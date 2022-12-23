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
    title: Text('settings_plan_leave_dialog_title'.tr()),
    content: Column(
      children: [
        const SizedBox(height: kPadding / 2),
        Text('settings_plan_leave_dialog_description'.tr()),
      ],
    ),
    actions: <Widget>[
      CupertinoDialogAction(
        onPressed: () => Navigator.of(context).pop(true),
        isDestructiveAction: true,
        child: Text(
          'settings_plan_leave_dialog_action_leave'.tr().toUpperCase(),
        ),
      ),
      CupertinoDialogAction(
        onPressed: () {
          Navigator.of(context).pop(false);
        },
        isDefaultAction: true,
        child: Text(
          'settings_plan_leave_dialog_action_cancel'.tr().toUpperCase(),
          style: TextStyle(color: Theme.of(context).primaryColor),
        ),
      ),
    ],
  );
}

AlertDialog _buildLeaveDialog(BuildContext context) {
  return AlertDialog(
    title: Text('settings_plan_leave_dialog_title'.tr()),
    content: Column(
      children: [
        const SizedBox(height: kPadding / 2),
        Text('settings_plan_leave_dialog_description'.tr()),
      ],
    ),
    actions: <Widget>[
      TextButton(
        onPressed: () {
          Navigator.of(context).pop(true);
        },
        child: Text(
          'settings_plan_leave_dialog_action_leave'.tr(),
          style: TextStyle(color: Theme.of(context).errorColor),
        ),
      ),
      TextButton(
        child: Text(
          'settings_plan_leave_dialog_action_cancel'.tr(),
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
    title: Text('settings_plan_delete_dialog_title'.tr()),
    content: Column(
      children: [
        const SizedBox(height: kPadding / 2),
        Text('settings_plan_delete_dialog_description'.tr()),
      ],
    ),
    actions: <Widget>[
      CupertinoDialogAction(
        onPressed: () => Navigator.of(context).pop(true),
        isDestructiveAction: true,
        child: Text(
          'settings_plan_delete_dialog_action_delete'.tr().toUpperCase(),
        ),
      ),
      CupertinoDialogAction(
        onPressed: () {
          Navigator.of(context).pop(false);
        },
        isDefaultAction: true,
        child: Text(
          'settings_plan_delete_dialog_action_cancel'.tr().toUpperCase(),
          style: TextStyle(color: Theme.of(context).primaryColor),
        ),
      ),
    ],
  );
}

AlertDialog _buildDeleteConfirmDialog(BuildContext context) {
  return AlertDialog(
    title: Text('settings_plan_delete_dialog_title'.tr()),
    content: Column(
      children: [
        const SizedBox(height: kPadding / 2),
        Text('settings_plan_delete_dialog_description'.tr()),
      ],
    ),
    actions: <Widget>[
      TextButton(
        onPressed: () {
          Navigator.of(context).pop(true);
        },
        child: Text(
          'settings_plan_delete_dialog_action_delete'.tr(),
          style: TextStyle(color: Theme.of(context).errorColor),
        ),
      ),
      TextButton(
        child: Text(
          'settings_plan_delete_dialog_action_cancel'.tr(),
          style: TextStyle(color: Theme.of(context).primaryColor),
        ),
        onPressed: () {
          Navigator.of(context).pop(false);
        },
      ),
    ],
  );
}
