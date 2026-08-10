import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sakenph/providers/provider_transient_ui.dart';

/// Closes transient overlays before a new search or route workflow begins.
void dismissTransientUi(BuildContext context) {
  context.read<TransientUiProvider>().dismissBottomSheet();
  FocusManager.instance.primaryFocus?.unfocus();
}
