import 'package:flutter/material.dart';

import 'progress_button.dart';

class MainButton extends StatelessWidget {
  final void Function() onTap;
  final String? text;
  final IconData? iconData;
  final double width;
  final double height;
  final bool isSecondary;
  final bool isProgress;
  final ButtonState? buttonState;
  final Color? color;

  /// Label colour on a filled button; white by default. Light fills such as
  /// the premium yellow need dark ink to stay readable.
  final Color? textColor;

  /// Shadow under the button, for one floating over content.
  final bool floating;

  Color get kTextHeadlineColor => const Color(0xFF333333);

  const MainButton({
    required this.onTap,
    this.text,
    this.iconData,
    this.width = 300,
    this.height = 60,
    this.isSecondary = false,
    this.isProgress = false,
    this.buttonState,
    this.color,
    this.textColor,
    this.floating = false,
    super.key,
  })  : assert(isProgress && buttonState != null || !isProgress),
        assert(text != null || iconData != null);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final fillColor = color ?? theme.primaryColor;
    final decoration = BoxDecoration(
      color: isSecondary ? theme.scaffoldBackgroundColor : fillColor,
      borderRadius: BorderRadius.circular(10),
      // Part of the decoration, so it follows the progress button's shape.
      boxShadow: floating
          ? [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.18),
                blurRadius: 16,
                offset: const Offset(0, 6),
              ),
            ]
          : null,
      border: isSecondary ? Border.all(color: fillColor) : null,
    );
    return !isProgress
        ? InkWell(
            onTap: onTap,
            child: Container(
              width: width,
              height: height,
              decoration: decoration,
              child: Center(
                child: text != null
                    ? Text(
                        text!,
                        style: !isSecondary
                            ? theme.textTheme.labelLarge!
                                .copyWith(color: textColor ?? Colors.white)
                            : theme.textTheme.bodyLarge!.copyWith(
                                color: kTextHeadlineColor,
                                fontWeight: FontWeight.bold,
                              ),
                      )
                    : Icon(
                        iconData,
                        color: isSecondary
                            ? kTextHeadlineColor
                            : textColor ?? Colors.white,
                      ),
              ),
            ),
          )
        : SizedBox(
            width: buttonState != ButtonState.inProgress ? width : null,
            height: height,
            child: ProgressButton(
              buttonState: buttonState,
              onPressed: onTap,
              decoration: decoration,
              progressColor: !isSecondary
                  ? Colors.white
                  // ? Theme.of(context).textTheme.button.color
                  : kTextHeadlineColor,
              child: Text(
                text!,
                style: !isSecondary
                    ? theme.textTheme.labelLarge!
                        .copyWith(color: textColor ?? Colors.white)
                    : theme.textTheme.bodyLarge!.copyWith(
                        color: kTextHeadlineColor,
                        fontWeight: FontWeight.bold,
                      ),
              ),
            ),
          );
  }
}
