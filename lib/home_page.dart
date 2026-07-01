import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sakenph/features/background_widget/widgets.dart';
import 'package:sakenph/features/foreground_widget/functions.dart'
    show fetchData, handleLocationPermission;
import 'package:sakenph/features/foreground_widget/widgets.dart';
import 'package:sakenph/listeners/compass_direction_listener.dart';
import 'package:sakenph/map_widget.dart';
import 'package:sakenph/providers/provider_map_helper.dart';
import 'package:sakenph/providers/provider_system_tasks.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePage();
}

class _HomePage extends State<HomePage> {
  late Future<Map<dynamic, dynamic>> json;

  @override
  void initState() {
    super.initState();
    json = fetchData();
    context.read<MapHelperProvider>().fetchUserCurrentGeolocationAndSave();
    context.read<SystemTasksProvder>().mountProviders(context);
    // Enable compass
    requestPermissionAndListen(context);
  }

  @override
  void dispose() {
    super.dispose();
    context.read<SystemTasksProvder>().stop_repeatingTask();
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
            controller: context.read<MapHelperProvider>().mapWidgetController,
          ),

          /// Renders the background widget where other features and widgets
          /// could appear based on the current logic
          BackgroundWidget(),

          /// Renders widgets that are intended to only show up within the safe
          /// area and to show up above the other widgets
          ForegroundWidget(),
        ],
      ),
    );
  }
}
