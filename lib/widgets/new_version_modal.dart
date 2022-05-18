import 'package:easy_localization/easy_localization.dart';
import 'package:eva_icons_flutter/eva_icons_flutter.dart';
import 'package:flutter/material.dart';
import 'package:modal_bottom_sheet/modal_bottom_sheet.dart';
import 'package:package_info_plus/package_info_plus.dart';

import '../constants.dart';
import '../models/foodly_version.dart';
import '../services/version_service.dart';
import 'main_button.dart';

// ignore: avoid_classes_with_only_static_members
class NewFeaturesModalUtils {
  static void open(BuildContext context) async {
    final PackageInfo packageInfo = await PackageInfo.fromPlatform();
    final FoodlyVersion version =
        await VersionService.getNotesForVersionAndLanguage(
      packageInfo.version,
      context.locale.languageCode,
    );

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
}

class _NewVersionModalState extends State<NewVersionModal> {
  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                'new_version_modal_title'.tr().toUpperCase(),
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            IconButton(
              icon: const Icon(EvaIcons.arrowBackOutline),
              onPressed: _close,
            ),
          ],
        ),
        const SizedBox(height: kPadding / 2),
        SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: kPadding / 4),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '${'new_version_modal_version'.tr()} ${widget.version}',
                    ),
                    ...widget.versionNotes
                        .map((e) => _buildVersionNote(e))
                        .toList(),
                    Text('new_version_modal_where_to_find'.tr()),
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
      ],
    );
  }

  Widget _buildVersionNote(VersionNote versionNote) {
    return Row(
      children: [
        Text(versionNote.leading),
        const SizedBox(width: kPadding / 4),
        Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              versionNote.title,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: kPadding / 4),
            Text(versionNote.description),
          ],
        ),
      ],
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
