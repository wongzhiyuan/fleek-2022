import 'package:fleek/global/globalFunctions.dart';
import 'package:fleek/values/colors.dart';
import 'package:fleek/values/strings.dart';
import 'package:flutter/material.dart';

class FlexibleSpaceTabBar extends StatelessWidget {
  final List<Widget> tabs;
  FlexibleSpaceTabBar({this.tabs});

  @override
  Widget build(BuildContext context) {
    final tabPaddingV = kToolbarHeight / 8;
    final tabPaddingH = getScreenWidth(context) / 4;

    return new Container(
      alignment: Alignment.center,
      padding: EdgeInsets.symmetric(horizontal: tabPaddingH, vertical: tabPaddingV),
      child: ConstrainedBox(
        constraints: BoxConstraints.expand(),
        child: TabBar(
          unselectedLabelColor: CustomColors.colorPrimaryDark,
          indicatorSize: TabBarIndicatorSize.tab,
          indicator: BoxDecoration(
            borderRadius: BorderRadius.circular(kToolbarHeight / 2 - tabPaddingV),
            color: CustomColors.colorTheme,
          ),
          labelColor: CustomColors.colorPrimary,
          tabs: tabs,
        ),
      ),
    );
  }

}