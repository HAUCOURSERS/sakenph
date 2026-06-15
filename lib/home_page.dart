import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sakenph/features/background_widget/widgets.dart';
import 'package:sakenph/features/foreground_widget/functions.dart'
    show fetchData, handleLocationPermission;
import 'package:sakenph/features/foreground_widget/widgets.dart';
import 'package:sakenph/globals/enums.dart';
import 'package:sakenph/map_widget.dart';
import 'package:sakenph/providers/provider_mapwidget_handler.dart';
import 'package:sakenph/providers/provider_search_details.dart';
import 'package:sakenph/providers/provider_system_vars.dart';
import 'package:sakenph/side-effects/context_change_listener.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePage();
}

class _HomePage extends State<HomePage> {
  late Future<Map<dynamic, dynamic>> json;

  SearchDetailsProvider? _searchProvider;

  @override
  void initState() {
    super.initState();
    json = fetchData();
  }

  @override
  Widget build(BuildContext context) {
    handleLocationPermission(context);
    return Scaffold(
      appBar: AppBar(toolbarHeight: 0),
      resizeToAvoidBottomInset: false,
      body: Stack(
        children: [
          /// Renders the map
          MapWidget(
            controller: context
                .read<MapWidgetHandlerProvider>()
                .mapWidgetController,
          ),

          /// Renders the background widget where other features and widgets
          /// could appear based on the current logic
          BackgroundWidget(),

          /// Renders widgets that are intended to only show up within the safe
          /// area and to show up above the other widgets
          ForegroundWidget(),

          /// Mainly used to just listen to context provider value changes
          /// and execute code accordingly
          ContextChangeListener(),
        ],
      ),
    );
  }
}
