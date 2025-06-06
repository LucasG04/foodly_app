import 'package:easy_localization/easy_localization.dart';
import 'package:eva_icons_flutter/eva_icons_flutter.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logging/logging.dart';
import 'package:version/version.dart';

import '../constants.dart';
import '../models/foodly_version.dart';
import '../services/lunix_api_service.dart';
import '../services/version_service.dart';
import '../utils/widget_utils.dart';
import 'main_button.dart';

class NewVersionModal extends ConsumerStatefulWidget {
  final List<String> versions;
  final List<VersionNote> versionNotes;

  static final Logger _log = Logger('NewVersionModal');

  const NewVersionModal({
    required this.versions,
    required this.versionNotes,
    super.key,
  });

  @override
  _NewVersionModalState createState() => _NewVersionModalState();

  static Future<void> open(BuildContext context) async {
    Version lastCheckedVersion;
    try {
      lastCheckedVersion =
          Version.parse(VersionService.lastCheckedVersion ?? '');
    } catch (e) {
      _log.severe(
        'NewVersionModal.open() with lastCheckedVersion: ${VersionService.lastCheckedVersion}',
        e,
      );
      return;
    }
    final publishedVersions = await _getPublishedVersions();
    // ignore: use_build_context_synchronously
    if (!context.mounted) {
      return;
    }

    final versionStrings = publishedVersions.map<String>((e) => e.toString());
    _log.fine(
      'open() with lastCheckedVersion: $lastCheckedVersion and publishedVersions: $versionStrings',
    );

    final newVersions = publishedVersions.where((v) => v > lastCheckedVersion);

    String deviceLanguageCode;
    try {
      deviceLanguageCode = context.locale.languageCode;
    } catch (e) {
      deviceLanguageCode = 'en';
    }

    final List<FoodlyVersion>? versions =
        await VersionService.getNotesForVersionsAndLanguage(
      newVersions.map((e) => e.toString()).toList(),
      deviceLanguageCode,
    );

    if (versions == null || versions.isEmpty || !context.mounted) {
      return;
    }

    // get every single note and flatten the list
    var versionNotes = versions.map((e) => e.notes).expand((i) => i).toList();
    versionNotes = checkVersionNotesForVariables(versionNotes);

    _log.finest(
      'open() with versionNotes: ${versionNotes.map((e) => '${e.title}(${e.language})')}',
    );

    // ignore: use_build_context_synchronously
    return WidgetUtils.showFoodlyBottomSheet<void>(
      context: context,
      builder: (_) => NewVersionModal(
        versions: versions.map((e) => e.version).toList(),
        versionNotes: versionNotes
            .map(
              (e) => VersionNote(
                title: e.title,
                description: e.description,
                leading: e.emoji,
              ),
            )
            .toList(),
      ),
    );
  }

  static Future<List<Version>> _getPublishedVersions() async {
    final versions = await LunixApiService.getAllPublishedVersions();
    return versions.map((e) => Version.parse(e)).toList();
  }

  @visibleForTesting
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
                color: Theme.of(context).scaffoldBackgroundColor,
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
                minHeight: MediaQuery.of(context).size.height * 0.8,
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
                        Text(
                          '${(widget.versions.length > 1 ? 'new_version_modal_version_pl' : 'new_version_modal_version').tr()} ${widget.versions.join(', ')}',
                        ),
                        const SizedBox(height: kPadding / 2),
                        ...widget.versionNotes.map((e) => _buildVersionNote(e)),
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(
                      top: kPadding / 2,
                      bottom: kPadding,
                    ),
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

  Widget _buildVersionNote(VersionNote versionNote) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: kPadding / 2),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(versionNote.leading),
          const SizedBox(width: kPadding / 4),
          Flexible(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  versionNote.title,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: kPadding / 4),
                Text(
                  versionNote.description,
                  softWrap: true,
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
  String leading;
  String title;
  String description;

  VersionNote({
    required this.leading,
    required this.title,
    required this.description,
  });
}
