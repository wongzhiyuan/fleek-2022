import 'package:fleek/values/dimens.dart';
import 'package:flutter/material.dart';

class CircularProfileThumb extends StatelessWidget {
  final String image;
  final double side = Dimens.imageSizeThumb;
  CircularProfileThumb({this.image});

  @override
  Widget build(BuildContext context) {
    return CircleAvatar(
      radius: side/2,
      backgroundImage: Image.network(
        image,
        width: side,
        height: side,
        fit: BoxFit.cover,
      ).image,
    );
  }


}