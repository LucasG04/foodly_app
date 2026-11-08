import 'dart:async';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:eva_icons_flutter/eva_icons_flutter.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../constants.dart';
import '../../../utils/main_snackbar.dart';
import '../../../utils/widget_utils.dart';
import '../../../widgets/main_button.dart';

/// Shared building blocks of the MCP sheets (AI apps + API key).

/// Horizontal padding that centers sheet content at the standard width.
EdgeInsets mcpSheetPadding(BuildContext context) {
  final size = MediaQuery.sizeOf(context);
  final width = size.width > 599 ? 580.0 : size.width * 0.88;
  final side = (size.width - width) / 2;
  return EdgeInsets.fromLTRB(
    side,
    kPadding,
    side,
    WidgetUtils.sheetBottomPadding(context),
  );
}

class McpCard extends StatelessWidget {
  final Widget child;
  final VoidCallback? onTap;
  final Color? color;

  const McpCard({required this.child, this.onTap, this.color, super.key});

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 600),
      decoration: BoxDecoration(
        color: color ??
            Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Material(
        type: MaterialType.transparency,
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
      ),
    );
  }
}

/// Monospace value; tapping copies it and swaps the icon for "Copied".
class McpCodeBox extends StatefulWidget {
  final String text;
  final VoidCallback? onCopied;

  const McpCodeBox({required this.text, this.onCopied, super.key});

  @override
  State<McpCodeBox> createState() => _McpCodeBoxState();
}

class _McpCodeBoxState extends State<McpCodeBox> {
  bool _copied = false;
  Timer? _reset;

  @override
  void dispose() {
    _reset?.cancel();
    super.dispose();
  }

  Future<void> _copy() async {
    await Clipboard.setData(ClipboardData(text: widget.text));
    unawaited(HapticFeedback.selectionClick());
    widget.onCopied?.call();
    if (!mounted) {
      return;
    }
    setState(() => _copied = true);
    _reset?.cancel();
    _reset = Timer(const Duration(seconds: 2), () {
      if (mounted) {
        setState(() => _copied = false);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).primaryColor;
    return Semantics(
      button: true,
      label: context.tr(_copied ? 'mcp_token_copied' : 'mcp_token_copy'),
      child: McpCard(
        onTap: _copy,
        child: Row(
          children: [
            Expanded(
              child: Text(
                widget.text,
                style: const TextStyle(
                  fontFamily: 'monospace',
                  fontFamilyFallback: ['Menlo', 'Courier'],
                  fontSize: 13,
                  height: 1.4,
                ),
              ),
            ),
            const SizedBox(width: 12),
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 200),
              transitionBuilder: (child, animation) =>
                  ScaleTransition(scale: animation, child: child),
              child: _copied
                  ? Row(
                      key: const ValueKey(true),
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(EvaIcons.checkmark, size: 20, color: primary),
                        const SizedBox(width: 4),
                        Text(
                          context.tr('mcp_token_copied'),
                          style: TextStyle(
                            color: primary,
                            fontWeight: FontWeight.w600,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    )
                  : const Icon(
                      EvaIcons.copyOutline,
                      key: ValueKey(false),
                      size: 20,
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Small section label (600 weight, 60 % text color).
class McpLabel extends StatelessWidget {
  final String text;

  const McpLabel(this.text, {super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: kPadding / 2),
      child: Text(
        text,
        style: theme.textTheme.bodyMedium?.copyWith(
          fontWeight: FontWeight.w600,
          color: theme.textTheme.bodyMedium?.color?.withValues(alpha: 0.6),
        ),
      ),
    );
  }
}

class McpInfoRow extends StatelessWidget {
  final IconData icon;
  final String text;
  final Color? color;

  const McpInfoRow({
    required this.icon,
    required this.text,
    this.color,
    super.key,
  });

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

/// Load error with a retry button.
class McpLoadError extends StatelessWidget {
  final String text;
  final VoidCallback onRetry;

  const McpLoadError({required this.text, required this.onRetry, super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        McpInfoRow(
          icon: EvaIcons.alertCircleOutline,
          color: Theme.of(context).colorScheme.error,
          text: text,
        ),
        const SizedBox(height: kPadding),
        MainButton(text: context.tr('mcp_token_retry'), onTap: onRetry),
      ],
    );
  }
}

class McpDisabled extends StatelessWidget {
  final bool disabled;
  final Widget child;

  const McpDisabled({required this.disabled, required this.child, super.key});

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      ignoring: disabled,
      child: Opacity(opacity: disabled ? 0.4 : 1, child: child),
    );
  }
}

/// Error snackbar for a failed request; 401 asks the user to sign in again.
void showMcpError(BuildContext context, Object error) {
  final isAuthError =
      error is DioException && error.response?.statusCode == 401;
  MainSnackbar(
    message:
        context.tr(isAuthError ? 'mcp_token_error_auth' : 'mcp_token_error'),
    isError: true,
  ).show(context);
}

/// Destructive confirmation in the platform's dialog style.
Future<bool> showMcpConfirm(
  BuildContext context, {
  required String title,
  required String message,
  required String action,
}) async {
  final isApple = Platform.isIOS || Platform.isMacOS;
  final result = await showDialog<bool>(
    context: context,
    builder: (context) {
      void pop(bool value) => Navigator.of(context).pop(value);
      final cancel = context.tr('mcp_token_cancel');
      return isApple
          ? CupertinoAlertDialog(
              title: Text(title),
              content: Text(message),
              actions: [
                CupertinoDialogAction(
                  onPressed: () => pop(false),
                  child: Text(cancel),
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
                TextButton(onPressed: () => pop(false), child: Text(cancel)),
                TextButton(
                  onPressed: () => pop(true),
                  child: Text(
                    action,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.error,
                    ),
                  ),
                ),
              ],
            );
    },
  );
  return result ?? false;
}
