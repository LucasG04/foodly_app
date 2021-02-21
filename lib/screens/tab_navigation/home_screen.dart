import 'package:auto_route/auto_route.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'tab_navigation_view.dart';
import '../../services/authentication_service.dart';
import '../../widgets/small_circular_progress_indicator.dart';

import '../../app_router.gr.dart';

class HomeScreen extends StatefulWidget {
  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User>(
      stream: AuthenticationService.authenticationStream(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Scaffold(
            body: Center(child: SmallCircularProgressIndicator()),
          );
        } else if (snapshot.hasData) {
          return TabNavigationView();
        } else {
          ExtendedNavigator.root.replace(Routes.authenticationScreen);
          return Scaffold();
        }
      },
    );
  }
}
