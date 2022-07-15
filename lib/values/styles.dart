import 'package:fleek/values/FontSettings.dart';
import 'package:fleek/values/colors.dart';
import 'package:fleek/values/shadows.dart';
import 'package:flutter/material.dart';

abstract class Styles {
  static const TextStyle signInBanner = TextStyle(

    color: CustomColors.colorPrimary,
    fontSize: 50,
    fontWeight: FontWeight.bold,
    fontFamily: FONT_GNUOLANE,
    shadows: [Shadows.main],
  );

  static const TextStyle discoverBanner = TextStyle(
    color: CustomColors.colorPrimary,
    fontSize: 30,
    fontWeight: FontWeight.w900,
    fontFamily: FONT_EXPRESSWAY,
    shadows: [Shadows.main],
  );
  static const TextStyle listHeader = TextStyle(
    fontSize: 25,
    fontFamily: FontSettings.headerFamily,
  );

  static const TextStyle discoverChipText = TextStyle(
    fontSize: 15,
    color: CustomColors.chipText,
    height: 1.0,
  );

  static const TextStyle createFormHeader = TextStyle(
    fontSize: 18,
    fontFamily: FontSettings.bodyFamilyBold,
  );

  static const TextStyle detailsHeader = TextStyle(
    fontSize: 15,
    fontFamily: FontSettings.bodyFamilyBold,
  );

  static TextStyle discoverFilterTypesListText(bool isSelected) => TextStyle(
    fontSize: 30,
    color: isSelected ? CustomColors.colorPrimaryDark : CustomColors.colorGreyedOut,
    fontFamily: FontSettings.bodyFamilyBold,
    height: 1.0,
  );

  static const TextStyle smallLabel = TextStyle(
    fontSize: 13,
    fontWeight: FontWeight.bold,
    height: 1.0,
  );

  static const TextStyle glowingTabLabel = TextStyle(
    fontSize: 15,
    shadows: <Shadow>[
      Shadow(
        offset: Offset(0,0),
        color: CustomColors.colorPrimaryDark,
        blurRadius: 3.0,
      ),
    ],
  );

  static const TextStyle seeAllButton = TextStyle(
    fontSize: 10,
    fontStyle: FontStyle.italic,
  );
  static const TextStyle submitButton = TextStyle(
    fontSize: 12,
    color: CustomColors.colorPrimaryDark,
    fontWeight: FontWeight.bold,
  );

  static const TextStyle prompt = TextStyle(
    fontSize: 10,
    color: CustomColors.colorPrimary,
    fontStyle: FontStyle.italic,
  );

  static const TextStyle indicator = TextStyle(
    fontSize: 10,
    color: CustomColors.colorGreyedOut,
    fontStyle: FontStyle.italic,
  );

  static const TextStyle details = TextStyle(
    fontSize: 10,
    color: CustomColors.colorGreyedOut,
  );

  static const TextStyle bigCounter = TextStyle(
    fontSize: 25,
    color: CustomColors.colorPrimaryDark,
    fontWeight: FontWeight.bold,
  );

  static const TextStyle bigCounterLabel = TextStyle(
    fontSize: 10,
    color: CustomColors.colorPrimaryDark,
  );

  static const TextStyle chatMessage = TextStyle(
    fontSize: 16,
    color: CustomColors.colorPrimaryDark,
  );

  static const TextStyle timestamp = TextStyle(
    fontSize: 8,
    color: CustomColors.colorGreyedOut,
  );

  static RoundedRectangleBorder roundedButtonShape = RoundedRectangleBorder(
    side: BorderSide(color: CustomColors.colorPrimary, width: 1.0),
    borderRadius: BorderRadius.circular(20),
  );

  static InputBorder createInputBorderEnabled = OutlineInputBorder(
    borderSide: BorderSide(color: CustomColors.createGrey,),
    borderRadius: BorderRadius.circular(20),
  );

  static InputBorder createInputBorder = OutlineInputBorder(
    borderSide: BorderSide(color: CustomColors.createGrey,),
    borderRadius: BorderRadius.circular(20),
  );

  static InputBorder signInInputBorder = UnderlineInputBorder(
    borderSide: BorderSide(color: Colors.transparent,),
    borderRadius: BorderRadius.circular(20),
  );

  static InputBorder inputBorder = OutlineInputBorder(
      borderSide: BorderSide(color: CustomColors.colorPrimaryDark, width: 5.0),
      borderRadius: BorderRadius.circular(10)
  );

  static InputBorder chatInputBorder = OutlineInputBorder(
      borderSide: BorderSide(color: CustomColors.colorGreyedOut, width: 5.0),
      borderRadius: BorderRadius.circular(25)
  );
}