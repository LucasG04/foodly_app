import 'dart:async';
import 'dart:math';

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import '../constants.dart';
import 'small_circular_progress_indicator.dart';

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

  Timer? _timer;
  String _displayText = '';
  String _fullText = '';
  bool _visible = false;
  int _messageIndex = 0;

  @override
  void initState() {
    super.initState();
    _messageIndex = Random().nextInt(_messageKeys.length);
    _fullText = _messageKeys[_messageIndex].tr();
    _timer = Timer(const Duration(milliseconds: 500), _show);
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

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBackgroundColor,
      body: Center(
        child: AnimatedOpacity(
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
      ),
    );
  }
}
