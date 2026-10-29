import 'dart:async';
import 'dart:math' as math;

import 'package:eva_icons_flutter/eva_icons_flutter.dart';
import 'package:flutter/material.dart';

import '../services/app_review_service.dart';

/// Custom Snackbar.
class MainSnackbar {
  final String? title;
  final String message;
  final Widget? action;
  final int duration;
  final bool isSuccess;
  final bool isError;
  final bool isCountdown;
  final bool infinite;
  final bool isDismissible;

  /// Example Usage: `MainSnackbar(message: 'Hello there!').show(context);`
  ///
  /// Only required param is the `message` String. `isSuccess` and `isError` cannot be both true.
  MainSnackbar({
    required this.message,
    this.title,
    this.action,
    this.duration = 5,
    this.isSuccess = false,
    this.isError = false,
    this.isCountdown = false,
    this.infinite = false,
    this.isDismissible = true,
  }) : assert(!isSuccess || !isError || !isCountdown);

  /// Shows the snackbar above every page, sheet and dialog through the app's
  /// [SnackbarHost]. It is not a route: it stays while pages change and
  /// doesn't swallow a back tap. Completes once it is gone; a new snackbar
  /// replaces the current one.
  Future<void> show(BuildContext context) {
    if (!context.mounted) {
      return Future.value();
    }
    if (isError) {
      AppReviewService.skipThisSession();
    }
    final host = context.findAncestorStateOfType<_SnackbarHostState>() ??
        _SnackbarHostState._current;
    if (host == null) {
      return Future.value();
    }
    return host._show(this);
  }

  Widget _buildIcon(ThemeData theme) {
    if (isCountdown) {
      return _buildCountdown(theme);
    }
    if (isSuccess) {
      return Icon(EvaIcons.checkmarkCircle2Outline, color: Colors.green[300]);
    }
    if (isError) {
      return Icon(
        EvaIcons.alertCircleOutline,
        size: 28.0,
        color: theme.colorScheme.error,
      );
    }
    return Icon(EvaIcons.infoOutline, size: 28.0, color: theme.primaryColor);
  }

  Widget _buildCountdown(ThemeData theme) {
    return Container(
      constraints: const BoxConstraints(maxHeight: 22.0),
      child: TweenAnimationBuilder(
        tween: Tween<double>(begin: 0, end: duration * 1000.toDouble()),
        duration: Duration(seconds: duration),
        builder: (context, double value, child) {
          return Stack(
            alignment: Alignment.center,
            children: [
              SizedBox(
                height: 20.0,
                width: 20.0,
                child: CircularProgressIndicator(
                  strokeWidth: 2.0,
                  value: _getProgressValue(value),
                  color: Colors.grey[850],
                  backgroundColor: theme.dialogTheme.backgroundColor,
                ),
              ),
              Center(
                child: Text(
                  _getCountdownText(value),
                  textScaler: const TextScaler.linear(0.85),
                  style: TextStyle(
                    color: theme.dialogTheme.backgroundColor,
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  double _getProgressValue(double value) {
    return value / (duration * 1000);
  }

  String _getCountdownText(double value) {
    return (duration - (value / 1000)).toInt().toString();
  }
}

/// Draws [MainSnackbar]s above the app's navigator, so they show over sheets
/// and dialogs and survive navigation. Put it in `MaterialApp.builder`.
class SnackbarHost extends StatefulWidget {
  final Widget child;

  const SnackbarHost({required this.child, super.key});

  @override
  State<SnackbarHost> createState() => _SnackbarHostState();
}

class _SnackbarHostState extends State<SnackbarHost> {
  /// For contexts outside the host (e.g. above `MaterialApp.builder`).
  static _SnackbarHostState? _current;

  _Shown? _shown;

  @override
  void initState() {
    super.initState();
    _current = this;
  }

  @override
  void dispose() {
    if (_current == this) {
      _current = null;
    }
    _shown?.done.complete();
    super.dispose();
  }

  Future<void> _show(MainSnackbar snackbar) {
    _shown?.done.complete();
    final shown = _Shown(snackbar);
    setState(() => _shown = shown);
    return shown.done.future;
  }

  void _remove(_Shown shown) {
    if (_shown != shown) {
      return;
    }
    shown.done.complete();
    setState(() => _shown = null);
  }

  @override
  Widget build(BuildContext context) {
    final shown = _shown;
    return Stack(
      children: [
        widget.child,
        if (shown != null)
          Positioned.fill(
            child: _SnackbarView(
              key: ObjectKey(shown),
              snackbar: shown.snackbar,
              onGone: () => _remove(shown),
            ),
          ),
      ],
    );
  }
}

class _Shown {
  final MainSnackbar snackbar;
  final done = Completer<void>();

  _Shown(this.snackbar);
}

class _SnackbarView extends StatefulWidget {
  final MainSnackbar snackbar;
  final VoidCallback onGone;

  const _SnackbarView({
    required this.snackbar,
    required this.onGone,
    super.key,
  });

  @override
  State<_SnackbarView> createState() => _SnackbarViewState();
}

class _SnackbarViewState extends State<_SnackbarView>
    with SingleTickerProviderStateMixin {
  late final _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 250),
    reverseDuration: const Duration(milliseconds: 200),
  )..forward();
  late final _curve = CurvedAnimation(
    parent: _controller,
    curve: Curves.easeOutCubic,
  );
  Timer? _timer;

  /// Its own overlay, since the host sits above the navigator's: tooltips
  /// in an action need one. Empty space lets touches through.
  late final _entry = OverlayEntry(
    builder: (context) => Stack(children: [_buildPositioned(context)]),
  );

  @override
  void initState() {
    super.initState();
    if (!widget.snackbar.infinite) {
      _timer = Timer(Duration(seconds: widget.snackbar.duration), _hide);
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    _entry
      ..remove()
      ..dispose();
    _controller.dispose();
    super.dispose();
  }

  Future<void> _hide() async {
    _timer?.cancel();
    if (!mounted) {
      return;
    }
    await _controller.reverse();
    if (mounted) {
      widget.onGone();
    }
  }

  @override
  Widget build(BuildContext context) => Overlay(initialEntries: [_entry]);

  Widget _buildPositioned(BuildContext context) {
    final snackbar = widget.snackbar;
    final theme = Theme.of(context);
    final media = MediaQuery.of(context);
    final reduceMotion = MediaQuery.disableAnimationsOf(context);
    final bottom =
        8.0 + math.max(media.viewInsets.bottom, media.viewPadding.bottom);

    Widget view = Material(
      // Flushbar's look, which the app's snackbars always had.
      color: const Color(0xFF303030),
      borderRadius: BorderRadius.circular(10.0),
      child: InkWell(
        borderRadius: BorderRadius.circular(10.0),
        onTap: snackbar.infinite ? _hide : null,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              snackbar._buildIcon(theme),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (snackbar.title != null)
                      Text(
                        snackbar.title!,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                    Text(
                      snackbar.message,
                      style: const TextStyle(fontSize: 14, color: Colors.white),
                    ),
                  ],
                ),
              ),
              if (snackbar.action != null)
                // The action runs, then the message goes.
                Listener(
                  onPointerUp: (_) => Future.microtask(_hide),
                  child: snackbar.action,
                ),
            ],
          ),
        ),
      ),
    );
    if (snackbar.isDismissible || snackbar.infinite) {
      view = Dismissible(
        key: const ValueKey('snackbar'),
        direction: DismissDirection.down,
        onDismissed: (_) => widget.onGone(),
        child: view,
      );
    }

    return Positioned(
      left: 8,
      right: 8,
      bottom: bottom,
      child: SafeArea(
        top: false,
        bottom: false,
        child: Semantics(
          liveRegion: true,
          child: FadeTransition(
            opacity: _curve,
            child: reduceMotion
                ? view
                : SlideTransition(
                    position: Tween(
                      begin: const Offset(0, 1),
                      end: Offset.zero,
                    ).animate(_curve),
                    child: view,
                  ),
          ),
        ),
      ),
    );
  }
}
