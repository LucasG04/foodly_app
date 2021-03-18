import 'package:flutter/material.dart';

class SelectableTagTile extends StatefulWidget {
  final String tag;
  final bool initiallySelected;

  const SelectableTagTile({
    @required this.tag,
    this.initiallySelected = false,
  });

  @override
  _SelectableTagTileState createState() => _SelectableTagTileState();
}

class _SelectableTagTileState extends State<SelectableTagTile> {
  bool _isSelected;

  @override
  void initState() {
    _isSelected = widget.initiallySelected;
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Container();
  }
}
