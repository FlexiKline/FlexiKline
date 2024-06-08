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

import 'package:example/src/models/export.dart';
import 'package:example/src/theme/flexi_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../dialogs/select_symbol_dialog.dart';
import '../utils/dialog_manager.dart';

class SelectSymbolTitleView extends ConsumerStatefulWidget {
  const SelectSymbolTitleView({
    super.key,
    required this.instId,
    this.onChangeTradingPair,
    this.long,
    this.short,
  });

  final String instId;
  final ValueChanged<MarketTicker>? onChangeTradingPair;
  final Color? long;
  final Color? short;

  @override
  ConsumerState<ConsumerStatefulWidget> createState() =>
      _SelectSymbolTitleViewState();
}

class _SelectSymbolTitleViewState extends ConsumerState<SelectSymbolTitleView> {
  bool iconStatus = false;
  @override
  void initState() {
    super.initState();
  }

  Future<void> showSelectSymbolDialog() async {
    setState(() {
      iconStatus = true;
    });
    final result = await DialogManager().showBottomDialog(
      dialogTag: SelectSymbolDialog.dialogTag,
      builder: (context) => SelectSymbolDialog(
        long: widget.long,
        short: widget.short,
      ),
    );
    if (result != null) {
      widget.onChangeTradingPair?.call(result);
    }
    setState(() {
      iconStatus = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = ref.watch(themeProvider);
    return GestureDetector(
      onTap: showSelectSymbolDialog,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            widget.instId,
            style: theme.t1s20w700,
          ),
          RotationTransition(
            turns: AlwaysStoppedAnimation(iconStatus ? 0.5 : 0),
            child: Icon(
              Icons.arrow_drop_down,
              color: theme.t1,
            ),
          ),
        ],
      ),
    );
  }
}
