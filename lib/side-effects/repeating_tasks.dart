import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sakenph/providers/provider_search_details.dart';

/// Function that contains all code to run in interval
void runRepeatingTaskJobs(BuildContext context) {
  //print("REPEAT JOB: GET AND STORE CURRENT LOC DETAILS");
  context.read<SearchDetailsProvider>().getUserCurrentLocAndSaveToContext(
    context,
  );
}
