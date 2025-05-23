import 'package:auto_size_text/auto_size_text.dart';
import 'package:flutter/material.dart';

import 'helper.dart';

class ButtonsTab extends StatefulWidget {
  /// Define attribute Widget and State
  ///
  const ButtonsTab({
    super.key,
    this.title,
    this.onPressed,
    required this.width,
    this.height,
    this.isSelected,
    this.radius,
    this.selectedTextStyle,
    this.unSelectedTextStyle,
    required this.selectedColors,
    this.icons,
    required this.unSelectedColors,
    this.begin,
    this.end,
    this.marginSelected = EdgeInsets.zero,
  });

  final String? title;
  final Function? onPressed;
  final double? width;
  final double? height;
  final List<Color>? selectedColors;
  final List<Color>? unSelectedColors;
  final TextStyle? selectedTextStyle;
  final TextStyle? unSelectedTextStyle;

//  final BoxDecoration selectedDecoration;
//  final BoxDecoration unSelectedDecoration;
  final bool? isSelected;
  final double? radius;
  final IconData? icons;

  final Alignment? begin;
  final Alignment? end;

  final EdgeInsets? marginSelected;

  @override
  State<ButtonsTab> createState() => _ButtonsTabState();
}

class _ButtonsTabState extends State<ButtonsTab> {
  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: widget.width ?? widthInPercent(100, context),
      height: widget.height ?? 50,
      //wrap with container to fix margin issue
      child: Container(
        margin: widget.isSelected! ? widget.marginSelected : EdgeInsets.zero,
        decoration: widget.isSelected!
            ? bdHeader.copyWith(
                borderRadius: BorderRadius.circular(widget.radius!),
                gradient: LinearGradient(
                  // Where the linear gradient begins and ends
                  begin: widget.begin ?? Alignment.topCenter,
                  end: widget.end ?? Alignment.bottomCenter,
                  colors:
                      widget.selectedColors ?? [Theme.of(context).primaryColor],
                ),
              )
            : null,
        child: TextButton(
          onPressed: widget.onPressed as void Function()?,
          style: ButtonStyle(
              shape: WidgetStateProperty.all(RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(widget.radius!))),
              padding: WidgetStateProperty.all(EdgeInsets.zero)),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (widget.icons != null)
                Icon(
                  widget.icons,
                  color: widget.isSelected!
                      ? widget.selectedTextStyle!.color
                      : widget.unSelectedTextStyle!.color,
                )
              else
                Container(),
              Visibility(
                visible: widget.icons != null,
                child: const SizedBox(
                  width: 4,
                ),
              ),
              AutoSizeText(
                widget.title!,
                maxLines: 1,
                style: widget.isSelected!
                    ? widget.selectedTextStyle
                    : widget.unSelectedTextStyle,
                textAlign: TextAlign.center,
              )
            ],
          ),
        ),
      ),
    );
  }
}
