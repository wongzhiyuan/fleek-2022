import 'package:fleek/global/globalFunctions.dart';
import 'package:fleek/values/dimens.dart';
import 'package:fleek/values/styles.dart';
import 'package:flutter/material.dart';

class FloatingNavBar extends StatefulWidget {
  final Function(int) onTap;
  final List<BottomNavigationBarItem> items;
  FloatingNavBar({
    this.onTap,
    this.items,
  });

  _FloatingNavBarState createState() => _FloatingNavBarState();
}

class _FloatingNavBarState extends State<FloatingNavBar> {
  final double offset = Dimens.offsetNavBar;
  static final double height = Dimens.heightNavBar;
  double iconSize = height/3;
  int _currentIndex = 0;
  final borderRadius = BorderRadius.circular(height/2);

  @override
  void initState() {
    super.initState();
  }
  @override
  Widget build(BuildContext context) {
    return new Container(
      width: getScreenWidth(context),
      height: height + offset,
      alignment: Alignment.topCenter,
      color: Colors.transparent,
      child: Stack(
        children: <Widget>[
          Positioned(
            bottom: offset,
            left: offset,
            right: offset,
            child: Material(
              elevation: 5.0,
              borderRadius: borderRadius,
              child: Container(
                height: height,
                alignment: Alignment.center,
                foregroundDecoration: BoxDecoration(
                  borderRadius: borderRadius,
                ),
                child: ClipRRect(
                  borderRadius: borderRadius,
                  child: BottomNavigationBar(
                    showSelectedLabels: false,
                    showUnselectedLabels: false,
                    type: BottomNavigationBarType.fixed,
                    iconSize: iconSize,
                    selectedIconTheme: IconThemeData(
                      size: iconSize * 1.5,
                    ),
                    currentIndex: _currentIndex,
                    onTap: (index) {
                      widget.onTap(index);
                      setState(() => _currentIndex = index);
                    },
                    items: widget.items,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

}