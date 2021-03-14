import 'dart:async';

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
  StreamSubscription<User> _authStream;

  bool _isLoading;
  User _currentUser;

  @override
  void initState() {
    _isLoading = true;
    _authStream = AuthenticationService.authenticationStream().listen((user) {
      setStateIfMounted(() {
        _currentUser = user;
        _isLoading = false;
      });
    });
    super.initState();
  }

  @override
  void dispose() {
    _authStream.cancel();
    super.dispose();
  }

  void setStateIfMounted(f) {
    if (mounted) setState(f);
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        body: Center(child: SmallCircularProgressIndicator()),
      );
    } else if (_currentUser != null) {
      return TabNavigationView();
    } else {
      ExtendedNavigator.root.replace(Routes.authenticationScreen);
      return Scaffold();
    }
  }
}
