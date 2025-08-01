import 'package:auto_size_text/auto_size_text.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:eva_icons_flutter/eva_icons_flutter.dart';
import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logging/logging.dart';
import 'package:url_launcher/url_launcher.dart';

import '../utils/of_context_mixin.dart';

class MarkdownEditor extends ConsumerStatefulWidget {
  final TextEditingController textEditingController;

  const MarkdownEditor({
    required this.textEditingController,
    super.key,
  });

  @override
  _MarkdownEditorState createState() => _MarkdownEditorState();
}

class _MarkdownEditorState extends ConsumerState<MarkdownEditor>
    with OfContextMixin, TickerProviderStateMixin {
  static final log = Logger('MarkdownEditor');

  late AutoDisposeStateProvider<String> _$currentText;
  late TabController _tabController;

  @override
  void initState() {
    _$currentText = StateProvider.autoDispose<String>(
        (_) => widget.textEditingController.text);
    _tabController = TabController(vsync: this, length: 2);
    super.initState();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final textColor = theme.textTheme.bodyLarge!.color;
    return SizedBox(
      width: media.size.width > 599 ? 600.0 : media.size.width * 0.9,
      height: media.size.height < 500
          ? 250.0
          : media.size.height > 1000
              ? 600.0
              : media.size.height * 0.5,
      child: Column(
        children: [
          TabBar(
            controller: _tabController,
            indicatorColor: textColor,
            tabs: [
              Tab(
                child: Wrap(
                  alignment: WrapAlignment.center,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: <Widget>[
                    Icon(EvaIcons.editOutline, color: textColor),
                    const SizedBox(width: 8.0),
                    Text('markdown_edit', style: TextStyle(color: textColor))
                        .tr(),
                  ],
                ),
              ),
              Tab(
                child: Wrap(
                  alignment: WrapAlignment.center,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: <Widget>[
                    Icon(EvaIcons.eyeOutline, color: textColor),
                    const SizedBox(width: 8.0),
                    Text('markdown_preview', style: TextStyle(color: textColor))
                        .tr(),
                  ],
                ),
              )
            ],
          ),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: <Widget>[
                Padding(
                  padding: const EdgeInsets.symmetric(
                    vertical: 5.0,
                    horizontal: 20.0,
                  ),
                  child: Scrollbar(
                    thickness: 2.5,
                    child: TextFormField(
                      controller: widget.textEditingController,
                      scrollController: ScrollController(),
                      maxLines: null,
                      onChanged: (data) =>
                          ref.read(_$currentText.notifier).state = data,
                      decoration: const InputDecoration(
                        border: InputBorder.none,
                        hintText:
                            '# Title\n## Subtitle\n- The quick brown fox jumps over the lazy dog\n- Lorem ipsum dolor sit amet, ...',
                      ),
                      cursorColor: theme.primaryColor,
                      minLines: 6,
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(
                    vertical: 5.0,
                    horizontal: 20.0,
                  ),
                  child: Scrollbar(
                    thickness: 2.5,
                    child: SingleChildScrollView(
                      controller: ScrollController(),
                      child: Consumer(builder: (context, ref, child) {
                        final text = ref.watch(_$currentText);
                        return MarkdownBody(
                          data: text,
                          selectable: true,
                          onTapLink: (_, href, __) => openLink(href!),
                        );
                      }),
                    ),
                  ),
                ),
              ],
            ),
          ),
          Container(
            decoration: const BoxDecoration(
              border: Border(
                top: BorderSide(color: Colors.black38),
              ),
            ),
            child: GestureDetector(
              onTap: () => openLink('https://commonmark.org/help/'),
              child: Padding(
                padding: const EdgeInsets.all(10.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Flexible(
                      child: AutoSizeText(
                        'markdown_format_text'.tr(),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Image.asset('assets/images/md-icon.png', width: 30.0),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void openLink(String href) async {
    final url = Uri.parse(href);
    if (await canLaunchUrl(url)) {
      await launchUrl(url);
    } else {
      log.severe('ERR in linkOnTapHandler()! Could not launch $href');
    }
  }
}
