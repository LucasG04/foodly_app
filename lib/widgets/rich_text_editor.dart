import 'package:flutter/material.dart';
import 'package:flutter_quill/flutter_quill.dart';

class RichTextEditor extends StatelessWidget {
  final TextEditingController controller;

  const RichTextEditor({
    required this.controller,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final quillController = QuillController.basic();
    final size = MediaQuery.of(context).size;
    return SizedBox(
      width: size.width > 599 ? 600.0 : size.width * 0.95,
      height: size.height < 500
          ? 250.0
          : size.height > 1000
              ? 600.0
              : size.height * 0.5,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          QuillSimpleToolbar(
            controller: quillController,
            config: const QuillSimpleToolbarConfig(
              showBackgroundColorButton: false,
              showCenterAlignment: false,
              showClearFormat: false,
              showColorButton: false,
              showCodeBlock: false,
              showFontFamily: false,
              showFontSize: false,
              showIndent: false,
              showInlineCode: false,
              showJustifyAlignment: false,
              showLeftAlignment: false,
              showLink: false,
              showListCheck: false,
              showQuote: false,
              showRightAlignment: false,
              showSearchButton: false,
              showStrikeThrough: false,
            ),
          ),
          QuillEditor.basic(
            controller: quillController,
          )
        ],
      ),
    );
  }
}
