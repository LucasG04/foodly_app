import 'dart:io';

import 'package:dio/dio.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:eva_icons_flutter/eva_icons_flutter.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../constants.dart';
import '../../models/mcp_token.dart';
import '../../services/lunix_api_service.dart';
import '../../utils/main_snackbar.dart';
import '../../widgets/main_button.dart';
import '../../widgets/progress_button.dart';
import '../../widgets/small_circular_progress_indicator.dart';

class SettingsMcpTokenModal extends StatefulWidget {
  const SettingsMcpTokenModal({super.key});

  @override
  _SettingsMcpTokenModalState createState() => _SettingsMcpTokenModalState();
}

enum _Action { create, delete }

class _SettingsMcpTokenModalState extends State<SettingsMcpTokenModal> {
  bool _loading = true;
  bool _loadFailed = false;
  DateTime? _createdAt;

  /// Plaintext token, only held in widget state until the modal closes.
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
        !await _confirm(
          'mcp_token_regenerate_title'.tr(),
          'mcp_token_regenerate_confirm'.tr(),
          'mcp_token_regenerate'.tr(),
        )) {
      return;
    }
    setState(() => _running = _Action.create);
    try {
      final token = await LunixApiService.createMcpToken();
      FirebaseAnalytics.instance.logEvent(
        name: regenerate ? 'mcp_token_regenerate' : 'mcp_token_create',
      );
      if (!mounted) {
        return;
      }
      setState(() {
        _newToken = token;
        _createdAt = token.createdAt;
      });
    } catch (e) {
      _showError(e);
    } finally {
      if (mounted) {
        setState(() => _running = null);
      }
    }
  }

  Future<void> _delete() async {
    if (_running != null ||
        !await _confirm(
          'mcp_token_delete_title'.tr(),
          'mcp_token_delete_confirm'.tr(),
          'mcp_token_delete'.tr(),
        )) {
      return;
    }
    setState(() => _running = _Action.delete);
    try {
      await LunixApiService.deleteMcpToken();
      FirebaseAnalytics.instance.logEvent(name: 'mcp_token_delete');
      if (!mounted) {
        return;
      }
      setState(() => _createdAt = null);
    } catch (e) {
      _showError(e);
    } finally {
      if (mounted) {
        setState(() => _running = null);
      }
    }
  }

  void _showError(Object e) {
    final isAuthError = e is DioException && e.response?.statusCode == 401;
    MainSnackbar(
      message: (isAuthError ? 'mcp_token_error_auth' : 'mcp_token_error').tr(),
      isError: true,
    ).show(context);
  }

  Future<void> _copy(String text) async {
    await Clipboard.setData(ClipboardData(text: text));
    if (!mounted) {
      return;
    }
    MainSnackbar(message: 'mcp_token_copied'.tr(), isSuccess: true)
        .show(context);
  }

  Future<bool> _confirm(String title, String message, String action) async {
    final isApple = Platform.isIOS || Platform.isMacOS;
    final result = await showDialog<bool>(
      context: context,
      builder: (context) {
        void pop(bool value) => Navigator.of(context).pop(value);
        final errorColor = Theme.of(context).colorScheme.error;
        return isApple
            ? CupertinoAlertDialog(
                title: Text(title),
                content: Text(message),
                actions: [
                  CupertinoDialogAction(
                    onPressed: () => pop(false),
                    child: Text('mcp_token_cancel'.tr()),
                  ),
                  CupertinoDialogAction(
                    onPressed: () => pop(true),
                    isDestructiveAction: true,
                    child: Text(action),
                  ),
                ],
              )
            : AlertDialog(
                title: Text(title),
                content: Text(message),
                actions: [
                  TextButton(
                    onPressed: () => pop(false),
                    child: Text('mcp_token_cancel'.tr()),
                  ),
                  TextButton(
                    onPressed: () => pop(true),
                    child: Text(action, style: TextStyle(color: errorColor)),
                  ),
                ],
              );
      },
    );
    return result ?? false;
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    final width = size.width > 599 ? 580.0 : size.width * 0.88;

    return PopScope(
      // Only "Done" may close while a request runs or the token is shown.
      canPop: _newToken == null && _running == null,
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          (size.width - width) / 2,
          kPadding,
          (size.width - width) / 2,
          kPadding + MediaQuery.paddingOf(context).bottom,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildHeader(),
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

  Widget _buildHeader() {
    final theme = Theme.of(context);
    return Column(
      children: [
        Text(
          'mcp_token_title'.tr().toUpperCase(),
          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 4),
        Text(
          'mcp_token_subtitle'.tr(),
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.textTheme.bodySmall?.color,
          ),
          textAlign: TextAlign.center,
        ),
      ],
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
      return _buildLoadFailed();
    }
    if (_newToken != null) {
      return _buildJustCreated(_newToken!);
    }
    if (_createdAt != null) {
      return _buildTokenExists(_createdAt!);
    }
    return _buildNoToken();
  }

  Widget _buildLoadFailed() {
    return Column(
      children: [
        _InfoRow(
          icon: EvaIcons.alertCircleOutline,
          color: Theme.of(context).colorScheme.error,
          text: 'mcp_token_load_error'.tr(),
        ),
        const SizedBox(height: kPadding),
        MainButton(text: 'mcp_token_retry'.tr(), onTap: _load),
      ],
    );
  }

  Widget _buildNoToken() {
    return Column(
      children: [
        Text('mcp_token_explanation'.tr()),
        const SizedBox(height: kPadding),
        _buildCapabilities(),
        const SizedBox(height: kPadding),
        MainButton(
          text: 'mcp_token_create'.tr(),
          onTap: _create,
          isProgress: true,
          buttonState: _running == _Action.create
              ? ButtonState.inProgress
              : ButtonState.normal,
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
        _Card(
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
                      'mcp_token_active'.tr(),
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    Text(
                      'mcp_token_created_on'.tr(args: [date]),
                      style: theme.textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: kPadding / 2),
        _InfoRow(
          icon: EvaIcons.lockOutline,
          text: 'mcp_token_hidden_hint'.tr(),
        ),
        const SizedBox(height: kPadding),
        _Disabled(
          disabled: _running == _Action.delete,
          child: MainButton(
            text: 'mcp_token_regenerate'.tr(),
            onTap: () => _create(regenerate: true),
            isSecondary: true,
            isProgress: true,
            buttonState: _running == _Action.create
                ? ButtonState.inProgress
                : ButtonState.normal,
          ),
        ),
        const SizedBox(height: kPadding / 2),
        _Disabled(
          disabled: _running == _Action.create,
          child: MainButton(
            text: 'mcp_token_delete'.tr(),
            onTap: _delete,
            color: theme.colorScheme.error,
            isProgress: true,
            buttonState: _running == _Action.delete
                ? ButtonState.inProgress
                : ButtonState.normal,
          ),
        ),
      ],
    );
  }

  Widget _buildJustCreated(McpToken token) {
    final url = LunixApiService.mcpEndpoint;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _Label('mcp_token_your_token'.tr()),
        _CodeBox(text: token.token, onCopy: () => _copy(token.token)),
        const SizedBox(height: kPadding / 2),
        _InfoRow(
          icon: EvaIcons.alertTriangleOutline,
          color: Colors.orange,
          text: 'mcp_token_shown_once'.tr(),
        ),
        const SizedBox(height: kPadding),
        _Label('mcp_token_server_url'.tr()),
        _CodeBox(text: url, onCopy: () => _copy(url)),
        const SizedBox(height: kPadding),
        _InfoRow(
          icon: EvaIcons.infoOutline,
          text: 'mcp_token_setup_docs_hint'.tr(),
        ),
        const SizedBox(height: kPadding),
        Center(
          child: MainButton(
            text: 'mcp_token_done'.tr(),
            onTap: () => Navigator.of(context).pop(),
          ),
        ),
      ],
    );
  }

  Widget _buildCapabilities() {
    const keys = [
      'mcp_token_capability_plans',
      'mcp_token_capability_meals',
      'mcp_token_capability_entries',
      'mcp_token_capability_shopping',
    ];
    return Column(
      children: [
        for (final key in keys)
          Padding(
            padding: const EdgeInsets.only(bottom: 6),
            child: _InfoRow(
              icon: EvaIcons.checkmarkCircle2Outline,
              color: Theme.of(context).primaryColor,
              text: key.tr(),
            ),
          ),
      ],
    );
  }
}

class _Card extends StatelessWidget {
  final Widget child;
  final VoidCallback? onTap;

  const _Card({required this.child, this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.05),
      borderRadius: BorderRadius.circular(10),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(14),
          child: child,
        ),
      ),
    );
  }
}

class _CodeBox extends StatelessWidget {
  final String text;
  final VoidCallback onCopy;

  const _CodeBox({required this.text, required this.onCopy});

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: 'mcp_token_copy'.tr(),
      child: _Card(
        onTap: onCopy,
        child: Row(
          children: [
            Expanded(
              child: Text(
                text,
                style: const TextStyle(
                  fontFamily: 'monospace',
                  fontFamilyFallback: ['Menlo', 'Courier'],
                  fontSize: 13,
                  height: 1.4,
                ),
              ),
            ),
            const SizedBox(width: 12),
            const Icon(EvaIcons.copyOutline, size: 20),
          ],
        ),
      ),
    );
  }
}

class _Label extends StatelessWidget {
  final String text;

  const _Label(this.text);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Text(
        text.toUpperCase(),
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
              fontWeight: FontWeight.bold,
              letterSpacing: 0.8,
            ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String text;
  final Color? color;

  const _InfoRow({required this.icon, required this.text, this.color});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      children: [
        Icon(icon, size: 18, color: color ?? theme.textTheme.bodySmall?.color),
        const SizedBox(width: 8),
        Expanded(child: Text(text, style: theme.textTheme.bodySmall)),
      ],
    );
  }
}

class _Disabled extends StatelessWidget {
  final bool disabled;
  final Widget child;

  const _Disabled({required this.disabled, required this.child});

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      ignoring: disabled,
      child: Opacity(opacity: disabled ? 0.4 : 1, child: child),
    );
  }
}
