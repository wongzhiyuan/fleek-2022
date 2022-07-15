import 'dart:async';
import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fleek/assets/custom_icons_icons.dart';
import 'package:fleek/dataclasses/DisplayItem.dart';
import 'package:fleek/dataclasses/PPost.dart';
import 'package:fleek/dataclasses/PProduct.dart';
import 'package:fleek/dataclasses/Post.dart';
import 'package:fleek/dataclasses/Product.dart';
import 'package:fleek/dataclasses/User.dart';
import 'package:fleek/global/globalFunctions.dart';
import 'package:fleek/global/globalItems.dart';
import 'package:fleek/popup/UserPageWidget.dart';
import 'package:fleek/values/colors.dart';
import 'package:fleek/values/dimens.dart';
import 'package:fleek/values/styles.dart';
import 'package:fleek/widgetClasses/DefaultImageFile.dart';
import 'package:fleek/widgetClasses/DefaultImageNetwork.dart';
import 'package:flutter/material.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:flutter_swiper/flutter_swiper.dart';
import 'package:parse_server_sdk/parse_server_sdk.dart';

class CommunityWidget extends StatefulWidget {
  final String title = "Community";

  _CommunityState createState() => _CommunityState();
}

class _CommunityState extends State<CommunityWidget> {
  List<String> currentFollowingUsers = [];
  List<DisplayItem> _followingDisplayList = [];
  List<DisplayItem> _forYouDisplayList = [];

  StreamSubscription productUpdateListener, postUpdateListener, userListener;

  @override
  void initState() {
    super.initState();

    setState(() {
      currentFollowingUsers = currentUserCollection.following;
      _forYouDisplayList = populateForYouList();
      _followingDisplayList = populateFollowingList();
    });

    postUpdateListener = aSocialModifyId.stream.listen((id) {
      for (int i = 0; i < _forYouDisplayList.length; i++) {
        DisplayItem item = DisplayItem().fromPost(parseSocialCollection[id]);
        if (_forYouDisplayList[i].id == id) {
          setState(() {
            _forYouDisplayList[i] = item;
          });
        }

        if (_followingDisplayList[i].id == id) {
          setState(() {
            _followingDisplayList[i] = item;
          });
        }
      }
    });

    productUpdateListener = aShopModifyId.stream.listen((id) {
      for (int i = 0; i < _forYouDisplayList.length; i++) {
        DisplayItem item = DisplayItem().fromProduct(parseShopCollection[id]);
        if (_forYouDisplayList[i].id == id) {
          setState(() {
            _forYouDisplayList[i] = item;
          });
        }

        if (_followingDisplayList[i].id == id) {
          setState(() {
            _followingDisplayList[i] = item;
          });
        }
      }
    });

    userListener = aUserCollectionModified.stream.listen((event) {
      setState(() {
        currentFollowingUsers = currentUserCollection.following;
      });
    });
  }

  @override
  void dispose() {
    productUpdateListener.cancel();
    postUpdateListener.cancel();
    userListener.cancel();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        body: ConstrainedBox(
          constraints: BoxConstraints.expand(),
          child: Stack(
            children: <Widget>[
              TabBarView(
                children: <Widget>[
                  followingWidget(),
                  forYouWidget(),
                ],
              ),
              Align(
                alignment: Alignment.topCenter,
                child: Container(
                  padding: EdgeInsets.only(top: 20),
                  height: 200,
                    width: 250,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Expanded(
                          child: TabBar(
                            indicatorSize: TabBarIndicatorSize.label,
                            labelColor: CustomColors.colorPrimary,
                            indicatorColor: CustomColors.colorPrimary,
                            tabs: <Widget>[
                              Tab(
                                child: Text(
                                  "Following",
                                  style: Styles.glowingTabLabel,
                                ),
                              ),
                              Tab(
                                child: Text(
                                  "For You",
                                  style: Styles.glowingTabLabel,
                                ),
                              ),
                            ],
                          ),
                        ),

                      ],
                    ),
                  ),
                ),
            ],
          ),
        ),

      ),
    );
  }

  Widget forYouWidget() {
    final double gridSpacing = Dimens.paddingStaggeredGrid;
    final double imageWidth = (getScreenWidth(context) - 3 * gridSpacing) / 2;

    if (_forYouDisplayList.length == 1 && _forYouDisplayList[0].isEmpty) {
      return centeredEmptyWidget("There aren't any posts available right now. Please try again later.");
    }
    return Padding(
      padding: EdgeInsets.all(gridSpacing),
      child: StaggeredGridView.countBuilder(
        crossAxisCount: 4,
        mainAxisSpacing: gridSpacing,
        crossAxisSpacing: gridSpacing,

        itemCount: _forYouDisplayList.length,
        itemBuilder: (BuildContext context, int index) {
          DisplayItem item = _forYouDisplayList[index];
          final bool isProduct = item.isProduct;
          final padding = EdgeInsets.all(Dimens.paddingStaggeredGridLikeBar);
          return Container(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.start,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: <Widget>[
                ClipRRect(
                  child: DefaultImageNetwork(
                    image: item.coverImage.url,
                    width: imageWidth,
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
                              item.title,
                              style: Styles.listHeader,
                            ),
                          ),
                        ),
                        Padding(
                          padding: padding,
                          child: Align(
                            alignment: Alignment.centerLeft,
                            child: Text(
                              formatTimestamp(item.timestamp),
                            ),
                          ),
                        ),
                      ],
                    ),

                    Column(
                      mainAxisSize: MainAxisSize.min,
                      mainAxisAlignment: MainAxisAlignment.start,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: <Widget>[
                        Padding(
                          padding: padding,
                          child: likeIndicator(item, isProduct, index),
                        ),
                        Padding(
                          padding: padding,
                          child: Text(
                            isProduct ? item.price.toString() : "",
                          ),
                        ),
                      ],
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

  Widget followingWidget() {
    final spacing = Dimens.paddingStaggeredGrid;
    final imageWidth = getScreenWidth(context) - 2*spacing;
    final listLength = _followingDisplayList.length;

    if (listLength == 1 && _followingDisplayList[0].isEmpty) {
      String emptyText = currentUserCollection.following.length > 0
          ? "There currently aren't any posts from the users you are following. Please try again later."
          : "You haven't followed anyone yet.";

      return centeredEmptyWidget(emptyText);
    }

    return Padding(
      padding: EdgeInsets.all(spacing),
      child: ListView.builder(
        shrinkWrap: true,
        itemCount: listLength,
        itemBuilder: (BuildContext context, int index) {
          final padding = EdgeInsets.all(Dimens.paddingStaggeredGridLikeBar);

          var item = _followingDisplayList[index];

          List<ParseFile> imageList = item.images;

          bool isProduct = item.isProduct;
          bool shouldAutoPlay = imageList.length > 1;

          return Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: <Widget>[
              Container(
                height: 450,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8.0),
                  child: Swiper(
                    itemCount: imageList.length,
                    itemBuilder: (BuildContext context, int i) {
                      return DefaultImageNetwork(
                        image: imageList[i].url,
                        width: imageWidth,
                        fit: BoxFit.cover,
                      );
                    },
                    pagination: shouldAutoPlay ? new SwiperPagination() : null,
                    autoplay: shouldAutoPlay,
                    physics: shouldAutoPlay ? new ScrollPhysics() : new NeverScrollableScrollPhysics(),
                  ),
                ),
              
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
                            item.title,
                            style: Styles.listHeader,
                          ),
                        ),
                      ),
                      Padding(
                        padding: padding,
                        child: Align(
                          alignment: Alignment.centerLeft,
                          child: InkWell(
                            onTap: () => Navigator.push(context, MaterialPageRoute(
                              builder: (context) => UserPageWidget(userUid: item.author,),
                            )),
                            child: RichText(
                              text: new TextSpan(
                                style: new TextStyle(
                                  color: Colors.black,
                                ),
                                children: <TextSpan>[
                                  TextSpan(
                                    text: "@${takenDisplayNames[item.author].toUpperCase()}",
                                    style: new TextStyle(fontWeight: FontWeight.bold),
                                  ),
                                  TextSpan(
                                    text: " POSTED ${formatTimestamp(item.timestamp)}",
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),

                  Column(
                    mainAxisSize: MainAxisSize.min,
                    mainAxisAlignment: MainAxisAlignment.start,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: <Widget>[
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        mainAxisAlignment: MainAxisAlignment.end,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: <Widget>[
                          Padding(
                            padding: padding,
                            child: Text(item.likedBy.length.toString()),
                          ),
                          Padding(
                            padding: padding,
                            child: likeIndicator(item, isProduct, index),
                          ),
                        ],
                      ),

                      Padding(
                        padding: padding,
                        child: Text(
                          isProduct ? item.price.toString() : "",
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              Container(
                alignment: Alignment.centerLeft,
                padding: padding,
                child: Text(
                  isProduct ? item.description : "",
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget likeIndicator(DisplayItem item, bool isProduct, int index) {
    bool isLikedByUser = item.likedBy.contains(currentParseUserUid);
    void onClick() async {
      String recentStyle = item.styles.isEmpty
          ? currentParseUserCollection.mostRecentStyle
          : item.styles[Random().nextInt(item.styles.length - 1)];

      var object = new ParseObject(
          (isProduct) ? OBJECT_SHOP : OBJECT_SOCIAL
      )..objectId = item.id;

      object = objFromMap(object, {
          ((isProduct) ? SHOP_LIKED_BY_LIST : SOCIAL_LIKED_BY) : currentParseUserUid
        },
        setType: isLikedByUser ? SET_REMOVE : SET_ADD_UNIQUE
      );

      await object.save().then(parseSaveCallback);

      var result = await getUserDataObject(currentParseUserUid);
      if (result.success) {
        var dataObj = objFromMap(
          objFromMap(result.object,
            {
              ((isProduct) ? USER_LIKED_PRODUCTS : USER_LIKED_POSTS) : item.id
            },
            setType: isLikedByUser ? SET_REMOVE : SET_ADD_UNIQUE,
          ),
          {
            USER_MOST_RECENT_STYLE : recentStyle,
            USER_MOST_RECENT_TYPE : item.type,
          },
        );

        await dataObj.save().then(parseSaveCallback);
      }

      /*
      var updateValue;
      var updateId;

      if (isLikedByUser) {
        updateValue = FieldValue.arrayRemove([currentUserUid]);
        updateId = FieldValue.arrayRemove([item.id]);
      }
      else {
        updateValue = FieldValue.arrayUnion([currentUserUid]);
        updateId = FieldValue.arrayUnion([item.id]);
      }

      if (isProduct) {
        shopRef.document(item.id).updateData({
          SHOP_LIKED_BY_LIST : updateValue,
        }).then((value) {
          userCollectionRef.document(currentUserUid).updateData({
            USER_LIKED_PRODUCTS : updateId,
            USER_MOST_RECENT_TYPE : item.type,
            USER_MOST_RECENT_STYLE : recentStyle,
          });
        });
      }
      else {
        socialRef.document(item.id).updateData({
          SOCIAL_LIKED_BY : updateValue,
        }).then((value) {
          userCollectionRef.document(currentUserUid).updateData({
            USER_LIKED_POSTS : updateId,
            USER_MOST_RECENT_TYPE : item.type,
            USER_MOST_RECENT_STYLE : recentStyle,
          });
        });
      }
       */
    }

    return InkWell(
      onTap: onClick,
      child: isLikedByUser
      ? Icon(CustomIcons.heart)
      : Icon(CustomIcons.heart_empty),
    );
  }

  List<DisplayItem> populateForYouList() {
    List<PProduct> recommendedProductList = getRecommendedProductList(getRecommendedProductMap(currentFilters, [], ""));
    List<PPost> recommendedPostList = getRecommendedPostList("", "");

    recommendedProductList.removeWhere((product) => currentFollowingUsers.contains(product.seller));
    recommendedPostList.removeWhere((post) => currentFollowingUsers.contains(post.author));

    recommendedProductList.shuffle();

    return balanceLists(recommendedProductList, recommendedPostList);
  }

  List<DisplayItem> populateFollowingList() {
    List<PProduct> followingProducts = [];
    List<PPost> followingPosts = [];
    
    for (String userUid in currentFollowingUsers) {
      User user = usersCollection.containsKey(userUid) ? usersCollection[userUid] : null;

      if (user != null) {
        user.selling.forEach((id) => followingProducts.add(parseShopCollection[id]));
        user.posted.forEach((id) => followingPosts.add(parseSocialCollection[id]));
      }
      else {
        updateParseUserData(currentParseUserUid, {
          USER_FOLLOWING : userUid
        }, setType: SET_REMOVE);
      }
    }

    followingProducts.shuffle();

    List<DisplayItem> returnList = balanceLists(followingProducts, followingPosts);
    returnList.sort(communityTimeComparator);
    return returnList;
  }
  
  List<DisplayItem> balanceLists(List<PProduct> productList, List<PPost> postList) {
    List<DisplayItem> returnList = [];
    
    int productLimit = productList.length;
    int postLimit = postList.length;
    
    int productIndex = 0;
    int postIndex = 0;

    Map<String, int> ratio = {
      'post' : 1,
      'product' : 1,
    };

    while (postIndex < postLimit) {
      for (int i = 0; i < ratio['post']; i++) {
        if (postIndex < postLimit) {
          PPost post = postList[postIndex];
          returnList.add(DisplayItem().fromPost(post));
          postIndex++;
        }
        else break;
      }

      for (int j = 0; j < ratio['product']; j++) {
        if (productIndex < productLimit) {
          PProduct product = productList[productIndex];
          returnList.add(DisplayItem().fromProduct(product));
          productIndex++;
        }
        else break;
      }
    }

    if (returnList.length == 0) {
      returnList.add(DisplayItem(isEmpty: true));
    }
    
    return returnList;
  }
}