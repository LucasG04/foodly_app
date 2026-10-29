import 'package:auto_route/auto_route.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import '../app_router.gr.dart';

/// "Tell us" action for a failure snackbar, opening the feedback form.
/// Built from the caller's [context]: the snackbar sits above the router.
Widget feedbackSnackbarAction(BuildContext context) {
  final router = AutoRouter.of(context);
  return TextButton(
    onPressed: () => router.push(const FeedbackScreenRoute()),
    child: Text(context.tr('error_feedback_action')),
  );
}
