import 'package:another_flushbar/flushbar.dart';
import 'package:eva_icons_flutter/eva_icons_flutter.dart';
import 'package:flutter/material.dart';

/// Custom Snackbar.
class MainSnackbar {
  final String? title;
  final String message;
  final Widget? action;
  final int duration;
  final bool isSuccess;
  final bool isError;
  final bool isCountdown;
  final bool infinite;
  final bool isDismissible;

  /// Example Usage: `MainSnackbar(message: 'Hello there!').show(context);`
  ///
  /// Only required param is the `message` String. `isSuccess` and `isError` cannot be both true.
  MainSnackbar({
    required this.message,
    this.title,
    this.action,
    this.duration = 5,
    this.isSuccess = false,
    this.isError = false,
    this.isCountdown = false,
    this.infinite = false,
    this.isDismissible = false,
  }) : assert(!isSuccess || !isError || !isCountdown);

  /// Show the snackbar.
  Future<dynamic> show(BuildContext context) {
    return Flushbar<dynamic>(
      margin: const EdgeInsets.all(8),
      borderRadius: BorderRadius.circular(10.0),
      title: title,
      message: message,
      duration: infinite ? null : Duration(seconds: duration),
      isDismissible: isDismissible || infinite,
      onTap: infinite ? (_) => Navigator.maybePop(context) : null,
      icon: isCountdown
          ? _buildCountdown()
          : isSuccess
              ? Icon(
                  EvaIcons.checkmarkCircle2Outline,
                  color: Colors.green[300],
                )
              : isError
                  ? Icon(
                      EvaIcons.alertCircleOutline,
                      size: 28.0,
                      color: Theme.of(context).errorColor,
                    )
                  : Icon(
                      EvaIcons.infoOutline,
                      size: 28.0,
                      color: Theme.of(context).primaryColor,
                    ),
      mainButton: action,
    ).show(context);
  }

  Widget _buildCountdown() {
    return Container(
      constraints: const BoxConstraints(maxHeight: 22.0),
      child: TweenAnimationBuilder(
        tween: Tween<double>(begin: 0, end: duration * 1000.toDouble()),
        duration: Duration(seconds: duration),
        builder: (context, double value, child) {
          return Stack(
            alignment: Alignment.center,
            children: [
              SizedBox(
                height: 20.0,
                width: 20.0,
                child: CircularProgressIndicator(
                  strokeWidth: 2.0,
                  value: _getProgressValue(value),
                  color: Colors.grey[850],
                  backgroundColor: Theme.of(context).dialogBackgroundColor,
                ),
              ),
              Center(
                child: Text(
                  _getCountdownText(value),
                  textScaleFactor: 0.85,
                  style: TextStyle(
                    color: Theme.of(context).dialogBackgroundColor,
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  double _getProgressValue(double value) {
    return value / (duration * 1000);

    // Progress with steps:
    // final step = 1 / seconds;
    // final passedSeconds = value ~/ 1000;
    // final newProgress = step * passedSeconds;
    // return newProgress;
  }

  String _getCountdownText(double value) {
    return ((duration - (value / 1000)).toInt()).toString();
  }
}
