import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';

import '../../app_router.gr.dart';

class UnknownRouteScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final size =
        MediaQuery.of(context).size.width < MediaQuery.of(context).size.height
            ? MediaQuery.of(context).size.width
            : MediaQuery.of(context).size.height;
    return Scaffold(
      body: Center(
        child: Column(
          children: [
            Container(
              height: size * 0.5,
              width: size * 0.5,
              child: Image.asset(
                'assets/images/undraw_page_not_found.png',
              ),
            ),
            SizedBox(height: 0.0),
            Text(
              'Page not found.',
              style: TextStyle(fontSize: 30),
            ),
            SizedBox(height: 40.0),
            TextButton(
              onPressed: () => _navigateToHome(context),
              child: Text('Back to Home'),
            ),
          ],
        ),
      ),
    );
  }

  void _navigateToHome(context) {
    AutoRouter.of(context).replaceAll([HomeScreenRoute()]);
  }
}
