import 'package:fleek/dataclasses/Review.dart';
import 'package:fleek/dataclasses/User.dart';
import 'package:fleek/global/globalItems.dart';
import 'package:fleek/values/dimens.dart';
import 'package:fleek/values/styles.dart';
import 'package:flutter/material.dart';

class ReviewDisplayWidget extends StatelessWidget {
  final Map<String, Review> reviewMap;
  final String userUid;
  ReviewDisplayWidget({this.userUid, this.reviewMap});

  @override
  Widget build(BuildContext context) {
    final List<String> keys = new List<String>.from(reviewMap.keys);
    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: Text("Reviews of ${takenDisplayNames[userUid]}"),
      ),
      body: reviewMap.isNotEmpty
        ? ListView.builder(
          itemCount: keys.length,
          itemBuilder: (BuildContext context, int index) {
            final String userUid = keys[index];
            final User user = usersCollection[userUid];
            final double profileImageWidth = Dimens.imageSizeThumb;
            final Review review = reviewMap[userUid];

            Widget leading = new CircleAvatar(
              radius: profileImageWidth/2,
              backgroundImage: Image.network(
                user.profilePictureUri,
                width: profileImageWidth,
                height: profileImageWidth,
                fit: BoxFit.cover,
              ).image,
            );
            Widget title = new Text(user.displayName);
            Widget trailing = new Row(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: <Widget>[
                Text(review.rating.toString()),
                Padding(
                  padding: EdgeInsets.only(left: Dimens.paddingRatingDisplayStar),
                  child: Icon(
                    Icons.star,
                    color: Colors.amber,
                  ),
                ),
              ],
            );

            return (review.desc.isNotEmpty)
                ? ExpansionTile(
              leading: leading,
              title: title,
              trailing: trailing,
              children: <Widget>[
                ListTile(
                  title: Text(review.desc),
                ),
              ],
            )
                : ListTile(
              leading: leading,
              title: title,
              trailing: trailing,
            );
          }
      )
      : Center(
        child: Text(
          "There are no reviews for this user yet.",
          style: Styles.indicator,
        ),
      ),
    );
  }

}