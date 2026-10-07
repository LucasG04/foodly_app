import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import '../constants.dart';
import '../models/foodly_change.dart';
import '../utils/widget_utils.dart';
import 'main_button.dart';
import 'scroll_shadow_layout.dart';
import 'sheet_header.dart';

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
        color: Theme.of(context).dialogTheme.backgroundColor,
        child: SheetHeader(
          title: context.tr('new_version_modal_title'),
          padding: const EdgeInsets.fromLTRB(
              kPadding, kPadding, kPadding, kPadding / 2),
        ),
      ),
      body: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: kPadding),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  for (final group in widget.versionGroups)
                    _buildVersionSection(group),
                ],
              ),
            ),
            Padding(
              padding: EdgeInsets.only(
                  bottom: WidgetUtils.sheetBottomPadding(context)),
              child: MainButton(
                onTap: _close,
                text: context.tr('new_version_modal_continue'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildVersionSection(VersionGroup group) {
    return Padding(
      padding: const EdgeInsets.only(bottom: kPadding),
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
                  crossAxisAlignment: CrossAxisAlignment.start,
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
                    Expanded(
                      child: Text(
                        note.title,
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                        ),
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
