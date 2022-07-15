import 'package:fleek/global/globalItems.dart';
import 'package:fleek/main/ProfileWidget.dart';
import 'package:flutter/material.dart';

class UserPageWidget extends StatefulWidget {
  final String userUid;

  UserPageWidget({this.userUid});

  final title = "User Page";
  _UserPageState createState() => _UserPageState();
}

class _UserPageState extends State<UserPageWidget> {
  String userUid, userName;

  @override
  void initState() {
    super.initState();

    userUid = widget.userUid;
    userName = takenDisplayNames[userUid];
  }

  @override
  void dispose() {
    // TODO: implement dispose
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(userName),
      ),
      body: ProfileWidget(userUid: userUid,),
    );
  }

}