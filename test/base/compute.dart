// Copyright 2024 Andy.Zhao
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//     https://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.

import 'dart:async';
import 'dart:developer';
import 'dart:isolate';

import 'package:flutter/foundation.dart';

/// Signature for the callback passed to [compute].
///
/// For more information, visit Flutter documentation for the equivalent
/// [`ComputeCallback<Q, R>` type definition](https://api.flutter.dev/flutter/foundation/ComputeCallback.html)
/// in Flutter. This documentation is taken directly from
/// the Flutter source code.
///
/// {@macro flutter.foundation.compute.types}
///
/// Instances of [ComputeCallback] must be functions that can be sent to an
/// isolate.
/// {@macro flutter.foundation.compute.callback}
///
/// {@macro flutter.foundation.compute.types}
typedef ComputeCallback<Q, R> = FutureOr<R> Function(Q message);

/// The signature of [compute], which spawns an isolate, runs `callback` on
/// that isolate, passes it `message`, and (eventually) returns the value
/// returned by `callback`.
///
/// For more information, visit Flutter documentation for the equivalent
/// [`ComputeImpl` type definition](https://api.flutter.dev/flutter/foundation/ComputeImpl.html)
/// in Flutter. This documentation is taken directly from
/// the Flutter source code.
///
/// {@macro flutter.foundation.compute.usecase}
///
/// The function used as `callback` must be one that can be sent to an isolate.
/// {@macro flutter.foundation.compute.callback}
///
/// {@macro flutter.foundation.compute.types}
///
/// The `debugLabel` argument can be specified to provide a name to add to the
/// [Timeline]. This is useful when profiling an application.
typedef ComputeImpl = Future<R> Function<Q, R>(
  ComputeCallback<Q, R> callback,
  Q message, {
  String? debugLabel,
});

/// The dart:io implementation of [c.compute].
Future<R> compute<Q, R>(
  ComputeCallback<Q, R> callback,
  Q message, {
  String? debugLabel,
}) async {
  debugLabel ??= kReleaseMode ? 'compute' : callback.toString();

  final Flow flow = Flow.begin();
  Timeline.startSync('$debugLabel: start', flow: flow);
  final RawReceivePort port = RawReceivePort();
  Timeline.finishSync();

  void timeEndAndCleanup() {
    Timeline.startSync('$debugLabel: end', flow: Flow.end(flow.id));
    port.close();
    Timeline.finishSync();
  }

  final Completer<dynamic> completer = Completer<dynamic>();
  port.handler = (dynamic msg) {
    timeEndAndCleanup();
    completer.complete(msg);
  };

  try {
    await Isolate.spawn<_IsolateConfiguration<Q, R>>(
      _spawn,
      _IsolateConfiguration<Q, R>(
        callback,
        message,
        port.sendPort,
        debugLabel,
        flow.id,
      ),
      errorsAreFatal: true,
      onExit: port.sendPort,
      onError: port.sendPort,
      debugName: debugLabel,
    );
  } on Object {
    timeEndAndCleanup();
    rethrow;
  }

  final dynamic response = await completer.future;
  if (response == null) {
    throw RemoteError('Isolate exited without result or error.', '');
  }

  assert(response is List<dynamic>);
  response as List<dynamic>;

  final int type = response.length;
  assert(1 <= type && type <= 3);

  switch (type) {
    // success; see _buildSuccessResponse
    case 1:
      return response[0] as R;

    // native error; see Isolate.addErrorListener
    case 2:
      await Future<Never>.error(
        RemoteError(
          response[0] as String,
          response[1] as String,
        ),
      );

    // caught error; see _buildErrorResponse
    case 3:
    default:
      assert(type == 3 && response[2] == null);

      await Future<Never>.error(
        response[0] as Object,
        response[1] as StackTrace,
      );
  }
}

class _IsolateConfiguration<Q, R> {
  const _IsolateConfiguration(
    this.callback,
    this.message,
    this.resultPort,
    this.debugLabel,
    this.flowId,
  );

  final ComputeCallback<Q, R> callback;
  final Q message;
  final SendPort resultPort;
  final String debugLabel;
  final int flowId;

  FutureOr<R> applyAndTime() {
    return Timeline.timeSync(
      debugLabel,
      () => callback(message),
      flow: Flow.step(flowId),
    );
  }
}

/// The spawn point MUST guarantee only one result event is sent through the
/// [SendPort.send] be it directly or indirectly i.e. [Isolate.exit].
///
/// In case an [Error] or [Exception] are thrown AFTER the data
/// is sent, they will NOT be handled or reported by the main [Isolate] because
/// it stops listening after the first event is received.
///
/// Also use the helpers [_buildSuccessResponse] and [_buildErrorResponse] to
/// build the response
Future<void> _spawn<Q, R>(_IsolateConfiguration<Q, R> configuration) async {
  late final List<dynamic> computationResult;

  try {
    computationResult =
        _buildSuccessResponse(await configuration.applyAndTime());
  } catch (e, s) {
    computationResult = _buildErrorResponse(e, s);
  }

  Isolate.exit(configuration.resultPort, computationResult);
}

/// Wrap in [List] to ensure our expectations in the main [Isolate] are met.
///
/// We need to wrap a success result in a [List] because the user provided type
/// [R] could also be a [List]. Meaning, a check `result is R` could return true
/// for what was an error event.
List<R> _buildSuccessResponse<R>(R result) {
  return List<R>.filled(1, result);
}

/// Wrap in [List] to ensure our expectations in the main isolate are met.
///
/// We wrap a caught error in a 3 element [List]. Where the last element is
/// always null. We do this so we have a way to know if an error was one we
/// caught or one thrown by the library code.
List<dynamic> _buildErrorResponse(Object error, StackTrace stack) {
  return List<dynamic>.filled(3, null)
    ..[0] = error
    ..[1] = stack;
}
