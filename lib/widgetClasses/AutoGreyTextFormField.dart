import 'package:fleek/values/colors.dart';
import 'package:fleek/values/ints.dart';
import 'package:fleek/values/styles.dart';
import 'package:flutter/material.dart';

class AutoGreyTextFormField extends StatefulWidget {
  final EdgeInsets padding;
  final TextEditingController controller;
  final String labelText;
  final String hintText;
  final Function(String) validator;
  final TextInputType keyboardType;

  final bool maxLengthEnforced;
  final int maxLength;
  final int minLines;
  final int maxLines;

  AutoGreyTextFormField({
    @required this.padding,
    @required this.controller,
    @required this.validator,
    this.keyboardType,
    this.labelText,
    this.hintText,
    this.maxLengthEnforced,
    this.maxLength,
    this.minLines,
    this.maxLines,
  });

  _AutoGreyTextFormFieldState createState() => _AutoGreyTextFormFieldState();
}

class _AutoGreyTextFormFieldState extends State<AutoGreyTextFormField> {
  EdgeInsets padding;
  TextEditingController controller;
  String labelText;
  String hintText;
  Function(String) validator;
  TextInputType keyboardType;

  bool maxLengthEnforced;
  int maxLength;
  int minLines;
  int maxLines;

  bool shouldFill = true;
  bool hasMaxLength = false;

  @override
  void initState() {
    super.initState();

    padding = widget.padding;
    controller = widget.controller;
    validator = widget.validator;
    labelText = widget.labelText;
    hintText = widget.hintText;
    keyboardType = widget.keyboardType;

    maxLengthEnforced = widget.maxLengthEnforced;
    maxLength = widget.maxLength;

    hasMaxLength = (maxLengthEnforced != null) && (maxLength != null);

    minLines = widget.minLines;
    maxLines = widget.maxLines;
  }

  @override
  Widget build(BuildContext context) {
    return new Padding(
      padding: padding,
      child: Focus(
        onFocusChange: (hasFocus) => setState(() {
          shouldFill = !hasFocus && controller.text.isEmpty;
        }),
        child: TextFormField(
          initialValue: null,
          controller: controller,
          validator: validator,
          maxLength: maxLength,
          maxLengthEnforced: hasMaxLength ? maxLengthEnforced : false,
          keyboardType: keyboardType,
          decoration: InputDecoration(
            labelText: labelText,
            hintText: hintText,
            alignLabelWithHint: true,
            filled: shouldFill,
            fillColor: CustomColors.createGrey,
            enabledBorder: Styles.createInputBorderEnabled,
            border: Styles.createInputBorder,
          ),
          minLines: minLines,
          maxLines: maxLines,
        ),
      ),
    );
  }

}