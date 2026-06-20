import 'package:flutter/material.dart';

mixin OfContextMixin<T extends StatefulWidget> on State<T> {
  Size get mediaSize => MediaQuery.sizeOf(context);
  EdgeInsets get mediaViewInsets => MediaQuery.viewInsetsOf(context);
  EdgeInsets get mediaPadding => MediaQuery.paddingOf(context);
  ThemeData get theme => Theme.of(context);
}
