import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../../constants.dart';

// ignore: avoid_classes_with_only_static_members
class HomeScreenDialogs {
  static CupertinoAlertDialog updateDialogCupertino(
    BuildContext context, {
    required void Function() onUpdate,
    required void Function() onDismiss,
  }) {
    return CupertinoAlertDialog(
      title: Column(
        children: <Widget>[
          Text(context.tr('update_dialog_title', args: [kAppName])),
        ],
      ),
      content: Column(
        children: [
          const SizedBox(height: kPadding / 2),
          Text(context.tr('update_dialog_description')),
          Text(context.tr('update_dialog_question')),
        ],
      ),
      actions: <Widget>[
        CupertinoDialogAction(
          onPressed: onDismiss,
          isDestructiveAction: true,
          child: Text(context.tr('update_dialog_action_later').toUpperCase()),
        ),
        CupertinoDialogAction(
          onPressed: onUpdate,
          isDefaultAction: true,
          child: Text(
            context.tr('update_dialog_action_update').toUpperCase(),
            style: TextStyle(color: Theme.of(context).primaryColor),
          ),
        ),
      ],
    );
  }

  static CupertinoAlertDialog lockPlanCupertino(
    BuildContext context, {
    required void Function() onLock,
    required void Function() onDismiss,
  }) {
    return CupertinoAlertDialog(
      title: Column(
        children: <Widget>[
          Text(context.tr('lock_plan_dialog_title')),
        ],
      ),
      content: Column(
        children: [
          const SizedBox(height: kPadding / 2),
          Text(context.tr('lock_plan_dialog_description')),
        ],
      ),
      actions: <Widget>[
        CupertinoDialogAction(
          onPressed: onDismiss,
          isDestructiveAction: true,
          child:
              Text(context.tr('lock_plan_dialog_action_later').toUpperCase()),
        ),
        CupertinoDialogAction(
          onPressed: onLock,
          isDefaultAction: true,
          child: Text(
            context.tr('lock_plan_dialog_action_lock').toUpperCase(),
            style: TextStyle(color: Theme.of(context).primaryColor),
          ),
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
          Text(context.tr('lock_plan_dialog_title')),
        ],
      ),
      content: Column(
        children: [
          const SizedBox(height: kPadding / 2),
          Text(context.tr('lock_plan_dialog_description')),
        ],
      ),
      actions: <Widget>[
        TextButton(
          onPressed: onDismiss,
          child: Text(context.tr('lock_plan_dialog_action_later')),
        ),
        TextButton(
          onPressed: onLock,
          child: Text(
            context.tr('lock_plan_dialog_action_lock'),
            style: TextStyle(color: Theme.of(context).primaryColor),
          ),
        ),
      ],
    );
  }
}
