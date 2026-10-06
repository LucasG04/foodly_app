import 'dart:io';

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../../constants.dart';

Future<bool> showLeaveConfirmDialog(BuildContext context) async {
  final leavePlan = await showDialog<bool?>(
    context: context,
    builder: (_) => Platform.isIOS || Platform.isMacOS
        ? _buildIOSLeaveDialog(context)
        : _buildLeaveDialog(context),
  );

  return leavePlan != null && leavePlan;
}

CupertinoAlertDialog _buildIOSLeaveDialog(BuildContext context) {
  return CupertinoAlertDialog(
    title: Text(context.tr('settings_plan_leave_dialog_title')),
    content: Column(
      children: [
        const SizedBox(height: kPadding / 2),
        Text(context.tr('settings_plan_leave_dialog_description')),
      ],
    ),
    actions: <Widget>[
      CupertinoDialogAction(
        onPressed: () => Navigator.of(context).pop(true),
        isDestructiveAction: true,
        child: Text(
          context.tr('settings_plan_leave_dialog_action_leave').toUpperCase(),
        ),
      ),
      CupertinoDialogAction(
        onPressed: () {
          Navigator.of(context).pop(false);
        },
        isDefaultAction: true,
        child: Text(
          context.tr('settings_plan_leave_dialog_action_cancel').toUpperCase(),
          style: TextStyle(color: Theme.of(context).primaryColor),
        ),
      ),
    ],
  );
}

AlertDialog _buildLeaveDialog(BuildContext context) {
  return AlertDialog(
    title: Text(context.tr('settings_plan_leave_dialog_title')),
    content: Column(
      children: [
        const SizedBox(height: kPadding / 2),
        Text(context.tr('settings_plan_leave_dialog_description')),
      ],
    ),
    actions: <Widget>[
      TextButton(
        onPressed: () {
          Navigator.of(context).pop(true);
        },
        child: Text(
          context.tr('settings_plan_leave_dialog_action_leave'),
          style: TextStyle(color: Theme.of(context).colorScheme.error),
        ),
      ),
      TextButton(
        child: Text(
          context.tr('settings_plan_leave_dialog_action_cancel'),
          style: TextStyle(color: Theme.of(context).primaryColor),
        ),
        onPressed: () {
          Navigator.of(context).pop(false);
        },
      ),
    ],
  );
}

Future<bool> showDeleteConfirmDialog(BuildContext context) async {
  final delete = await showDialog<bool?>(
    context: context,
    builder: (_) => Platform.isIOS || Platform.isMacOS
        ? _buildIOSDeleteConfirmDialog(context)
        : _buildDeleteConfirmDialog(context),
  );

  return delete != null && delete;
}

CupertinoAlertDialog _buildIOSDeleteConfirmDialog(BuildContext context) {
  return CupertinoAlertDialog(
    title: Text(context.tr('settings_plan_delete_dialog_title')),
    content: Column(
      children: [
        const SizedBox(height: kPadding / 2),
        Text(context.tr('settings_plan_delete_dialog_description')),
      ],
    ),
    actions: <Widget>[
      CupertinoDialogAction(
        onPressed: () => Navigator.of(context).pop(true),
        isDestructiveAction: true,
        child: Text(
          context.tr('settings_plan_delete_dialog_action_delete').toUpperCase(),
        ),
      ),
      CupertinoDialogAction(
        onPressed: () {
          Navigator.of(context).pop(false);
        },
        isDefaultAction: true,
        child: Text(
          context.tr('settings_plan_delete_dialog_action_cancel').toUpperCase(),
          style: TextStyle(color: Theme.of(context).primaryColor),
        ),
      ),
    ],
  );
}

AlertDialog _buildDeleteConfirmDialog(BuildContext context) {
  return AlertDialog(
    title: Text(context.tr('settings_plan_delete_dialog_title')),
    content: Column(
      children: [
        const SizedBox(height: kPadding / 2),
        Text(context.tr('settings_plan_delete_dialog_description')),
      ],
    ),
    actions: <Widget>[
      TextButton(
        onPressed: () {
          Navigator.of(context).pop(true);
        },
        child: Text(
          context.tr('settings_plan_delete_dialog_action_delete'),
          style: TextStyle(color: Theme.of(context).colorScheme.error),
        ),
      ),
      TextButton(
        child: Text(
          context.tr('settings_plan_delete_dialog_action_cancel'),
          style: TextStyle(color: Theme.of(context).primaryColor),
        ),
        onPressed: () {
          Navigator.of(context).pop(false);
        },
      ),
    ],
  );
}
