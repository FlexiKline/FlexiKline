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

import 'package:dio/dio.dart';
import 'package:example/generated/l10n.dart';
// import 'package:flutter/foundation.dart';
// import 'package:talker_dio_logger/talker_dio_logger.dart';

typedef ModelMapper<T> = T Function(Map<String, dynamic>);
typedef DataConvert<T> = T? Function(dynamic);

String succeedCode = '0';
const errorCodeCancel = '700';
const errorCodeInternal = '701';
const errorCodeUnknown = '600';
const errorCodeTimeout = '601';
const errorCodeBadCertificate = '602';
const errorCodeConnectionError = '603';

const jsonNodeCode = 'code';
const jsonNodeMsg = 'msg';
const jsonNodeData = 'data';
const jsonNodeSuccess = 'success';

class ApiResult<T> {
  final String code;
  final String msg;
  T? data;
  final bool success;

  ApiResult({
    required this.code,
    required this.msg,
    this.data,
    bool? success,
  }) : success = success ?? code == succeedCode;
}

enum HttpMethod {
  connect,
  head,
  get,
  post,
  put,
  patch,
  delete,
  options,
  trace;

  @override
  String toString() => name.toUpperCase();
}

final class HttpClient {
  // HttpClient._internal();
  // factory HttpClient() => _instance;
  // static final HttpClient _instance = HttpClient._internal();
  // static HttpClient get instance => _instance;

  late final Dio _dio;
  Dio get dio => _dio;

  final Map<String, dynamic> _reqHeaders = {};
  Map<String, dynamic> get reqHeaders => _reqHeaders;

  void addHeader(String key, String val) {
    _reqHeaders[key] = val;
  }

  void removeHeader(String key) {
    _reqHeaders.remove(key);
  }

  HttpClient({
    required String baseUrl,
    String? accessKey,
  }) {
    _dio = Dio(BaseOptions(
      baseUrl: baseUrl,
      headers: {
        "OK-ACCESS-KEY": accessKey,
      },
      sendTimeout: const Duration(seconds: 15),
      receiveTimeout: const Duration(seconds: 15),
      connectTimeout: const Duration(seconds: 15),
    ));
    _dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) {
        options.headers.addAll(reqHeaders);
        handler.next(options);
      },
    ));
    // if (kDebugMode) {
    //   _dio.interceptors.add(
    //     TalkerDioLogger(
    //       settings: const TalkerDioLoggerSettings(
    //         printRequestHeaders: true,
    //         printResponseHeaders: true,
    //         printResponseMessage: true,
    //       ),
    //     ),
    //   );
    // }
  }

  static Options checkOptions(String method, Options? options) {
    options ??= Options();
    options.method = method;
    return options;
  }

  Future<ApiResult<T>> request<T>(
    String path,
    DataConvert<T> dataConvert, {
    required HttpMethod method,
    Object? data,
    Map<String, dynamic>? queryParameters,
    CancelToken? cancelToken,
    Options? options,
    ProgressCallback? onSendProgress,
    ProgressCallback? onReceiveProgress,
  }) async {
    try {
      final resp = await dio.request(
        path,
        data: data,
        queryParameters: queryParameters,
        options: checkOptions(method.toString(), options),
        cancelToken: cancelToken,
        onSendProgress: onSendProgress,
        onReceiveProgress: onReceiveProgress,
      );
      return handleResponse(resp, dataConvert);
    } on DioException catch (e) {
      return handleException(e);
    } on Exception catch (e) {
      return handleException(e);
    }
  }

  Future<ApiResult<T>> get<T>(
    String path,
    ModelMapper<T> mapper, {
    Map<String, dynamic>? queryParameters,
    Object? data,
    Options? options,
    CancelToken? cancelToken,
    ProgressCallback? onReceiveProgress,
  }) async {
    return request(
      path,
      (dynamic data) => mapper(data),
      method: HttpMethod.get,
      data: data,
      queryParameters: queryParameters,
      options: options,
      cancelToken: cancelToken,
      onReceiveProgress: onReceiveProgress,
    );
  }

  Future<ApiResult<List<T>>> getList<T>(
    String path,
    ModelMapper<T> mapper, {
    Map<String, dynamic>? queryParameters,
    Object? data,
    Options? options,
    CancelToken? cancelToken,
    ProgressCallback? onReceiveProgress,
  }) async {
    return request(
      path,
      (dynamic data) =>
          (data as List<dynamic>?)?.map((e) => mapper(e)).toList() ?? const [],
      method: HttpMethod.get,
      data: data,
      queryParameters: queryParameters,
      options: options,
      cancelToken: cancelToken,
      onReceiveProgress: onReceiveProgress,
    );
  }

  Future<ApiResult<T>> post<T>(
    String path,
    ModelMapper<T> mapper, {
    Object? data,
    Map<String, dynamic>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
    ProgressCallback? onSendProgress,
    ProgressCallback? onReceiveProgress,
  }) {
    return request(
      path,
      (dynamic data) => mapper(data),
      method: HttpMethod.post,
      data: data,
      options: options,
      queryParameters: queryParameters,
      cancelToken: cancelToken,
      onSendProgress: onSendProgress,
      onReceiveProgress: onReceiveProgress,
    );
  }

  Future<ApiResult<List<T>>> postList<T>(
    String path,
    ModelMapper<T> mapper, {
    Object? data,
    Map<String, dynamic>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
    ProgressCallback? onSendProgress,
    ProgressCallback? onReceiveProgress,
  }) {
    return request(
      path,
      (dynamic data) =>
          (data as List<dynamic>?)?.map((e) => mapper(e)).toList() ?? const [],
      method: HttpMethod.post,
      data: data,
      options: options,
      queryParameters: queryParameters,
      cancelToken: cancelToken,
      onSendProgress: onSendProgress,
      onReceiveProgress: onReceiveProgress,
    );
  }

  ApiResult<T> handleResponse<T>(Response response, DataConvert<T> convert) {
    final respData = response.data;
    final code = respData[jsonNodeCode] ?? errorCodeInternal;
    final msg = respData[jsonNodeMsg];
    final success = respData[jsonNodeSuccess];

    if (code == succeedCode) {
      return ApiResult(
        code: '$code',
        msg: msg,
        data: convert(respData[jsonNodeData]),
        success: success,
      );
    } else {
      return ApiResult(
        code: '$code',
        msg: msg,
        data: null,
        success: success,
      );
    }
  }

  ApiResult<T> handleException<T>(Exception exception) {
    String? code;
    String? msg;
    if (exception is DioException) {
      switch (exception.type) {
        case DioExceptionType.connectionTimeout:
          msg = S.current.connectionTimeout;
        case DioExceptionType.sendTimeout:
          msg = S.current.sendTimeout;
        case DioExceptionType.receiveTimeout:
          msg = S.current.responseTimeout;
          code = errorCodeTimeout;
          break;
        case DioExceptionType.cancel:
          code = errorCodeCancel;
          msg = S.current.canceled;
          break;
        case DioExceptionType.badResponse:
          int? statusCode = exception.response?.statusCode;
          if (statusCode != null) {
            code = '$statusCode';
            switch (statusCode) {
              case 400:
                msg = S.current.syntaxError;
                break;
              case 401:
                msg = S.current.permissionDenied;
                break;
              case 403:
                msg = S.current.serverRefused;
                break;
              case 404:
                msg = S.current.cannotReachServer;
                break;
              case 405:
                msg = S.current.reqMethodForbidden;
                break;
              case 500:
                msg = S.current.serverInternalError;
                break;
              case 502:
                msg = S.current.invalidReq;
                break;
              case 503:
                msg = S.current.serverDown;
                break;
              case 505:
                msg = S.current.unsupportedProtocol;
                break;
            }
          }
          code ??= errorCodeInternal;
          msg ??= exception.response?.statusMessage ?? S.current.unknownError;
          break;
        case DioExceptionType.badCertificate:
          code = errorCodeBadCertificate;
          msg = S.current.badCertificate;
          break;
        case DioExceptionType.connectionError:
          code = errorCodeConnectionError;
          msg = S.current.connectionError;
          break;
        case DioExceptionType.unknown:
      }
      code ??= errorCodeUnknown;
      msg ??= S.current.unknownError;
      return ApiResult<T>(
        code: code,
        msg: msg,
        data: null,
      );
    } else {
      return ApiResult<T>(
        code: errorCodeInternal,
        msg: exception.toString(),
        data: null,
      );
    }
  }
}

late final HttpClient httpClient;

void initHttpClient({
  String baseUrl = "https://aws.okx.com",
  String? accessKey,
}) {
  httpClient = HttpClient(baseUrl: baseUrl, accessKey: accessKey);
}
