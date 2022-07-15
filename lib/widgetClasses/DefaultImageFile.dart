import 'dart:io';
import 'dart:typed_data';

import 'package:fleek/values/colors.dart';
import 'package:flutter/material.dart';
import 'package:transparent_image/transparent_image.dart';

class DefaultImageFile extends StatelessWidget {
  final File image;
  final double width;
  final double height;
  final BoxFit fit;
  final Uint8List placeholder;
  final ColorFilter colorFilter;

  DefaultImageFile({
    this.placeholder,
    this.image,
    this.width,
    this.height,
    this.fit,
    this.colorFilter,
  });

  final Uint8List defaultPlaceholder = kTransparentImage;
  final ColorFilter defaultColorFilter = ColorFilter.mode(CustomColors.tint, BlendMode.color);
  @override
  Widget build(BuildContext context) {
    Uint8List holder = placeholder == null ? defaultPlaceholder : placeholder;
    ColorFilter filter = (colorFilter == null) ? defaultColorFilter : colorFilter;
    return ColorFiltered(
      colorFilter: filter,
      child: FadeInImage(
        placeholder: MemoryImage(holder),
        image: Image.file(image).image,
        width: width,
        height: height,
        fit: fit,
      ),
    );
  }

}