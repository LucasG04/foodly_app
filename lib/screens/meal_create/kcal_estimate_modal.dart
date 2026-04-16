import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../constants.dart';
import '../../models/kcal_estimate.dart';
import '../../widgets/main_button.dart';

class KcalEstimateModal extends StatefulWidget {
  final KcalEstimate estimate;

  const KcalEstimateModal({required this.estimate, super.key});

  @override
  State<KcalEstimateModal> createState() => _KcalEstimateModalState();
}

class _KcalEstimateModalState extends State<KcalEstimateModal> {
  int? _selectedValue;
  final TextEditingController _editController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final FocusNode _focusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    _focusNode.addListener(_onFocusChange);
  }

  @override
  void dispose() {
    _editController.dispose();
    _scrollController.dispose();
    _focusNode.removeListener(_onFocusChange);
    _focusNode.dispose();
    super.dispose();
  }

  void _onFocusChange() {
    if (_focusNode.hasFocus) {
      // Wait for AnimatedSize (300ms) to finish before scrolling,
      // so maxScrollExtent reflects the fully expanded layout.
      Future.delayed(const Duration(milliseconds: 350), () {
        if (_scrollController.hasClients) {
          _scrollController.animateTo(
            _scrollController.position.maxScrollExtent,
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeOut,
          );
        }
      });
    }
  }

  void _selectValue(int value) {
    setState(() {
      _selectedValue = value;
      _editController.text = value.toString();
    });
  }

  void _apply() {
    final v = int.tryParse(_editController.text.trim());
    if (v != null) {
      Navigator.pop(context, v);
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.sizeOf(context).width;
    final contentWidth = screenWidth > 599 ? 580.0 : screenWidth;
    final horizontalPad = (screenWidth - contentWidth) / 2 + kPadding;

    return SingleChildScrollView(
      controller: _scrollController,
      padding: EdgeInsets.fromLTRB(
        horizontalPad,
        kPadding,
        horizontalPad,
        kPadding * 2 + MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            widget.estimate.explanation,
            style: Theme.of(context)
                .textTheme
                .bodyMedium
                ?.copyWith(color: Theme.of(context).hintColor),
          ),
          const SizedBox(height: kPadding),
          IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(
                  child: _ChoiceCard(
                    label: 'meal_create_kcal_ai_min'.tr(),
                    value: widget.estimate.kcalMin,
                    isSelected: _selectedValue == widget.estimate.kcalMin,
                    isHighlighted: false,
                    hasSelection: _selectedValue != null,
                    onTap: () => _selectValue(widget.estimate.kcalMin),
                  ),
                ),
                const SizedBox(width: kPadding / 2),
                Expanded(
                  child: _ChoiceCard(
                    label: 'meal_create_kcal_ai_recommended'.tr(),
                    value: widget.estimate.kcalRecommend,
                    isSelected: _selectedValue == widget.estimate.kcalRecommend,
                    isHighlighted: true,
                    hasSelection: _selectedValue != null,
                    onTap: () => _selectValue(widget.estimate.kcalRecommend),
                  ),
                ),
                const SizedBox(width: kPadding / 2),
                Expanded(
                  child: _ChoiceCard(
                    label: 'meal_create_kcal_ai_max'.tr(),
                    value: widget.estimate.kcalMax,
                    isSelected: _selectedValue == widget.estimate.kcalMax,
                    isHighlighted: false,
                    hasSelection: _selectedValue != null,
                    onTap: () => _selectValue(widget.estimate.kcalMax),
                  ),
                ),
              ],
            ),
          ),
          AnimatedSize(
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOut,
            child: _selectedValue != null
                ? Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: kPadding),
                      TextField(
                        controller: _editController,
                        focusNode: _focusNode,
                        keyboardType: TextInputType.number,
                        textInputAction: TextInputAction.done,
                        onSubmitted: (_) => _apply(),
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                        ],
                        decoration: InputDecoration(
                          suffix: const Text('kcal'),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(kRadius),
                          ),
                        ),
                      ),
                      const SizedBox(height: kPadding),
                      Center(
                        child: MainButton(
                          text: 'meal_create_kcal_ai_apply'.tr(),
                          onTap: _apply,
                        ),
                      ),
                    ],
                  )
                : const SizedBox.shrink(),
          ),
        ],
      ),
    );
  }
}

class _ChoiceCard extends StatelessWidget {
  final String label;
  final int value;
  final bool isSelected;
  final bool isHighlighted;
  final bool hasSelection;
  final VoidCallback onTap;

  const _ChoiceCard({
    required this.label,
    required this.value,
    required this.isSelected,
    required this.isHighlighted,
    required this.hasSelection,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final primaryColor = Theme.of(context).primaryColor;
    final bool dimmed = hasSelection && !isSelected;

    return AnimatedOpacity(
      duration: const Duration(milliseconds: 250),
      opacity: dimmed ? 0.4 : 1.0,
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeInOut,
          padding: const EdgeInsets.symmetric(
            vertical: kPadding,
            horizontal: kPadding / 2,
          ),
          decoration: BoxDecoration(
            color: isSelected ? primaryColor : Theme.of(context).cardColor,
            borderRadius: BorderRadius.circular(kRadius * 2),
            border: Border.all(
              color: isSelected
                  ? primaryColor
                  : isHighlighted
                      ? primaryColor.withValues(alpha: 0.5)
                      : Colors.grey.withValues(alpha: 0.3),
              width: isSelected ? 2.0 : 1.5,
            ),
            boxShadow: isHighlighted && !hasSelection
                ? [
                    BoxShadow(
                      color: primaryColor.withValues(alpha: 0.25),
                      blurRadius: 12,
                      spreadRadius: 2,
                    ),
                  ]
                : null,
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: isSelected
                      ? _contrastColor(primaryColor)
                      : Theme.of(context).hintColor,
                  letterSpacing: 0.5,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 4),
              AnimatedDefaultTextStyle(
                duration: const Duration(milliseconds: 250),
                style: TextStyle(
                  fontSize: isSelected ? 22 : 18,
                  fontWeight: FontWeight.bold,
                  color: isSelected
                      ? _contrastColor(primaryColor)
                      : Theme.of(context).textTheme.bodyLarge?.color,
                ),
                child: Text('$value'),
              ),
              const SizedBox(height: 2),
              Text(
                'kcal',
                style: TextStyle(
                  fontSize: 10,
                  color: isSelected
                      ? _contrastColor(primaryColor).withValues(alpha: 0.7)
                      : Theme.of(context).hintColor,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Color _contrastColor(Color bg) {
    final luminance = bg.computeLuminance();
    return luminance > 0.5 ? Colors.black87 : Colors.white;
  }
}
