import 'dart:ffi';
import 'dart:math';

import 'package:flutter/material.dart';

class PullableTray extends StatefulWidget {
  final Alignment alignment;
  final Widget backgroundImage;
  final Widget preview;
  final Widget child;
  final Color color;
  final double padding;
  final double height;
  final double tabRadius;

  PullableTray({
    this.tabRadius,
    this.padding,
    this.height,
    this.color,
    this.backgroundImage,
    this.alignment,
    this.preview,
    this.child,
  });

  _PullableTrayState createState() => _PullableTrayState();
}

class _PullableTrayState extends State<PullableTray> with TickerProviderStateMixin {
  double padding;
  double height;
  Alignment alignment;
  Color color;
  Widget image;
  Widget preview;
  Widget child;
  bool isExpanded = false;
  bool isRightAligned = false;
  String openChar, closeChar;

  double tabRadius;
  AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = new AnimationController(vsync: this, duration: const Duration(milliseconds: 200));
    _controller.reset();

    height = widget.height;
    tabRadius = widget.tabRadius;
    padding = widget.padding;
    color = widget.color;
    image = widget.backgroundImage;
    alignment = widget.alignment;
    preview = widget.preview;
    child = widget.child;

    isRightAligned = alignment == Alignment.centerRight;

    alignment ??= Alignment.centerRight;
    color ??= Colors.white;
    tabRadius ??= 30;

    openChar = isRightAligned ? '<' : '>';
    closeChar = isRightAligned ? '>' : '<';
  }
  @override
  Widget build(BuildContext context) {
    final paddingAround = EdgeInsets.all(padding);

    void moveTray() {
      setState(() => isExpanded = !isExpanded);
      (isExpanded) ? _controller.forward() : _controller.reverse();
    }

    List<Widget> rowChildren = <Widget>[
      SizedBox(
        width: tabRadius,
        height: tabRadius * 2,
        child: GestureDetector(
          onTap: moveTray,
          child: Center(child: Text(isExpanded ? closeChar : openChar),),
        ),
      ),
      Padding(
        padding: paddingAround,
        child: preview,
      ),
      SizeTransition(
        axis: Axis.horizontal,
        sizeFactor: CurvedAnimation(
          curve: Curves.easeInOut,
          parent: _controller,
        ),
        child: Padding(
          padding: paddingAround,
          child: child,
        ),
      ),
    ];

    return Stack(
      children: <Widget>[
        image,
        GestureDetector(
          onHorizontalDragEnd: (DragEndDetails details) {
            bool closeTrigger, openTrigger;

            if (isRightAligned) {
              closeTrigger = details.primaryVelocity > 0;
              openTrigger = details.primaryVelocity < 0;
            }
            else {
              closeTrigger = details.primaryVelocity < 0;
              openTrigger = details.primaryVelocity > 0;
            }
            if ((openTrigger && !isExpanded) ||
                (closeTrigger && isExpanded)) moveTray();
          },
          child: Container(
            height: height,
            alignment: alignment,
            padding: isRightAligned
                ? EdgeInsets.fromLTRB(padding, padding, 0, padding)
                : EdgeInsets.fromLTRB(0, padding, padding, padding),
            child: ClipPath(
                clipper: TrayClipper(
                  isRightAligned: isRightAligned,
                  tabRadius: tabRadius,
                  borderRadius: 30,
                ),
                child: Container(
                  color: color,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: isRightAligned ? rowChildren : rowChildren.reversed.toList(),
                  ),
                )
            ),
          ),
        ),
      ],
    );
  }
}

class TrayClipper extends CustomClipper<Path> {
  final double defaultSize = 20;
  final double defaultRadius = 20;
  final bool isRightAligned;
  final double tabRadius;
  final double borderRadius;
  TrayClipper({this.tabRadius, this.borderRadius, this.isRightAligned});

  @override
  Path getClip(Size size) {
    final w = size.width;
    final h = size.height;

    final isRight = (isRightAligned == null) ? false : isRightAligned;

    final tR = (tabRadius != null) ? tabRadius : defaultSize;
    final r = (borderRadius != null) ? borderRadius : defaultRadius;

    final intH = h / 2 - r - tR;
    final circularR = Radius.circular(r);

    Path rightAligned = Path()..moveTo(r + tR, 0)
        ..lineTo(w, 0)
        ..lineTo(w, h)
        ..lineTo(r + tR, h)
        ..arcToPoint(Offset(tR, h - r), radius: circularR)
        ..lineTo(tR, h - r - intH)
        ..arcToPoint(Offset(tR, r + intH), radius: Radius.circular(tR))
        ..lineTo(tR, r)
        ..arcToPoint(Offset(r + tR, 0), radius: circularR)
        ..close();

    Path leftAligned = Path()..lineTo(w - r - tR, 0)
      ..arcToPoint(Offset(w - tR, r), radius: circularR)
      ..lineTo(w - tR, r + intH)
      ..arcToPoint(Offset(w - tR, h - intH - r), radius: circularR)
      ..lineTo(w - tR, h - r)
      ..arcToPoint(Offset(w - tR - r, h), radius: circularR)
      ..lineTo(0, h)
      ..lineTo(0, 0)
      ..close();
    return isRight ? rightAligned : leftAligned;
  }

  @override
  bool shouldReclip(CustomClipper<Path> oldClipper) {
    return false;
  }

}
