import 'package:fleek/values/Keys.dart';
import 'package:fleek/values/colors.dart';
import 'package:fleek/values/styles.dart';
import 'package:flutter/material.dart';

class AutoGreyDropdownFormField extends StatefulWidget {
  final EdgeInsets padding;
  final String labelText;
  final Function(String) onChanged;
  final Function(String) validator;
  final List<String> items;

  final bool isType;
  final bool isPost;

  AutoGreyDropdownFormField({
    this.padding,
    this.labelText,
    @required this.onChanged,
    this.validator,
    @required this.items,
    this.isType,
    this.isPost,
  });

  _AutoGreyDropdownFormField createState() => _AutoGreyDropdownFormField();
}

class _AutoGreyDropdownFormField extends State<AutoGreyDropdownFormField> {
  EdgeInsets padding;
  String labelText;
  Function(String) onChanged;
  Function(String) validator;
  List<String> items;

  GlobalKey<FormFieldState> key;

  bool shouldFill = true;

  @override
  void initState() {
    super.initState();

    padding = widget.padding;
    labelText = widget.labelText;
    onChanged = widget.onChanged;
    validator = widget.validator;
    items = widget.items;
    bool isType = (widget.isType != null) ? widget.isType : false;
    bool isPost = (widget.isPost != null) ? widget.isPost : false;
    if (isType) key = isPost ? Keys.createPostTypeKey : Keys.createProductTypeKey;
  }
  @override
  Widget build(BuildContext context) {
    return new Padding(
      padding: padding,
      child: DropdownButtonFormField(
        key: key,
        validator: validator,
        decoration: InputDecoration(
          filled: shouldFill,
          fillColor: CustomColors.createGrey,
          labelText: labelText,
          enabledBorder: Styles.createInputBorderEnabled,
          border: Styles.createInputBorder,
        ),
        value: null,
        onChanged: (value) {
          onChanged(value);
          setState(() {
            shouldFill = value.isEmpty;
          });
        },
        items: items.map((value) => DropdownMenuItem<String>(
          value: value,
          child: Text(value),
        )).toList(),
      ),
    );
  }

}