import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fleek/assets/custom_icons_icons.dart';
import 'package:fleek/chat/ChatWidget.dart';
import 'package:fleek/dataclasses/PPost.dart';
import 'package:fleek/dataclasses/PProduct.dart';
import 'package:fleek/dataclasses/Post.dart';
import 'package:fleek/dataclasses/Product.dart';
import 'package:fleek/global/globalFunctions.dart';
import 'package:fleek/global/globalItems.dart';
import 'package:fleek/values/colors.dart';
import 'package:fleek/values/dimens.dart';
import 'package:fleek/values/strings.dart';
import 'package:fleek/values/styles.dart';
import 'package:fleek/widgetClasses/ChatDrawer.dart';
import 'package:fleek/widgetClasses/DefaultImageFile.dart';
import 'package:fleek/widgetClasses/DefaultImageNetwork.dart';
import 'package:fleek/widgetClasses/FlexibleSpaceTabBar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:parse_server_sdk/parse_server_sdk.dart';
import 'package:transparent_image/transparent_image.dart';

class LikedWidget extends StatefulWidget {
  final String title = "Liked";

  _LikedState createState() => _LikedState();
}

class _LikedState extends State<LikedWidget> {
  StreamSubscription<String> shopModifiedListener, socialModifiedListener, shopDeleteListener, socialDeleteListener;
  List<PProduct> _likedProductsList = [];
  List<PPost> _likedPostsList = [];
  
  final imageWidth = Dimens.imageSizeThumb;

  @override
  void initState() {
    super.initState();

    refreshLikedProductsList();
    refreshLikedPostsList();

    shopModifiedListener = aShopModifyId.stream.listen((id) {
      int modifyIndex = _likedProductsList.indexWhere((product) => product.id == id);
      final PProduct modifiedProduct = parseShopCollection[id];
      if (modifyIndex != -1) {
        setState(() {
          if (!modifiedProduct.likedBy.contains(currentParseUserUid)) _likedProductsList.removeAt(modifyIndex);
          else _likedProductsList[modifyIndex] = modifiedProduct;
        });
      }
    });

    shopDeleteListener = aShopDeleteId.stream.listen((id) {
      setState(() {
        _likedProductsList.removeWhere((product) => product.id == id);
      });
    });

    socialModifiedListener = aSocialModifyId.stream.listen((id) {
      int modifyIndex = _likedPostsList.indexWhere((post) {
        return post.id == id;
      });
      final PPost modifiedPost = parseSocialCollection[id];
      if (modifyIndex != -1) {
        setState(() {
          if (!modifiedPost.likedBy.contains(currentParseUserUid)) _likedPostsList.removeAt(modifyIndex);
          else _likedPostsList[modifyIndex] = modifiedPost;
        });
      }
    });

    socialDeleteListener = aSocialDeleteId.stream.listen((id) {
      setState(() {
        _likedPostsList.removeWhere((post) => post.id == id);
      });
    });
  }

  @override
  void dispose() {
    shopModifiedListener.cancel();
    shopDeleteListener.cancel();
    socialModifiedListener.cancel();
    socialDeleteListener.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          actions: <Widget>[
            Builder(
              builder: (BuildContext context) {
                return IconButton(
                  icon: const Icon(Icons.chat),
                  onPressed: () => slidePageTransition(context, new ChatDrawer(), RIGHT),
                  tooltip: MaterialLocalizations.of(context).openAppDrawerTooltip,
                  color: CustomColors.colorPrimaryDark,
                );
              },
            ),
          ],
          backgroundColor: CustomColors.colorPrimary,
          flexibleSpace: FlexibleSpaceTabBar(
            tabs: <Widget>[
              Text(Strings.tabLabelLikedProducts),
              Text(Strings.tabLabelLikedPosts),
            ],
          ),
        ),
        body: TabBarView(
          children: <Widget>[
            productTab(),
            postTab(),
          ],
        ),
      ),
    );
  }

  void refreshLikedProductsList() {
    _likedProductsList.clear();
    currentUserCollection.likedProducts.forEach((id) {
      setState(() {
        _likedProductsList.add(parseShopCollection[id]);
      });
    });
  }

  void refreshLikedPostsList() {
    _likedPostsList.clear();
    currentUserCollection.likedPosts.forEach((id) {
      setState(() {
        _likedPostsList.add(parseSocialCollection[id]);
      });
    });
  }

  Widget productTab() {
    var displayList = _likedProductsList;
    if (displayList.length == 0) {
      return centeredEmptyWidget("You haven't liked anything yet.");
    }

    return ListView.builder(
      shrinkWrap: true,
      itemCount: displayList.length,
      itemBuilder: (BuildContext context, int index) {
        PProduct product = displayList[index];

        return InkWell(
          onTap: () => Navigator.push(context, MaterialPageRoute(
            builder: (context) => ChatWidget(
              product: product,
              chatUid: product.seller,
            ),
          )),
          child: Padding(
            padding: EdgeInsets.all(Dimens.paddingLikedListTile),
            child: ListTile(
              leading: CircleAvatar(
                radius: imageWidth/2,
                backgroundImage: Image.file(
                  product.images[0].file,
                  width: imageWidth,
                  height: imageWidth,
                  fit: BoxFit.cover,
                ).image,
              ),
              title: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(product.title, style: Styles.createFormHeader,),
                  Text(takenDisplayNames[product.seller]),
                ],
              ),
              trailing: soldReservedIndicator(product),
            ),
          ),
        );
      },
    );
  }
  
  Widget soldReservedIndicator(PProduct product) {
    if (product.isSold) {
      return Text("SOLD");
    }
    else if (product.isReserved) {
      return Text("RESERVED");
    }
    
    return null;
  }
  Widget postTab() {
    var displayList = _likedPostsList;
    if (displayList.length == 0) {
      return centeredEmptyWidget("You haven't liked anything yet.");
    }

    final double gridSpacing = Dimens.paddingStaggeredGrid;
    final double postImageWidth = (getScreenWidth(context) - 3 * gridSpacing) / 2;

    return Padding(
      padding: EdgeInsets.all(gridSpacing),
      child: StaggeredGridView.countBuilder(
        crossAxisCount: 4,
        mainAxisSpacing: gridSpacing,
        crossAxisSpacing: gridSpacing,
        itemCount: displayList.length,
        itemBuilder: (BuildContext context, int index) {
          PPost post = displayList[index];
          final padding = EdgeInsets.all(Dimens.paddingStaggeredGridLikeBar);

          return Container(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.start,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: <Widget>[
                ClipRRect(
                  child: DefaultImageNetwork(
                    image: post.image.url,
                    width: postImageWidth,
                    fit: BoxFit.contain,
                  ),
                  borderRadius: BorderRadius.circular(8.0),
                ),
                Row(
                  mainAxisSize: MainAxisSize.max,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: <Widget>[
                    Column(
                      mainAxisSize: MainAxisSize.min,
                      mainAxisAlignment: MainAxisAlignment.start,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Padding(
                          padding: padding,
                          child: Align(
                            alignment: Alignment.centerLeft,
                            child: Text(
                              post.title,
                              style: Styles.listHeader,
                            ),
                          ),
                        ),
                        Padding(
                          padding: padding,
                          child: Align(
                            alignment: Alignment.centerLeft,
                            child: Text(
                              formatTimestamp(post.timestamp),
                            ),
                          ),
                        ),
                      ],
                    ),

                    Padding(
                      padding: padding,
                      child: likeIndicator(post, index),
                    ),
                  ],
                ),

              ],
            ),
          );
        },
        staggeredTileBuilder: (int index) => StaggeredTile.fit(2),
      ),
    );
  }

  Widget likeIndicator(PPost post, int index) {
    bool isLikedByUser = post.likedBy.contains(currentParseUserUid);
    final String setType = isLikedByUser ? SET_REMOVE : SET_ADD_UNIQUE;
    void onClick() async {
      var postObj = objFromMap(new ParseObject(OBJECT_SOCIAL), {
        SOCIAL_LIKED_BY : currentParseUserUid
      }, setType: setType);

      await postObj.save().then(parseSaveCallback);

      var result = await getUserDataObject(currentParseUserUid);
      if (result.success) {
        var dataObj = objFromMap(result.object, {
          USER_LIKED_POSTS : post.id
        }, setType: setType);
        await dataObj.save().then(parseSaveCallback);
      }
    }

    return InkWell(
      onTap: onClick,
      child: isLikedByUser
          ? Icon(CustomIcons.heart)
          : Icon(CustomIcons.heart_empty),
    );
  }

}