import 'package:easy_localization/easy_localization.dart';
import 'package:eva_icons_flutter/eva_icons_flutter.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:modal_bottom_sheet/modal_bottom_sheet.dart';
import 'package:package_info_plus/package_info_plus.dart';

import '../constants.dart';
import '../models/foodly_version.dart';
import '../services/version_service.dart';
import 'main_button.dart';

class NewVersionModal extends StatefulWidget {
  final String version;
  final List<VersionNote> versionNotes;

  const NewVersionModal({
    required this.version,
    required this.versionNotes,
    Key? key,
  }) : super(key: key);

  @override
  State<NewVersionModal> createState() => _NewVersionModalState();

  static void open(BuildContext context) async {
    final PackageInfo packageInfo = await PackageInfo.fromPlatform();
    final FoodlyVersion? version =
        await VersionService.getNotesForVersionAndLanguage(
      packageInfo.version,
      context.locale.languageCode,
    );

    if (version == null || version.notes.isEmpty) {
      return;
    }

    showBarModalBottomSheet<void>(
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(10.0),
        ),
      ),
      context: context,
      builder: (_) => NewVersionModal(
        version: packageInfo.version,
        versionNotes: version.notes
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
}

class _NewVersionModalState extends State<NewVersionModal> {
  late final ScrollController _scrollController;
  late final AutoDisposeStateProvider<bool> _$titleShowShadow;

  @override
  void initState() {
    _$titleShowShadow = AutoDisposeStateProvider((_) => false);
    _scrollController = ScrollController();
    _scrollController.addListener(() {
      final showShadow = context.read(_$titleShowShadow).state;
      if (_scrollController.offset > 0 && !showShadow) {
        context.read(_$titleShowShadow).state = true;
      } else if (_scrollController.offset <= 0 && showShadow) {
        context.read(_$titleShowShadow).state = false;
      }
    });
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Consumer(
          builder: (context, ref, child) {
            final showShadow = ref(_$titleShowShadow).state;
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
                  minHeight: MediaQuery.of(context).size.height * 0.8),
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
                          '${'new_version_modal_version'.tr()} ${widget.version}',
                        ),
                        const SizedBox(height: kPadding / 2),
                        ...widget.versionNotes
                            .map((e) => _buildVersionNote(e))
                            .toList(),
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