import 'package:fleek/values/colors.dart';
import 'package:flutter/material.dart';

class CircularInfo extends StatelessWidget {
  final String info;
  CircularInfo({this.info});

  @override
  Widget build(BuildContext context) {
    return new CircleAvatar(
      foregroundColor: CustomColors.colorPrimary,
      backgroundColor: CustomColors.colorPrimaryDark,
      child: Text(info),
    );
  }

}