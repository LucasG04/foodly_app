import 'package:flutter/material.dart';

import 'progress_button.dart';

class MainButton extends StatelessWidget {
  final String text;
  final void Function() onTap;
  final double width;
  final double height;
  final bool isSecondary;
  final bool isProgress;
  final ButtonState buttonState;
  final Color color;

  final kTextHeadlineColor = Color(0xFF333333);

  MainButton({
    @required this.text,
    @required this.onTap,
    this.width = 300,
    this.height = 60,
    this.isSecondary = false,
    this.isProgress = false,
    this.buttonState,
    this.color,
  }) : assert(isProgress && buttonState != null || !isProgress);

  @override
  Widget build(BuildContext context) {
    final _color = color ?? Theme.of(context).primaryColor;
    return !isProgress
        ? InkWell(
            onTap: onTap,
            child: Container(
              width: width,
              height: height,
              decoration: !isSecondary
                  ? BoxDecoration(
                      color: _color,
                      borderRadius: BorderRadius.circular(10),
                    )
                  : BoxDecoration(
                      color: Theme.of(context).scaffoldBackgroundColor,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: _color),
                    ),
              child: Center(
                child: Text(
                  text,
                  style: !isSecondary
                      ? Theme.of(context)
                          .textTheme
                          .button
                          .copyWith(color: Colors.white)
                      : Theme.of(context).textTheme.bodyText1.copyWith(
                            color: kTextHeadlineColor,
                            fontWeight: FontWeight.bold,
                          ),
                ),
              ),
            ),
          )
        : Container(
            width: buttonState != ButtonState.inProgress ? width : null,
            height: height,
            child: ProgressButton(
              buttonState: buttonState,
              onPressed: onTap,
              decoration: !isSecondary
                  ? BoxDecoration(
                      color: _color,
                      borderRadius: BorderRadius.circular(10),
                    )
                  : BoxDecoration(
                      color: Theme.of(context).scaffoldBackgroundColor,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: _color),
                    ),
              child: Text(
                text,
                style: !isSecondary
                    ? Theme.of(context)
                        .textTheme
                        .button
                        .copyWith(color: Colors.white)
                    : Theme.of(context).textTheme.bodyText1.copyWith(
                          color: kTextHeadlineColor,
                          fontWeight: FontWeight.bold,
                        ),
              ),
              progressColor: !isSecondary
                  ? Colors.white
                  // ? Theme.of(context).textTheme.button.color
                  : kTextHeadlineColor,
            ),
          );
  }
}
