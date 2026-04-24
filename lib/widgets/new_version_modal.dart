import 'package:easy_localization/easy_localization.dart';
import 'package:eva_icons_flutter/eva_icons_flutter.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../constants.dart';
import '../models/foodly_version.dart';
import 'main_button.dart';

class NewVersionModal extends ConsumerStatefulWidget {
  final List<VersionGroup> versionGroups;

  const NewVersionModal({
    required this.versionGroups,
    super.key,
  });

  @override
  _NewVersionModalState createState() => _NewVersionModalState();

  static List<FoodlyVersionNote> checkVersionNotesForVariables(
      List<FoodlyVersionNote> notes) {
    return notes.map((e) {
      if (e.title.contains('{appName}')) {
        e.title = e.title.replaceAll('{appName}', kAppName);
      }
      if (e.description.contains('{appName}')) {
        e.description = e.description.replaceAll('{appName}', kAppName);
      }
      return e;
    }).toList();
  }
}

class _NewVersionModalState extends ConsumerState<NewVersionModal> {
  late final ScrollController _scrollController;
  late final AutoDisposeStateProvider<bool> _$titleShowShadow;

  @override
  void initState() {
    _$titleShowShadow = AutoDisposeStateProvider((_) => false);
    _scrollController = ScrollController();
    _scrollController.addListener(_handleTitleShadowState);
    super.initState();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Consumer(
          builder: (context, ref, child) {
            final showShadow = ref.watch(_$titleShowShadow);
            return Container(
              padding: const EdgeInsets.all(kPadding / 2),
              decoration: BoxDecoration(
                color: Theme.of(context).dialogTheme.backgroundColor,
                boxShadow: showShadow
                    ? [
                        const BoxShadow(
                          offset: Offset(0, 1),
                          blurRadius: 1,
                          color: Color.fromRGBO(0, 0, 0, .16),
                        )
                      ]
                    : [],
              ),
              child: child,
            );
          },
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
        Expanded(
          child: SingleChildScrollView(
            controller: _scrollController,
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
        ),
      ],
    );
  }

  Widget _buildVersionSection(VersionGroup group) {
    return Padding(
      padding: const EdgeInsets.only(top: kPadding),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
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
              if (group.emoji != null) ...[
                const SizedBox(width: kPadding / 2),
                Text(
                  group.emoji!,
                  style: const TextStyle(fontSize: 16),
                  strutStyle: const StrutStyle(
                    fontSize: 16,
                    forceStrutHeight:
                        true, // Zwingt das Widget, die Höhe strikt zu berechnen
                  ),
                )
              ],
            ],
          ),
          const SizedBox(height: kPadding / 2),
          ...group.notes.asMap().entries.map((entry) {
            final isFirst = entry.key == 0;
            return Padding(
              padding: EdgeInsets.only(top: isFirst ? 0 : kPadding / 2),
              child: _buildNoteCard(entry.value, group.emoji),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildNoteCard(VersionNote note, String? emoji) {
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
                Text(
                  note.title,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                  ),
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

  void _handleTitleShadowState() {
    final showShadow = ref.read(_$titleShowShadow);
    if (_scrollController.offset > 0 && !showShadow) {
      ref.read(_$titleShowShadow.notifier).state = true;
    } else if (_scrollController.offset <= 0 && showShadow) {
      ref.read(_$titleShowShadow.notifier).state = false;
    }
  }
}

class VersionNote {
  String title;
  String description;

  VersionNote({
    required this.title,
    required this.description,
  });
}

class VersionGroup {
  final String version;
  final String? emoji;
  final List<VersionNote> notes;

  const VersionGroup({
    required this.version,
    this.emoji,
    required this.notes,
  });
}
