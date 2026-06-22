import 'package:flutter/material.dart';
import 'package:intl/number_symbols_data.dart';
import 'package:provider/provider.dart';
import 'package:sakenph/globals/enums.dart';
import 'package:sakenph/providers/provider_search_details.dart';
import 'package:sakenph/providers/provider_system_vars.dart';

/// Mainly used to just listen to context provider value changes
/// and execute code accordingly.
///
/// Some codes in this app require proper BuildContext access throughout execution
/// but is lost when async tasks are needed to be executed. But with the help of
/// this widget listening to specific value changes, this issue can be solved.
class ContextChangeListener extends StatelessWidget {
  const ContextChangeListener({super.key});

  @override
  Widget build(BuildContext context) {
    // ///////////////////////////////////
    // Hide background widget if backend is done returning shortest paths.
    // ///////////////////////////////////
    final isNotEmpty = context.select<SearchDetailsProvider, bool>(
      (value) => value.suggestedShortestPaths.isNotEmpty,
    );

    // Adding a state check is kind of useless in the grand scheme. It's just there because
    // it keeps resetting back to the route choice while I'm debugging
    // - Josef Miko
    if (isNotEmpty &&
        context.read<SystemVariablesProvider>().appCurrentState !=
            SystemState.isCurrentlyTravelling) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        // safe — runs after the current build frame is done
        context.read<SystemVariablesProvider>().setAppCurrentState(
          SystemState.showSuggestedRoutes,
        );
      });
    }

    return SizedBox.shrink();
  }
}
