import 'package:easy_localization/easy_localization.dart';
import 'package:eva_icons_flutter/eva_icons_flutter.dart';
import 'package:flutter/material.dart';

import '../../../constants.dart';
import '../../../models/mcp_token.dart';
import '../../../services/lunix_api_service.dart';
import '../../../utils/analytics.dart';
import '../../../widgets/main_button.dart';
import '../../../widgets/progress_button.dart';
import '../../../widgets/sheet_header.dart';
import '../../../widgets/small_circular_progress_indicator.dart';
import 'mcp_widgets.dart';

/// Fallback for AI apps without OAuth sign-in: a personal API key (PAT).
/// Show with `enableDrag: false`: drag-to-dismiss bypasses the [PopScope]
/// that keeps a freshly created key on screen until "Done".
class McpApiKeyModal extends StatefulWidget {
  const McpApiKeyModal({super.key});

  @override
  State<McpApiKeyModal> createState() => _McpApiKeyModalState();
}

enum _Action { create, delete }

class _McpApiKeyModalState extends State<McpApiKeyModal> {
  bool _loading = true;
  bool _loadFailed = false;
  DateTime? _createdAt;

  /// Plaintext key, only held in widget state until the modal closes.
  McpToken? _newToken;
  _Action? _running;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _loadFailed = false;
    });
    try {
      final createdAt = await LunixApiService.getMcpTokenCreatedAt();
      if (!mounted) {
        return;
      }
      setState(() {
        _createdAt = createdAt;
        _loading = false;
      });
    } catch (_) {
      if (!mounted) {
        return;
      }
      setState(() {
        _loadFailed = true;
        _loading = false;
      });
    }
  }

  Future<void> _create({bool regenerate = false}) async {
    if (_running != null) {
      return;
    }
    if (regenerate &&
        !await showMcpConfirm(
          context,
          title: context.tr('mcp_token_regenerate_title'),
          message: context.tr('mcp_token_regenerate_confirm'),
          action: context.tr('mcp_token_regenerate'),
        )) {
      return;
    }
    setState(() => _running = _Action.create);
    try {
      final token = await LunixApiService.createMcpToken();
      logEvent(
        regenerate
            ? AnalyticsEvent.mcpTokenRegenerate
            : AnalyticsEvent.mcpTokenCreate,
      );
      if (!mounted) {
        return;
      }
      setState(() {
        _newToken = token;
        _createdAt = token.createdAt;
      });
    } catch (e) {
      if (mounted) {
        showMcpError(context, e);
      }
    } finally {
      if (mounted) {
        setState(() => _running = null);
      }
    }
  }

  Future<void> _delete() async {
    if (_running != null ||
        !await showMcpConfirm(
          context,
          title: context.tr('mcp_token_delete_title'),
          message: context.tr('mcp_token_delete_confirm'),
          action: context.tr('mcp_token_delete'),
        )) {
      return;
    }
    setState(() => _running = _Action.delete);
    try {
      await LunixApiService.deleteMcpToken();
      logEvent(AnalyticsEvent.mcpTokenDelete);
      if (!mounted) {
        return;
      }
      setState(() => _createdAt = null);
    } catch (e) {
      if (mounted) {
        showMcpError(context, e);
      }
    } finally {
      if (mounted) {
        setState(() => _running = null);
      }
    }
  }

  ButtonState _buttonState(_Action action) =>
      _running == action ? ButtonState.inProgress : ButtonState.normal;

  /// Only "Done" may close while a request runs or the key is shown.
  bool get _canClose => _newToken == null && _running == null;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return PopScope(
      canPop: _canClose,
      child: Padding(
        padding: mcpSheetPadding(context),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SheetHeader(
              title: context.tr('mcp_token_title'),
              showClose: _canClose,
              padding: EdgeInsets.zero,
            ),
            Text(
              context.tr('mcp_token_subtitle'),
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.textTheme.bodySmall?.color,
              ),
            ),
            const SizedBox(height: kPadding),
            AnimatedSize(
              duration: const Duration(milliseconds: 200),
              alignment: Alignment.topCenter,
              child: _buildBody(),
            ),
          ],
        ),
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
      return McpLoadError(
        text: context.tr('mcp_token_load_error'),
        onRetry: _load,
      );
    }
    if (_newToken != null) {
      return _buildJustCreated(_newToken!);
    }
    if (_createdAt != null) {
      return _buildTokenExists(_createdAt!);
    }
    return _buildNoToken();
  }

  Widget _buildNoToken() {
    return Column(
      children: [
        Text(context.tr('mcp_token_explanation')),
        const SizedBox(height: kPadding),
        MainButton(
          text: context.tr('mcp_token_create'),
          onTap: _create,
          isProgress: true,
          buttonState: _buttonState(_Action.create),
        ),
      ],
    );
  }

  Widget _buildTokenExists(DateTime createdAt) {
    final theme = Theme.of(context);
    final date =
        DateFormat.yMMMMd(context.locale.toLanguageTag()).format(createdAt);
    return Column(
      children: [
        McpCard(
          child: Row(
            children: [
              Container(
                width: 10,
                height: 10,
                decoration: const BoxDecoration(
                  color: Colors.green,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      context.tr('mcp_token_active'),
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    Text(
                      context.tr('mcp_token_created_on', args: [date]),
                      style: theme.textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: kPadding / 2),
        McpInfoRow(
          icon: EvaIcons.lockOutline,
          text: context.tr('mcp_token_hidden_hint'),
        ),
        const SizedBox(height: kPadding),
        McpDisabled(
          disabled: _running == _Action.delete,
          child: MainButton(
            text: context.tr('mcp_token_regenerate'),
            onTap: () => _create(regenerate: true),
            isSecondary: true,
            isProgress: true,
            buttonState: _buttonState(_Action.create),
          ),
        ),
        const SizedBox(height: kPadding / 2),
        McpDisabled(
          disabled: _running == _Action.create,
          child: MainButton(
            text: context.tr('mcp_token_delete'),
            onTap: _delete,
            color: theme.colorScheme.error,
            isProgress: true,
            buttonState: _buttonState(_Action.delete),
          ),
        ),
      ],
    );
  }

  Widget _buildJustCreated(McpToken token) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        McpLabel(context.tr('mcp_token_your_token')),
        McpCodeBox(text: token.token),
        const SizedBox(height: kPadding / 2),
        McpInfoRow(
          icon: EvaIcons.alertTriangleOutline,
          color: Colors.orange,
          text: context.tr('mcp_token_shown_once'),
        ),
        const SizedBox(height: kPadding),
        McpLabel(context.tr('mcp_token_server_url')),
        McpCodeBox(text: LunixApiService.mcpEndpoint),
        const SizedBox(height: kPadding),
        McpInfoRow(
          icon: EvaIcons.infoOutline,
          text: context.tr('mcp_token_setup_docs_hint'),
        ),
        const SizedBox(height: kPadding),
        Center(
          child: MainButton(
            text: context.tr('mcp_token_done'),
            onTap: () => Navigator.of(context).pop(),
          ),
        ),
      ],
    );
  }
}
