import 'package:easy_localization/easy_localization.dart';
import 'package:eva_icons_flutter/eva_icons_flutter.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';

import '../../constants.dart';
import '../../utils/debouncer.dart';
import '../../widgets/main_text_field.dart';
import '../../widgets/user_information.dart';

class EditListContentModal extends ConsumerStatefulWidget {
  final String title;
  final String textFieldInfo;
  final List<String> selectedContent;
  final List<String> allContent;

  const EditListContentModal({
    required this.title,
    this.textFieldInfo = '',
    required this.selectedContent,
    required this.allContent,
    Key? key,
  }) : super(key: key);

  @override
  _EditListContentModalState createState() => _EditListContentModalState();
}

class _EditListContentModalState extends ConsumerState<EditListContentModal> {
  late List<String> _selectedContent;
  late List<String> _allContent;

  late AutoDisposeStateProvider<List<String>> _$filteredList;
  late AutoDisposeStateProvider<bool> _$showInfoText;
  late Key _animationLimiterKey;

  final TextEditingController _textEditingController = TextEditingController();
  final _debouncer = Debouncer(milliseconds: 500);

  ShapeBorder get _listTileShape =>
      RoundedRectangleBorder(borderRadius: BorderRadius.circular(5.0));

  @override
  void initState() {
    _animationLimiterKey = UniqueKey();
    _selectedContent = widget.selectedContent;
    _allContent = widget.allContent;
    _$filteredList =
        StateProvider.autoDispose<List<String>>((_) => _allContent);
    _$showInfoText = StateProvider.autoDispose<bool>((_) => true);
    _textEditingController.addListener(() {
      _debouncer.run(_filterAllContent);
      if (ref.read(_$showInfoText) && _textEditingController.text.isNotEmpty) {
        ref.read(_$showInfoText.notifier).state = false;
      }
    });
    super.initState();
  }

  @override
  void dispose() {
    _debouncer.dispose();
    _textEditingController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width > 599
        ? 580.0
        : MediaQuery.of(context).size.width * 0.8;

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: (MediaQuery.of(context).size.width - width) / 2,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Center(
            child: Padding(
              padding: const EdgeInsets.only(top: kPadding),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    widget.title.toUpperCase(),
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  TextButton(
                    onPressed: _closeModal,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text('done').tr(),
                        const SizedBox(width: 5.0),
                        const Icon(EvaIcons.doneAllOutline)
                      ],
                    ),
                  )
                ],
              ),
            ),
          ),
          MainTextField(controller: _textEditingController),
          Consumer(builder: (_, ref, __) {
            final show = ref.watch(_$showInfoText);
            return show
                ? Padding(
                    padding: const EdgeInsets.only(bottom: kPadding / 2),
                    child: Text(widget.textFieldInfo),
                  )
                : const SizedBox();
          }),
          Flexible(
            child: Consumer(builder: (ctx, ref, child) {
              final list = ref.watch(_$filteredList);
              return _allContent.isEmpty && _textEditingController.text.isEmpty
                  ? UserInformation(
                      assetPath: 'assets/images/undraw_empty.png',
                      title: 'meal_create_edit_tags_no_results'.tr(),
                      message: 'meal_create_edit_tags_no_results_msg'.tr(),
                    )
                  : AnimationLimiter(
                      key: _animationLimiterKey,
                      child: ListView.separated(
                        shrinkWrap: true,
                        itemBuilder: (ctx, index) =>
                            AnimationConfiguration.staggeredList(
                          position: index,
                          duration: const Duration(milliseconds: 375),
                          child: SlideAnimation(
                            verticalOffset: 50.0,
                            child: FadeInAnimation(
                              child: _buildListTile(list, index, ctx),
                            ),
                          ),
                        ),
                        separatorBuilder: (_, __) => const Divider(),
                        itemCount: list.isEmpty &&
                                _textEditingController.text.isNotEmpty
                            ? list.length + 1
                            : list.length,
                      ),
                    );
            }),
          ),
        ],
      ),
    );
  }

  Widget _buildListTile(List<String> list, int index, BuildContext ctx) {
    if (list.isEmpty && _textEditingController.text.isNotEmpty) {
      return _buildAddToListTile();
    }

    final text = list[index];
    final isSelected = _isSelected(text);
    return ListTile(
      title: Text(text),
      trailing: isSelected
          ? Icon(
              EvaIcons.checkmark,
              color: Theme.of(ctx).primaryColor,
            )
          : const SizedBox(),
      selected: isSelected,
      onTap: () => _selectValue(text),
      shape: _listTileShape,
      dense: true,
    );
  }

  Widget _buildAddToListTile() {
    final value = _textEditingController.text.trim();
    return ListTile(
      title: Text(value),
      subtitle: Text('meal_create_edit_tags_create_tile'.tr()),
      onTap: () => _selectValue(value),
      trailing: Icon(
        EvaIcons.plusCircleOutline,
        color: Theme.of(context).primaryColor,
      ),
      shape: _listTileShape,
      dense: true,
    );
  }

  void _selectValue(String value) {
    if (_isSelected(value)) {
      _selectedContent.remove(value);
    } else {
      if (!_allContent.contains(value)) {
        _allContent.add(value);
      }
      _selectedContent.add(value);
    }
    _textEditingController.clear();

    // set to `[]`, to force state change, to correctly display selected items
    ref.read(_$filteredList.notifier).state = [];
    ref.read(_$filteredList.notifier).state = _allContent;
  }

  bool _isSelected(String value) {
    return _selectedContent.contains(value);
  }

  void _filterAllContent() {
    final filter = _textEditingController.text.trim();
    final filtered = _allContent
        .where((e) => e.toLowerCase().contains(filter.toLowerCase()))
        .toList();

    ref.read(_$filteredList.notifier).state = filtered;
  }

  void _closeModal() {
    Navigator.of(context).pop(_selectedContent);
  }
}
