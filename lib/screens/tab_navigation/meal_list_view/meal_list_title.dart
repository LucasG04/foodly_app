import 'package:auto_size_text/auto_size_text.dart';
import 'package:badges/badges.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:eva_icons_flutter/eva_icons_flutter.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../constants.dart';
import '../../../providers/state_providers.dart';
import 'tag_filter_modal.dart';

class MealListTitle extends StatefulWidget {
  final void Function(String) onSearch;
  final void Function() onSearchClose;
  final void Function() onRefresh;

  const MealListTitle({
    required this.onSearch,
    required this.onSearchClose,
    required this.onRefresh,
    Key? key,
  }) : super(key: key);

  @override
  State<MealListTitle> createState() => _MealListTitleState();
}

class _MealListTitleState extends State<MealListTitle> {
  bool _searchActive = false;
  TextEditingController? _textEditingController;

  @override
  void initState() {
    super.initState();

    _textEditingController = TextEditingController();
  }

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Center(
        child: SizedBox(
          height: 50.0,
          width: MediaQuery.of(context).size.width > 599
              ? 600.0
              : MediaQuery.of(context).size.width * 0.9,
          child: Row(
            children: [
              Expanded(
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 250),
                  child: _searchActive ? _buildSearchField() : _buildTitle(),
                ),
              ),
              const SizedBox(width: kPadding),
              if (!_searchActive)
                IconButton(
                  icon: const Icon(EvaIcons.refreshOutline),
                  onPressed: widget.onRefresh,
                  splashRadius: 25.0,
                ),
              const SizedBox(width: kPadding / 2),
              if (!_searchActive)
                Consumer(
                  builder: (context, ref, child) {
                    final tagFilterLength =
                        ref.watch(mealTagFilterProvider).length;
                    return Badge(
                      animationDuration: const Duration(milliseconds: 250),
                      position: BadgePosition.topEnd(top: 0, end: 3),
                      animationType: BadgeAnimationType.scale,
                      badgeColor: Theme.of(context).primaryColor,
                      badgeContent: Text(
                        tagFilterLength.toString(),
                        style: const TextStyle(color: Colors.white),
                      ),
                      child: child,
                    );
                  },
                  child: IconButton(
                    icon: const Icon(EvaIcons.options2Outline),
                    onPressed: () => _openTagFilterModal(context),
                    splashRadius: 25.0,
                  ),
                )
              else
                const SizedBox(),
              const SizedBox(width: kPadding / 2),
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 250),
                child: _searchActive
                    ? IconButton(
                        icon: const Icon(EvaIcons.close),
                        onPressed: () {
                          _textEditingController!.clear();
                          widget.onSearch('');
                          setState(() {
                            _searchActive = false;
                          });
                          widget.onSearchClose();
                        },
                        splashRadius: 25.0,
                      )
                    : IconButton(
                        icon: const Icon(EvaIcons.searchOutline),
                        onPressed: () {
                          setState(() {
                            _searchActive = true;
                          });
                        },
                        splashRadius: 25.0,
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTitle() {
    return SizedBox(
      width: double.infinity,
      child: AutoSizeText(
        'meal_list_title'.tr(),
        style: const TextStyle(
          fontSize: 32.0,
          fontWeight: FontWeight.w700,
          fontFamily: 'Poppins',
        ),
      ),
    );
  }

  Widget _buildSearchField() {
    return TextFormField(
      controller: _textEditingController,
      autofocus: true,
      onChanged: widget.onSearch,
      cursorColor: Theme.of(context).primaryColor,
      style: const TextStyle(
        fontSize: 32.0,
        fontWeight: FontWeight.w700,
        fontFamily: 'Poppins',
      ),
      decoration: InputDecoration(
        hintText: '${'meal_list_search'.tr()}...',
        enabledBorder: UnderlineInputBorder(
          borderSide: BorderSide(color: Theme.of(context).primaryColor),
        ),
        focusedBorder: UnderlineInputBorder(
          borderSide: BorderSide(color: Theme.of(context).primaryColor),
        ),
      ),
    );
  }

  void _openTagFilterModal(BuildContext context) {
    showModalBottomSheet<List<String>>(
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(10.0),
        ),
      ),
      isScrollControlled: true,
      context: context,
      builder: (_) => const TagFilterModal(),
    );
  }
}
