import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

// ignore: avoid_classes_with_only_static_members
class SocialSignInButton {
  static Widget apple(void Function() onTap) {
    return _SocialButton(
        text: 'Sign in with Apple',
        onTap: onTap,
        color: const Color(0xFF242424),
        icon: const FaIcon(FontAwesomeIcons.apple, color: Colors.white));
  }
}

class _SocialButton extends StatelessWidget {
  final String text;
  final void Function() onTap;
  final Widget icon;
  final Color color;

  double get _buttonHeight => 60.0;
  double get _buttonWidth => 300.0;

  const _SocialButton({
    required this.text,
    required this.onTap,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Container(
        width: _buttonWidth,
        height: _buttonHeight,
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            icon,
            Text(
              text,
              style: Theme.of(context)
                  .textTheme
                  .button!
                  .copyWith(color: Colors.white),
            ),
          ],
        ),
      ),
    );
  }
}
