import 'package:easy_localization/easy_localization.dart';
import 'package:eva_icons_flutter/eva_icons_flutter.dart';
import 'package:flutter/material.dart';

import '../constants.dart';
import '../models/foodly_change.dart';
import 'main_button.dart';
import 'scroll_shadow_layout.dart';

class NewVersionModal extends StatefulWidget {
  final List<VersionGroup> versionGroups;

  const NewVersionModal({
    required this.versionGroups,
    super.key,
  });

  @override
  State<NewVersionModal> createState() => _NewVersionModalState();

  static List<ChangeTranslation> checkVersionNotesForVariables(
      List<ChangeTranslation> translations) {
    return translations.map((t) {
      final title = t.title.replaceAll('{appName}', kAppName);
      final description = t.description.replaceAll('{appName}', kAppName);
      if (title == t.title && description == t.description) {
        return t;
      }
      return ChangeTranslation(
        language: t.language,
        title: title,
        description: description,
      );
    }).toList();
  }
}

class _NewVersionModalState extends State<NewVersionModal> {
  @override
  Widget build(BuildContext context) {
    return ScrollShadowLayout(
      header: Container(
        padding: const EdgeInsets.all(kPadding / 2),
        color: Theme.of(context).dialogTheme.backgroundColor,
        child: Row(
          children: [
            Expanded(
              child: Padding(
                padding: const EdgeInsets.only(left: kPadding / 2),
                child: Text(
                  'new_version_modal_title'.tr().toUpperCase(),
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
            IconButton(
              icon: const Icon(EvaIcons.close),
              onPressed: _close,
            ),
          ],
        ),
      ),
      body: SingleChildScrollView(
        child: Container(
          constraints: BoxConstraints(
            minHeight: MediaQuery.sizeOf(context).height * 0.8,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: kPadding),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ...widget.versionGroups.map(
                      (g) => _buildVersionSection(g),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(vertical: kPadding),
                child: MainButton(
                  onTap: _close,
                  text: 'new_version_modal_continue'.tr(),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildVersionSection(VersionGroup group) {
    return Padding(
      padding: const EdgeInsets.only(top: kPadding),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            group.version,
            style: TextStyle(
              color: Theme.of(context)
                  .colorScheme
                  .onSurface
                  .withValues(alpha: 0.5),
            ),
          ),
          const SizedBox(height: kPadding / 2),
          ...group.notes.asMap().entries.map((entry) {
            final isFirst = entry.key == 0;
            return Padding(
              padding: EdgeInsets.only(top: isFirst ? 0 : kPadding / 2),
              child: _buildNoteCard(entry.value),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildNoteCard(VersionNote note) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(kRadius),
      ),
      padding: const EdgeInsets.all(kPadding),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    if (note.emoji != null) ...[
                      Text(
                        note.emoji!,
                        style: const TextStyle(fontSize: 16),
                        strutStyle: const StrutStyle(
                          fontSize: 16,
                          forceStrutHeight:
                              true, // Zwingt das Widget, die Höhe strikt zu berechnen
                        ),
                      ),
                      const SizedBox(width: kPadding / 4),
                    ],
                    Text(
                      note.title,
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: kPadding / 2),
                Text(
                  note.description,
                  style: TextStyle(
                    color: Theme.of(context)
                        .colorScheme
                        .onSurface
                        .withValues(alpha: 0.6),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _close() {
    Navigator.pop(context);
  }
}

class VersionNote {
  String title;
  String description;
  String? emoji;

  VersionNote({
    required this.title,
    required this.description,
    this.emoji,
  });
}

class VersionGroup {
  final String version;
  final List<VersionNote> notes;

  const VersionGroup({
    required this.version,
    required this.notes,
  });
}
