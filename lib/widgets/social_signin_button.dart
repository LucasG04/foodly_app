import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

class SocialSignInButton {
  static Widget apple(void Function() onTap) {
    return _SocialButton(
        text: 'Sign in with Apple',
        onTap: onTap,
        color: Color(0xFF242424),
        icon: FaIcon(FontAwesomeIcons.apple, color: Colors.white));
  }
}

class _SocialButton extends StatelessWidget {
  final String text;
  final void Function() onTap;
  final double width;
  final double height;
  final Widget icon;
  final Color color;

  final kTextHeadlineColor = Color(0xFF333333);

  _SocialButton({
    @required this.text,
    @required this.onTap,
    this.width = 300.0,
    this.height = 60.0,
    @required this.icon,
    @required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            icon,
            Text(
              text,
              style: Theme.of(context)
                  .textTheme
                  .button
                  .copyWith(color: Colors.white),
            ),
          ],
        ),
      ),
    );
  }
}
