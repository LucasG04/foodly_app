import 'package:eva_icons_flutter/eva_icons_flutter.dart';
import 'package:flutter/material.dart';

class MainAppBar extends StatefulWidget implements PreferredSizeWidget {
  final String text;
  final bool showBack;
  final VoidCallback? onPopRejected;
  final List<Widget>? actions;
  final ScrollController scrollController;

  const MainAppBar({
    required this.text,
    this.showBack = true,
    this.onPopRejected,
    this.actions,
    required this.scrollController,
    super.key,
  });

  @override
  State<MainAppBar> createState() => _MainAppBarState();

  @override
  Size get preferredSize => Size.fromHeight(AppBar().preferredSize.height);
}

class _MainAppBarState extends State<MainAppBar> {
  bool _isScrollToTop = true;
  // empty_space is a distance of empty padding, only after scrolling through it the content starts getting under the app bar.
  static const double kEmptySpace = 10.0;

  @override
  void initState() {
    widget.scrollController.addListener(_scrollListener);
    super.initState();
  }

  @override
  void dispose() {
    try {
      widget.scrollController.dispose();
      // ignore: empty_catches
    } catch (e) {}
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AppBar(
      title: Text(
        widget.text,
        style: TextStyle(
          fontWeight: FontWeight.w600,
          fontFamily: 'Poppins',
          color: Theme.of(context).textTheme.bodyLarge!.color,
        ),
        overflow: TextOverflow.fade,
      ),
      centerTitle: true,
      elevation: _isScrollToTop ? 0 : 2,
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      surfaceTintColor: Theme.of(context).scaffoldBackgroundColor,
      shadowColor: Theme.of(context).primaryColor,
      leading: widget.showBack
          ? IconButton(
              icon: Icon(
                _getIconData(Theme.of(context).platform),
                color: Theme.of(context).textTheme.bodyLarge!.color,
              ),
              tooltip: MaterialLocalizations.of(context).backButtonTooltip,
              onPressed: () async {
                final success = await Navigator.maybePop(context);
                if (!success && widget.onPopRejected != null) {
                  widget.onPopRejected!();
                }
              },
            )
          : null,
      actions: widget.actions,
    );
  }

  void _scrollListener() {
    if (widget.scrollController.offset <=
        widget.scrollController.position.minScrollExtent) {
      if (!_isScrollToTop) {
        setState(() {
          _isScrollToTop = true;
        });
      }
    } else {
      if (widget.scrollController.offset > kEmptySpace && _isScrollToTop) {
        setState(() {
          _isScrollToTop = false;
        });
      }
    }
  }

  /// Returns the appropriate "back" icon for the given `platform`.
  IconData? _getIconData(TargetPlatform platform) {
    switch (platform) {
      case TargetPlatform.android:
      case TargetPlatform.fuchsia:
      case TargetPlatform.linux:
      case TargetPlatform.windows:
        return EvaIcons.arrowBackOutline;
      case TargetPlatform.iOS:
      case TargetPlatform.macOS:
        return EvaIcons.arrowIosBackOutline;
    }
  }
}
