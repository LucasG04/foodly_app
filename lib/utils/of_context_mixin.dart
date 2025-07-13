import 'package:flutter/material.dart';

mixin OfContextMixin<T extends StatefulWidget> on State<T> {
  MediaQueryData get media => MediaQuery.of(context);
  ThemeData get theme => Theme.of(context);
}
