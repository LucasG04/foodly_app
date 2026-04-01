import 'dart:async';
import 'dart:math';

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:internet_connection_checker/internet_connection_checker.dart';

import '../constants.dart';
import 'small_circular_progress_indicator.dart';

enum _LoadingWarning { noConnection, slowConnection, slowServer, closeApp }

class LoadingScreen extends StatefulWidget {
  const LoadingScreen({super.key});

  @override
  State<LoadingScreen> createState() => _LoadingScreenState();
}

class _LoadingScreenState extends State<LoadingScreen> {
  static const List<String> _messageKeys = [
    'loading_hint_0',
    'loading_hint_1',
    'loading_hint_2',
    'loading_hint_3',
    'loading_hint_4',
    'loading_hint_5',
    'loading_hint_6',
    'loading_hint_7',
    'loading_hint_8',
    'loading_hint_9',
  ];

  static const _charDuration = Duration(milliseconds: 40);
  static const _holdDuration = Duration(seconds: 1);
  static const _nextMessageDelay = Duration(milliseconds: 500);

  static const _warningDelay = Duration(seconds: 8);

  /// Will start a after checking for good internet connection of user
  static const _closeAppDelay = Duration(seconds: 12);

  Timer? _timer;
  Timer? _connectionCheckTimer;
  Timer? _closeAppTimer;
  String _displayText = '';
  String _fullText = '';
  bool _visible = false;
  int _messageIndex = 0;
  _LoadingWarning? _warning;

  @override
  void initState() {
    super.initState();
    _messageIndex = Random().nextInt(_messageKeys.length);
    _fullText = _messageKeys[_messageIndex].tr();
    _timer = Timer(const Duration(milliseconds: 500), _show);
    _connectionCheckTimer = Timer(_warningDelay, _checkConnectionAndWarn);
  }

  void _show() {
    if (!mounted) {
      return;
    }
    setState(() => _visible = true);
    _startTyping();
  }

  void _startTyping() {
    if (!mounted) {
      return;
    }
    var charIndex = 0;
    _timer = Timer.periodic(_charDuration, (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      charIndex++;
      setState(() {
        _displayText = _fullText.substring(0, charIndex);
      });
      if (charIndex == _fullText.length) {
        timer.cancel();
        _timer = Timer(_holdDuration, _startUntyping);
      }
    });
  }

  void _startUntyping() {
    if (!mounted) {
      return;
    }
    _timer = Timer.periodic(_charDuration, (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      if (_displayText.isEmpty) {
        timer.cancel();
        _timer = Timer(_nextMessageDelay, _advanceMessage);
        return;
      }
      setState(() {
        _displayText = _displayText.substring(0, _displayText.length - 1);
      });
    });
  }

  void _advanceMessage() {
    if (!mounted) {
      return;
    }
    _messageIndex = (_messageIndex + 1) % _messageKeys.length;
    _fullText = _messageKeys[_messageIndex].tr();
    _startTyping();
  }

  Future<void> _checkConnectionAndWarn() async {
    final checker = InternetConnectionChecker.createInstance(
      slowConnectionConfig: const SlowConnectionConfig(
        enableToCheckForSlowConnection: true,
      ),
    );
    final status = await checker.connectionStatus;
    checker.dispose();
    if (!mounted) {
      return;
    }
    setState(() {
      _warning = switch (status) {
        InternetConnectionStatus.disconnected => _LoadingWarning.noConnection,
        InternetConnectionStatus.slow => _LoadingWarning.slowConnection,
        InternetConnectionStatus.connected => _LoadingWarning.slowServer,
      };
    });
    // Only escalate to close-app message when the connection is fine but the server
    // is slow. For connection issues the user can't do more than check Wi-Fi.
    if (status == InternetConnectionStatus.connected) {
      _closeAppTimer = Timer(_closeAppDelay, _showCloseAppWarning);
    }
  }

  void _showCloseAppWarning() {
    if (!mounted) {
      return;
    }
    setState(() => _warning = _LoadingWarning.closeApp);
  }

  @override
  void dispose() {
    _timer?.cancel();
    _connectionCheckTimer?.cancel();
    _closeAppTimer?.cancel();
    super.dispose();
  }

  String get _warningText => switch (_warning) {
        _LoadingWarning.noConnection => 'loading_warning_no_connection'.tr(),
        _LoadingWarning.slowConnection =>
          'loading_warning_slow_connection'.tr(),
        _LoadingWarning.slowServer => 'loading_warning_slow_server'.tr(),
        _LoadingWarning.closeApp => 'loading_warning_close_app'.tr(),
        null => '',
      };

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBackgroundColor,
      body: Stack(
        alignment: Alignment.center,
        children: [
          AnimatedOpacity(
            opacity: _visible ? 1.0 : 0.0,
            duration: const Duration(milliseconds: 300),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const SmallCircularProgressIndicator(),
                const SizedBox(height: 24),
                Text(
                  _displayText,
                  style: TextStyle(
                    fontSize: 14,
                    color: kPrimaryColor.withValues(alpha: 0.5),
                    fontFamily: 'Poppins',
                  ),
                ),
              ],
            ),
          ),
          Align(
            alignment: const Alignment(0, 0.25),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: kPadding),
              child: AnimatedOpacity(
                opacity: _warning != null ? 1.0 : 0.0,
                duration: const Duration(milliseconds: 400),
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 400),
                  child: Text(
                    _warningText,
                    key: ValueKey(_warning),
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 14,
                      color: kPrimaryColor.withValues(alpha: 0.5),
                      fontFamily: 'Poppins',
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
