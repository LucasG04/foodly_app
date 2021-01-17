import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:eva_icons_flutter/eva_icons_flutter.dart';
import 'package:flutter/material.dart';
import 'package:foodly/constants.dart';
import 'package:foodly/widgets/main_text_field.dart';
import 'package:foodly/widgets/small_circular_progress_indicator.dart';

class MainImagePicker extends StatefulWidget {
  final String imageUrl;
  final Function(Image) onPick;

  MainImagePicker({
    this.imageUrl,
    this.onPick,
  });

  @override
  _MainImagePickerState createState() => _MainImagePickerState();
}

class _MainImagePickerState extends State<MainImagePicker> {
  bool _showInput = false;
  TextEditingController _urlController = new TextEditingController();
  String _imageUrl;

  @override
  void initState() {
    _imageUrl = widget.imageUrl;
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    final edgeLength = 300.0;
    return Container(
      width: edgeLength,
      height: edgeLength,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          InkWell(
            child: Container(
              width: edgeLength * 0.6,
              height: edgeLength * 0.6,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(kRadius),
                border: Border.all(color: Colors.black87),
              ),
              child: Center(
                child: _imageUrl == null || _imageUrl.isEmpty
                    ? Icon(EvaIcons.plusCircleOutline)
                    : CachedNetworkImage(
                        imageUrl: _imageUrl,
                        placeholder: (context, url) =>
                            SmallCircularProgressIndicator(),
                      ),
              ),
            ),
          ),
          Container(
            margin: const EdgeInsets.only(top: 8.0),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(kRadius),
              color: Theme.of(context).dialogBackgroundColor,
              boxShadow: [kSmallShadow],
            ),
            child: MainTextField(controller: _urlController),
          ),
        ],
      ),
    );
  }
}
