import 'package:auto_route/auto_route_annotations.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';

class MealScreen extends StatelessWidget {
  final String id;

  const MealScreen({
    @PathParam() this.id,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        child: Text(this.id ?? 'no id'),
      ),
    );
  }
}
