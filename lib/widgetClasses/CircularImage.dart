import 'package:fleek/widgetClasses/DefaultImageNetwork.dart';
import 'package:flutter/material.dart';

class CircularImage extends StatelessWidget {
  final double size;
  final String uri;

  CircularImage({this.size, this.uri});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(size/2),
      child: DefaultImageNetwork(
        image: uri,
        width: size,
        height: size,
        fit: BoxFit.cover,
      ),
    );
  }

}