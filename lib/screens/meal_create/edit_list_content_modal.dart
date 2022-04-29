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

class EditListContentModal extends StatefulWidget {
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
  State<EditListContentModal> createState() => _EditListContentModalState();
}

class _EditListContentModalState extends State<EditListContentModal> {
  late List<String> _selectedContent;
  late List<String> _allContent;
  late AutoDisposeStateProvider<List<String>> _filteredList;

  final TextEditingController _textEditingController = TextEditingController();
  final _debouncer = Debouncer(milliseconds: 500);

  ShapeBorder get _listTileShape =>
      RoundedRectangleBorder(borderRadius: BorderRadius.circular(5.0));

  @override
  void initState() {
    _selectedContent = widget.selectedContent;
    _allContent = widget.allContent;
    _filteredList = StateProvider.autoDispose<List<String>>((_) => _allContent);
    _textEditingController.addListener(() => _debouncer.run(_filterAllContent));
    super.initState();
  }

  @override
  void dispose() {
    _debouncer.dispose();
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
                        fontSize: 20, fontWeight: FontWeight.bold),
                    textAlign: TextAlign.center,
                  ),
                  TextButton(
                    onPressed: _closeModal,
                    child: const Text('save').tr(),
                  )
                ],
              ),
            ),
          ),
          MainTextField(
            controller: _textEditingController,
            infoText: widget.textFieldInfo,
          ),
          Consumer(builder: (ctx, ref, child) {
            print('consume lsit');
            final list = ref(_filteredList).state;
            return _allContent.isEmpty && _textEditingController.text.isEmpty
                ? UserInformation(
                    'assets/images/undraw_empty.png',
                    'meal_create_edit_tags_no_results'.tr(),
                    'meal_create_edit_tags_no_results_msg'.tr(),
                  )
                : AnimationLimiter(
                    child: ListView.separated(
                      shrinkWrap: true,
                      itemBuilder: (ctx, index) {
                        return AnimationConfiguration.staggeredList(
                          position: index,
                          duration: const Duration(milliseconds: 250),
                          child: SlideAnimation(
                            verticalOffset: 50.0,
                            child: FadeInAnimation(
                              child: _buildListTile(list, index, ctx),
                            ),
                          ),
                        );
                      },
                      separatorBuilder: (_, __) => const Divider(),
                      itemCount:
                          list.isEmpty && _textEditingController.text.isNotEmpty
                              ? 1
                              : list.length,
                    ),
                  );
          }),
          const SizedBox(height: kPadding),
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
      selectedTileColor: Theme.of(ctx).primaryColor.withOpacity(0.25),
      onTap: () => _selectValue(text),
      shape: _listTileShape,
      dense: true,
    );
  }

  Widget _buildAddToListTile() {
    final value = _textEditingController.text.trim();
    return ListTile(
      title: Text(value),
      subtitle: Text('add'.tr()),
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
    _updateFilteredList(_allContent);
  }

  bool _isSelected(String value) {
    return _selectedContent.contains(value);
  }

  void _filterAllContent() {
    final filter = _textEditingController.text.trim();
    final filtered = _allContent
        .where((e) => e.toLowerCase().contains(filter.toLowerCase()))
        .toList();
    _updateFilteredList(filtered);
  }

  void _closeModal() {
    Navigator.of(context).pop(_selectedContent);
  }

  void _updateFilteredList(List<String> list) {
    if (listEquals<String>(list, context.read(_filteredList).state)) {
      return;
    }
    context.read(_filteredList).state = list;
  }
}
