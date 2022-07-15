import 'dart:typed_data';

import 'package:fleek/values/colors.dart';
import 'package:flutter/material.dart';
import 'package:transparent_image/transparent_image.dart';

class DefaultImageNetwork extends StatelessWidget {
  final String image;
  final double width;
  final double height;
  final BoxFit fit;
  final Uint8List placeholder;
  final ColorFilter colorFilter;

  DefaultImageNetwork({
    this.placeholder,
    this.image,
    this.width,
    this.height,
    this.fit,
    this.colorFilter,
  });

  final Uint8List defaultPlaceholder = kTransparentImage;
  final ColorFilter defaultColorFilter = ColorFilter.mode(CustomColors.tint.withOpacity(0), BlendMode.color);
  @override
  Widget build(BuildContext context) {
    Uint8List holder = placeholder == null ? defaultPlaceholder : placeholder;
    ColorFilter filter = (colorFilter == null) ? defaultColorFilter : colorFilter;
    return ColorFiltered(
      colorFilter: filter,
      child: FadeInImage.memoryNetwork(
        placeholder: holder,
        image: image,
        width: width,
        height: height,
        fit: fit,
      ),
    );
  }

}