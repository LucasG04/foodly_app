import 'package:auto_size_text/auto_size_text.dart';
import 'package:flutter/material.dart';

import '../../../constants.dart';

class SettingsTile extends StatefulWidget {
  final String text;
  final IconData? leadingIcon;
  final Widget? trailing;
  final void Function()? onTap;
  final Color? colorIcon;
  final Color? colorText;
  final bool gradientBorder;

  const SettingsTile({
    required this.text,
    this.leadingIcon,
    this.trailing,
    this.onTap,
    this.colorIcon,
    this.colorText,
    this.gradientBorder = false,
    super.key,
  });

  @override
  State<SettingsTile> createState() => _SettingsTileState();
}

class _SettingsTileState extends State<SettingsTile>
    with SingleTickerProviderStateMixin {
  AnimationController? _controller;

  @override
  void initState() {
    super.initState();
    if (widget.gradientBorder) {
      _controller = AnimationController(
        vsync: this,
        duration: const Duration(seconds: 4),
      )..repeat();
    }
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return _controller == null
        ? _buildTile()
        : AnimatedBuilder(
            animation: _controller!,
            child: _buildTile(),
            builder: (context, child) {
              return Container(
                decoration: BoxDecoration(
                  gradient: SweepGradient(
                    colors: const [
                      Colors.pink,
                      Colors.red,
                      Colors.purple,
                      Colors.deepPurple,
                      Colors.red,
                    ],
                    transform: GradientRotation(_controller!.value * 2 * 3.14),
                  ),
                  borderRadius: BorderRadius.circular(kRadius),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(2.0),
                  child: child,
                ),
              );
            },
          );
  }

  Widget _buildTile() {
    final Color? textColor =
        widget.colorText ?? Theme.of(context).textTheme.bodyLarge!.color;
    return InkWell(
      onTap: widget.onTap,
      child: Container(
        height: 50,
        padding: const EdgeInsets.all(kPadding / 2),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(kRadius),
          color: Theme.of(context).dialogBackgroundColor,
        ),
        child: Row(
          children: [
            if (widget.leadingIcon != null)
              Icon(widget.leadingIcon, color: widget.colorIcon)
            else
              const SizedBox(),
            const SizedBox(width: kPadding),
            Expanded(
              child: AutoSizeText(
                widget.text,
                style: TextStyle(color: textColor),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            widget.trailing ?? const SizedBox(),
          ],
        ),
      ),
    );
  }
}
