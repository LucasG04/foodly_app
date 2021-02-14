import 'package:cached_network_image/cached_network_image.dart';
import 'package:eva_icons_flutter/eva_icons_flutter.dart';
import 'package:flutter/material.dart';

import '../constants.dart';
import 'main_text_field.dart';
import 'small_circular_progress_indicator.dart';

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
  TextEditingController _urlController = new TextEditingController();
  String _imageUrl;
  LoadState _loadState;

  @override
  void initState() {
    // _imageUrl = widget.imageUrl;
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    final edgeLength = 300.0;
    return Padding(
      padding: const EdgeInsets.all(kPadding),
      child: Row(
        children: [
          Flexible(
            flex: 1,
            child: InkWell(
              child: Container(
                width: edgeLength * 0.6,
                height: edgeLength * 0.6,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(kRadius),
                  border: Border.all(color: Colors.black87),
                ),
                child: Center(
                  child: _imageUrl == null || _imageUrl.isEmpty
                      ? Icon(EvaIcons.imageOutline)
                      : CachedNetworkImage(
                          imageUrl: _imageUrl,
                          progressIndicatorBuilder: (context, url, progress) {
                            print(progress.downloaded);
                            Future.delayed(Duration.zero, () {
                              if (progress.downloaded == progress.totalSize) {
                                setState(() {
                                  _loadState = LoadState.SUCCESS;
                                });
                              } else if (progress.downloaded == 0) {
                                setState(() {
                                  _loadState = null;
                                });
                              } else if (progress.downloaded <
                                  progress.totalSize) {
                                setState(() {
                                  _loadState = LoadState.LOADING;
                                });
                              }
                            });

                            return Center(
                                child: SmallCircularProgressIndicator());
                          },
                          errorWidget: (context, url, error) {
                            if (error != null) {
                              Future.delayed(Duration.zero, () {
                                setState(() {
                                  _loadState = LoadState.ERROR;
                                });
                              });
                            }
                            return Container();
                          },
                        ),
                ),
              ),
            ),
          ),
          SizedBox(width: kPadding),
          Flexible(
            flex: 3,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                MainTextField(
                  controller: _urlController,
                  placeholder: 'https://www.foodly.de/images/meal-chips.jpg',
                  onChange: (text) {
                    if (Uri.parse(text).isAbsolute) {
                      setState(() {
                        _imageUrl = text;
                      });
                    } else if (text.isEmpty) {
                      setState(() {
                        _loadState = null;
                      });
                    }
                  },
                ),
                SizedBox(height: kPadding),
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 350),
                  child: _loadState == LoadState.LOADING
                      ? ListTile(
                          leading: SmallCircularProgressIndicator(),
                          title: Text("Bild wird geladen..."),
                        )
                      : _loadState == LoadState.SUCCESS
                          ? ListTile(
                              leading: Icon(EvaIcons.checkmarkCircle2Outline),
                              title: Text("Bild erfolgreich geladen."),
                            )
                          : _loadState == LoadState.ERROR
                              ? ListTile(
                                  leading: Icon(EvaIcons.alertCircleOutline),
                                  title:
                                      Text("Bild konnte nicht gladen werden."),
                                )
                              : ListTile(
                                  leading: Icon(EvaIcons.infoOutline),
                                  title: Text(
                                      "Bitte füg die URL zu einem Bild ein."),
                                ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

enum LoadState { SUCCESS, LOADING, ERROR }
