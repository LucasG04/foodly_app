import 'dart:async';

import 'package:easy_localization/easy_localization.dart';
import 'package:eva_icons_flutter/eva_icons_flutter.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';

import '../../../constants.dart';
import '../../../models/mcp_connection.dart';
import '../../../utils/analytics.dart';
import '../../../utils/main_snackbar.dart';
import '../../../utils/widget_utils.dart';
import '../../../widgets/sheet_header.dart';
import '../../../widgets/small_circular_progress_indicator.dart';
import 'mcp_api.dart';
import 'mcp_api_key_modal.dart';
import 'mcp_widgets.dart';

/// AI assistants: connect via OAuth (copy URL → add connector → sign in),
/// see and disconnect connected apps; API key as the fallback.
///
/// Reloads silently when the app resumes, so an app the user just connected
/// in the browser appears (highlighted) without any extra tap.
class McpSettingsModal extends StatefulWidget {
  final McpApi api;

  const McpSettingsModal({this.api = const McpApi(), super.key});

  @override
  State<McpSettingsModal> createState() => _McpSettingsModalState();
}

class _McpSettingsModalState extends State<McpSettingsModal> {
  static const _highlightDuration = Duration(seconds: 4);

  bool _loading = true;
  bool _loadFailed = false;
  List<McpConnection> _connections = const [];
  bool _hasApiKey = false;

  /// Connections that appeared while the sheet was open.
  final Set<String> _newIds = {};
  String? _removingId;

  /// Bumped by every load and disconnect; a load whose number is outdated is dropped, so a reload that
  /// started before a disconnect can't bring the removed app back.
  int _generation = 0;
  late final AppLifecycleListener _lifecycle;
  Timer? _highlightTimer;

  @override
  void initState() {
    super.initState();
    _lifecycle = AppLifecycleListener(onResume: () => _load(silent: true));
    _load();
  }

  @override
  void dispose() {
    _lifecycle.dispose();
    _highlightTimer?.cancel();
    super.dispose();
  }

  /// [silent]: no spinner, errors ignored, new connections celebrated (only compared with a list that
  /// loaded successfully, so existing apps don't count as new after a failed or still running load).
  Future<void> _load({bool silent = false}) async {
    final generation = ++_generation;
    if (!silent) {
      setState(() {
        _loading = true;
        _loadFailed = false;
      });
    }
    try {
      final (connections, keyCreatedAt) = await (
        widget.api.connections(),
        widget.api.apiKeyCreatedAt(),
      ).wait;
      if (!mounted || generation != _generation) {
        return;
      }
      final known = _connections.map((c) => c.id).toSet();
      final hadList = !_loading && !_loadFailed;
      final added = silent && hadList
          ? connections.where((c) => !known.contains(c.id)).toList()
          : const <McpConnection>[];
      setState(() {
        _connections = connections;
        _hasApiKey = keyCreatedAt != null;
        _loading = false;
        _loadFailed = false;
        _newIds.addAll(added.map((c) => c.id));
      });
      if (added.isNotEmpty) {
        _celebrate(added.first);
      }
    } catch (_) {
      if (mounted && !silent && generation == _generation) {
        setState(() {
          _loadFailed = true;
          _loading = false;
        });
      }
    }
  }

  void _celebrate(McpConnection connection) {
    unawaited(HapticFeedback.mediumImpact());
    logEvent(AnalyticsEvent.mcpConnectionAdded);
    MainSnackbar(
      message: context.tr(
        'mcp_connected_snackbar',
        args: [connection.clientName],
      ),
      isSuccess: true,
    ).show(context);
    _highlightTimer?.cancel();
    _highlightTimer = Timer(_highlightDuration, () {
      if (mounted) {
        setState(_newIds.clear);
      }
    });
  }

  Future<void> _disconnect(McpConnection connection) async {
    if (_removingId != null ||
        !await showMcpConfirm(
          context,
          title: context.tr(
            'mcp_disconnect_title',
            args: [connection.clientName],
          ),
          message: context.tr(
            'mcp_disconnect_confirm',
            args: [connection.clientName],
          ),
          action: context.tr('mcp_disconnect'),
        )) {
      return;
    }
    setState(() => _removingId = connection.id);
    try {
      await widget.api.disconnect(connection.id);
      logEvent(AnalyticsEvent.mcpConnectionDelete);
      if (mounted) {
        setState(() {
          _generation++;
          _connections =
              _connections.where((c) => c.id != connection.id).toList();
        });
      }
    } catch (e) {
      if (mounted) {
        showMcpError(context, e);
      }
    } finally {
      if (mounted) {
        setState(() => _removingId = null);
      }
    }
  }

  Future<void> _shareUrl(BuildContext anchor, String url) async {
    final box = anchor.findRenderObject() as RenderBox?;
    await SharePlus.instance.share(ShareParams(
      uri: Uri.parse(url),
      // iPad anchors the share popover here.
      sharePositionOrigin:
          box == null ? null : box.localToGlobal(Offset.zero) & box.size,
    ));
    logEvent(AnalyticsEvent.mcpUrlShare);
  }

  Future<void> _openApiKey() async {
    await WidgetUtils.showFoodlyBottomSheet<void>(
      context: context,
      scrollable: true,
      enableDrag: false,
      builder: (_) => const McpApiKeyModal(),
    );
    if (mounted) {
      await _load(silent: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: mcpSheetPadding(context),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SheetHeader(title: context.tr('mcp_title'), padding: EdgeInsets.zero),
          Text(
            context.tr('mcp_subtitle'),
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.textTheme.bodySmall?.color,
            ),
          ),
          const SizedBox(height: kPadding),
          AnimatedSize(
            duration: const Duration(milliseconds: 250),
            curve: Curves.easeOutCubic,
            alignment: Alignment.topCenter,
            child: _buildBody(),
          ),
        ],
      ),
    );
  }

  Widget _buildBody() {
    if (_loading) {
      return const Padding(
        padding: EdgeInsets.all(kPadding),
        child: Center(child: SmallCircularProgressIndicator()),
      );
    }
    if (_loadFailed) {
      return McpLoadError(text: context.tr('mcp_load_error'), onRetry: _load);
    }
    const gap = SizedBox(height: kPadding * 1.5);
    // First visit teaches; once something is connected, the list leads.
    final children = _connections.isEmpty
        ? [_buildConnect(), gap, _buildConnected()]
        : [_buildConnected(), gap, _buildConnect()];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [...children, gap, _buildApiKey()],
    );
  }

  Widget _buildConnect() {
    final url = widget.api.serverUrl;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        McpLabel(
          context.tr(
            _connections.isEmpty ? 'mcp_connect_title' : 'mcp_connect_another',
          ),
        ),
        _Step(
          number: 1,
          text: context.tr('mcp_step_copy'),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              McpCodeBox(
                text: url,
                onCopied: () => logEvent(AnalyticsEvent.mcpUrlCopy),
              ),
              // AI apps often run on a computer: AirDrop / message the URL.
              Builder(
                builder: (ctx) => TextButton.icon(
                  onPressed: () => _shareUrl(ctx, url),
                  icon: const Icon(EvaIcons.shareOutline, size: 18),
                  label: Text(context.tr('mcp_share_url')),
                  style: TextButton.styleFrom(
                    foregroundColor: Theme.of(context).primaryColor,
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    visualDensity: VisualDensity.compact,
                  ),
                ),
              ),
            ],
          ),
        ),
        _Step(number: 2, text: context.tr('mcp_step_add')),
        _Step(number: 3, text: context.tr('mcp_step_sign_in'), isLast: true),
      ],
    );
  }

  Widget _buildConnected() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        McpLabel(context.tr('mcp_connected_title')),
        if (_connections.isEmpty)
          const _WaitingCard()
        else
          for (final c in _connections)
            Padding(
              padding: const EdgeInsets.only(bottom: kPadding / 2),
              child: _ConnectionTile(
                connection: c,
                isNew: _newIds.contains(c.id),
                isRemoving: _removingId == c.id,
                onDisconnect: () => _disconnect(c),
              ),
            ),
      ],
    );
  }

  Widget _buildApiKey() {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        McpLabel(context.tr('mcp_no_sign_in_title')),
        McpCard(
          onTap: _openApiKey,
          child: Row(
            children: [
              Icon(Icons.key_outlined, color: theme.textTheme.bodySmall?.color),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      context.tr('mcp_api_key_tile'),
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                    Text(
                      context.tr('mcp_api_key_tile_hint'),
                      style: theme.textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
              if (_hasApiKey) ...[
                const SizedBox(width: 12),
                const _StatusDot(color: Colors.green),
                const SizedBox(width: 6),
                Text(
                  context.tr('mcp_api_key_active'),
                  style: theme.textTheme.bodySmall,
                ),
              ],
              const SizedBox(width: 4),
              const Icon(EvaIcons.arrowIosForwardOutline, size: 20),
            ],
          ),
        ),
      ],
    );
  }
}

/// Numbered step; the last one has no bottom gap.
class _Step extends StatelessWidget {
  final int number;
  final String text;
  final Widget? child;
  final bool isLast;

  const _Step({
    required this.number,
    required this.text,
    this.child,
    this.isLast = false,
  });

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).primaryColor;
    return Padding(
      padding: EdgeInsets.only(bottom: isLast ? 0 : kPadding * 0.75),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 26,
            height: 26,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: primary.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: Text(
              '$number',
              style: TextStyle(
                color: primary,
                fontWeight: FontWeight.bold,
                fontSize: 13,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Padding(
                  padding: const EdgeInsets.only(top: 3),
                  child: Text(text),
                ),
                if (child != null) ...[const SizedBox(height: 8), child!],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ConnectionTile extends StatelessWidget {
  final McpConnection connection;
  final bool isNew;
  final bool isRemoving;
  final VoidCallback onDisconnect;

  const _ConnectionTile({
    required this.connection,
    required this.isNew,
    required this.isRemoving,
    required this.onDisconnect,
  });

  /// "Cl" / "Ch": two letters tell Claude and ChatGPT apart.
  static String _initials(String name) {
    final letters = name.trim().characters;
    if (letters.isEmpty) {
      return '?';
    }
    return letters.first.toUpperCase() +
        letters.skip(1).take(1).toString().toLowerCase();
  }

  String _relativeDay(BuildContext context, DateTime date) {
    final days = DateUtils.dateOnly(DateTime.now())
        .difference(DateUtils.dateOnly(date))
        .inDays;
    if (days <= 0) {
      return context.tr('mcp_today');
    }
    if (days == 1) {
      return context.tr('mcp_yesterday');
    }
    if (days < 7) {
      return context.tr('mcp_days_ago', args: ['$days']);
    }
    return DateFormat.MMMd(context.locale.toLanguageTag()).format(date);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primary = theme.primaryColor;
    final name = connection.clientName;
    final locale = context.locale.toLanguageTag();
    final created = connection.createdAt;
    final since = (created.year == DateTime.now().year
            ? DateFormat.MMMd(locale)
            : DateFormat.yMMMd(locale))
        .format(created);
    return McpCard(
      color: isNew ? primary.withValues(alpha: 0.14) : null,
      child: Row(
        children: [
          CircleAvatar(
            radius: 18,
            backgroundColor: primary.withValues(alpha: 0.14),
            child: Text(
              _initials(name),
              style: TextStyle(color: primary, fontWeight: FontWeight.bold),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                    if (isNew) ...[
                      const SizedBox(width: 6),
                      _NewBadge(color: primary),
                    ],
                  ],
                ),
                Text(
                  context.tr(
                    'mcp_connection_subtitle',
                    args: [_relativeDay(context, connection.lastUsedAt), since],
                  ),
                  style: theme.textTheme.bodySmall,
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          SizedBox(
            height: kMinInteractiveDimension,
            child: Center(
              child: isRemoving
                  ? const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 12),
                      child: SmallCircularProgressIndicator(),
                    )
                  : TextButton(
                      onPressed: onDisconnect,
                      style: TextButton.styleFrom(
                        foregroundColor: theme.colorScheme.error,
                      ),
                      child: Text(context.tr('mcp_disconnect')),
                    ),
            ),
          ),
        ],
      ),
    );
  }
}

class _NewBadge extends StatelessWidget {
  final Color color;

  const _NewBadge({required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        context.tr('mcp_new'),
        style: const TextStyle(
          color: Colors.white,
          fontSize: 11,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}

/// Empty state: tells the user the list fills itself after sign-in.
class _WaitingCard extends StatelessWidget {
  const _WaitingCard();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return McpCard(
      child: Row(
        children: [
          _StatusDot(color: theme.primaryColor, pulse: true),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  context.tr('mcp_waiting_title'),
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                Text(
                  context.tr('mcp_waiting_hint'),
                  style: theme.textTheme.bodySmall,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// 10 px dot; [pulse] fades it in and out unless animations are reduced.
class _StatusDot extends StatefulWidget {
  final Color color;
  final bool pulse;

  const _StatusDot({required this.color, this.pulse = false});

  @override
  State<_StatusDot> createState() => _StatusDotState();
}

class _StatusDotState extends State<_StatusDot>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1100),
    lowerBound: 0.3,
  );

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (widget.pulse && !MediaQuery.disableAnimationsOf(context)) {
      _controller.repeat(reverse: true);
    } else {
      _controller
        ..stop()
        ..value = 1;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _controller,
      child: Container(
        width: 10,
        height: 10,
        decoration: BoxDecoration(color: widget.color, shape: BoxShape.circle),
      ),
    );
  }
}
