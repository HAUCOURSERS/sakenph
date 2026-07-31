/*
Put all of the function/code you want to execute upon the start of HomePage init()
*/

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sakenph/providers/provider_map_helper.dart';
import 'package:sakenph/providers/provider_system_tasks.dart';

void runAtHomePageInit(BuildContext context) {
  context.read<MapHelperProvider>().fetchUserCurrentGeolocationAndSave();
  context.read<SystemTasksProvder>().mountProviders(context);
}
