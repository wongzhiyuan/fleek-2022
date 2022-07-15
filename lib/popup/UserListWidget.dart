import 'package:fleek/dataclasses/User.dart';
import 'package:fleek/global/globalItems.dart';
import 'package:fleek/popup/UserPageWidget.dart';
import 'package:fleek/values/styles.dart';
import 'package:fleek/widgetClasses/CircularProfileThumb.dart';
import 'package:flutter/material.dart';

class UserListWidget extends StatelessWidget {
  final String title;
  final List<String> userUids;
  UserListWidget({this.title, this.userUids});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: Text(title),
      ),
      body: (userUids.isNotEmpty)
      ? ListView.builder(
        itemCount: userUids.length,
        itemBuilder: (BuildContext context, int index) {
          User user = usersCollection[userUids[index]];
          return ListTile(
            onTap: () => Navigator.push(context, MaterialPageRoute(
              builder: (context) => UserPageWidget(userUid: user.id,),
            )),
            leading: new CircularProfileThumb(image: user.profilePictureUri,),
            title: Text(user.displayName),
          );
        }
      )
      : Center(
        child: Text(
          "No users found.",
          style: Styles.indicator,
        ),
      ),
    );
  }

}