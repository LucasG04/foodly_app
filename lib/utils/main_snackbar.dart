import 'package:another_flushbar/flushbar.dart';
import 'package:eva_icons_flutter/eva_icons_flutter.dart';
import 'package:flutter/material.dart';

/// Custom Snackbar.
class MainSnackbar {
  final String? title;
  final String message;
  final TextButton? button;
  final int seconds;
  final bool isSuccess;
  final bool isError;

  /// Example Usage: `MainSnackbar(message: 'Hello there!').show(context);`
  ///
  /// Only required param is the `message` String. `isSuccess` and `isError` cannot be both true.
  MainSnackbar({
    required this.message,
    this.title,
    this.button,
    this.seconds = 5,
    this.isSuccess = false,
    this.isError = false,
  }) : assert(!isSuccess || !isError);

  /// Show the snackbar.
  void show(BuildContext context) {
    Flushbar(
      margin: EdgeInsets.all(8),
      borderRadius: BorderRadius.circular(15.0),
      flushbarStyle: FlushbarStyle.FLOATING,
      title: this.title,
      message: this.message,
      duration: Duration(seconds: this.seconds),
      icon: isSuccess
          ? Icon(
              EvaIcons.checkmarkCircle2Outline,
              color: Colors.green[300],
            )
          : isError
              ? Icon(
                  EvaIcons.alertCircleOutline,
                  size: 28.0,
                  color: Colors.red[300],
                )
              : Icon(
                  EvaIcons.infoOutline,
                  size: 28.0,
                  color: Colors.grey,
                ),
      mainButton: this.button,
    )..show(context);
  }
}
