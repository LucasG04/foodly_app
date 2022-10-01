import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../../constants.dart';

// ignore: avoid_classes_with_only_static_members
class HomeScreenDialogs {
  static CupertinoAlertDialog updateDialogCupertino({
    required void Function() onUpdate,
    required void Function() onDismiss,
  }) {
    return CupertinoAlertDialog(
      title: Column(
        children: <Widget>[
          Text('update_dialog_title'.tr(args: [kAppName])),
        ],
      ),
      content: Column(
        children: [
          const SizedBox(height: kPadding / 2),
          Text('update_dialog_description'.tr()),
          Text('update_dialog_question'.tr()),
        ],
      ),
      actions: <Widget>[
        CupertinoDialogAction(
          onPressed: onDismiss,
          isDestructiveAction: true,
          child: Text('update_dialog_action_later'.tr().toUpperCase()),
        ),
        CupertinoDialogAction(
          onPressed: onUpdate,
          isDefaultAction: true,
          child: Text('update_dialog_action_update'.tr().toUpperCase()),
        ),
      ],
    );
  }

  static CupertinoAlertDialog lockPlanCupertino({
    required void Function() onLock,
    required void Function() onDismiss,
  }) {
    return CupertinoAlertDialog(
      title: Column(
        children: <Widget>[
          Text('lock_plan_dialog_title'.tr()),
        ],
      ),
      content: Column(
        children: [
          const SizedBox(height: kPadding / 2),
          Text('lock_plan_dialog_description'.tr()),
        ],
      ),
      actions: <Widget>[
        CupertinoDialogAction(
          onPressed: onDismiss,
          isDestructiveAction: true,
          child: Text('lock_plan_dialog_action_later'.tr().toUpperCase()),
        ),
        CupertinoDialogAction(
          onPressed: onLock,
          isDefaultAction: true,
          child: Text('lock_plan_dialog_action_lock'.tr().toUpperCase()),
        ),
      ],
    );
  }

  static AlertDialog lockPlanMaterial({
    required void Function() onLock,
    required void Function() onDismiss,
    required BuildContext context,
  }) {
    return AlertDialog(
      title: Column(
        children: <Widget>[
          Text('lock_plan_dialog_title'.tr()),
        ],
      ),
      content: Column(
        children: [
          const SizedBox(height: kPadding / 2),
          Text('lock_plan_dialog_description'.tr()),
        ],
      ),
      actions: <Widget>[
        TextButton(
          onPressed: onDismiss,
          child: Text('lock_plan_dialog_action_later'.tr()),
        ),
        TextButton(
          onPressed: onLock,
          child: Text(
            'lock_plan_dialog_action_lock'.tr(),
            style: TextStyle(color: Theme.of(context).primaryColor),
          ),
        ),
      ],
    );
  }
}
