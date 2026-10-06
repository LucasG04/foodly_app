import 'dart:async';

import 'package:easy_localization/easy_localization.dart';
import 'package:eva_icons_flutter/eva_icons_flutter.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logging/logging.dart';
import 'package:url_launcher/url_launcher.dart';

import '../constants.dart';
import '../providers/state_providers.dart';
import '../services/foodly_user_service.dart';
import '../utils/basic_utils.dart';
import '../utils/widget_utils.dart';
import 'main_button.dart';

/// Asks once before user inputs go to third-party AI (App Store 5.1.2(i)).
class AiConsentSheet extends StatelessWidget {
  const AiConsentSheet({super.key});

  static final _log = Logger('AiConsentSheet');

  static bool hasConsent(WidgetRef ref) =>
      ref.read(userProvider)?.aiConsentAt != null;

  /// True if consent exists or the user grants it now.
  static Future<bool> ensure(BuildContext context, WidgetRef ref) async {
    if (hasConsent(ref)) {
      return true;
    }
    final allowed = await WidgetUtils.showFoodlyBottomSheet<bool>(
      context: context,
      builder: (_) => const AiConsentSheet(),
    );
    if (allowed != true) {
      return false;
    }
    setConsent(ref, DateTime.now());
    return true;
  }

  static void setConsent(WidgetRef ref, DateTime? consentAt) {
    final user = ref.read(userProvider);
    final userId = user?.id;
    if (user == null || userId == null) {
      return;
    }
    user.aiConsentAt = consentAt;
    // Not awaited: Firestore completes only on server ack, which never comes
    // offline; the write is queued and synced later.
    unawaited(
      FoodlyUserService.setAiConsentAt(userId, consentAt).catchError(
        (Object e) => _log.severe('Saving AI consent failed', e),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final mutedColor = theme.colorScheme.onSurface.withValues(alpha: 0.6);
    // The "Not now" button's own padding already clears most of the home
    // indicator, so only part of the bottom inset is added.
    final bottomInset = MediaQuery.paddingOf(context).bottom / 2;
    return Padding(
      padding: EdgeInsets.only(bottom: bottomInset),
      child: Center(
        heightFactor: 1,
        child: SizedBox(
          width: BasicUtils.contentWidth(context),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.only(
                  top: kPadding,
                  bottom: kPadding / 2,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.auto_awesome, color: theme.primaryColor),
                    const SizedBox(width: kPadding / 2),
                    Flexible(
                      child: Text(
                        context.tr('ai_consent_title').toUpperCase(),
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Text(
                context.tr('ai_consent_intro'),
                style: theme.textTheme.bodyLarge,
              ),
              const SizedBox(height: kPadding),
              _buildPoint(
                context,
                EvaIcons.fileTextOutline,
                context.tr('ai_consent_what_title'),
                context.tr('ai_consent_what'),
              ),
              _buildPoint(
                context,
                EvaIcons.globe2Outline,
                context.tr('ai_consent_who_title'),
                context.tr('ai_consent_who'),
              ),
              _buildPoint(
                context,
                EvaIcons.shieldOutline,
                context.tr('ai_consent_when_title'),
                context.tr('ai_consent_when'),
              ),
              Center(
                child: TextButton(
                  onPressed: () => launchUrl(
                    Uri.parse(kAppPrivacyUrl),
                    mode: LaunchMode.externalApplication,
                  ),
                  child: Text(
                    context.tr('ai_consent_privacy'),
                    style: TextStyle(color: mutedColor),
                  ),
                ),
              ),
              const SizedBox(height: kPadding / 2),
              Center(
                child: MainButton(
                  onTap: () => Navigator.pop(context, true),
                  text: context.tr('ai_consent_allow'),
                ),
              ),
              Center(
                child: TextButton(
                  onPressed: () => Navigator.pop(context, false),
                  child: Text(
                    context.tr('ai_consent_decline'),
                    style: theme.textTheme.bodyLarge,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPoint(
    BuildContext context,
    IconData icon,
    String title,
    String text,
  ) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: kPadding * 0.75),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.06),
              borderRadius: BorderRadius.circular(kRadius),
            ),
            child: Icon(icon, size: 20, color: theme.primaryColor),
          ),
          const SizedBox(width: kPadding * 0.75),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 2),
                Text(
                  text,
                  style: TextStyle(
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
