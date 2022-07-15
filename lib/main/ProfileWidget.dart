import 'dart:async';
import 'dart:math';
import 'dart:core';

import 'package:fleek/assets/custom_icons_icons.dart';
import 'package:fleek/dataclasses/DisplayItem.dart';
import 'package:fleek/dataclasses/PUser.dart';
import 'package:fleek/dataclasses/Review.dart';
import 'package:fleek/global/globalFunctions.dart';
import 'package:fleek/global/globalItems.dart';
import 'package:fleek/popup/RatingDisplayWidget.dart';
import 'package:fleek/popup/UpdateProfileWidget.dart';
import 'package:fleek/popup/UserListWidget.dart';
import 'package:fleek/values/colors.dart';
import 'package:fleek/values/animInfo.dart';
import 'package:fleek/values/dimens.dart';
import 'package:fleek/values/strings.dart';
import 'package:fleek/values/styles.dart';
import 'package:fleek/widgetClasses/DefaultImageNetwork.dart';
import 'package:fleek/widgetClasses/PullableTray.dart';
import 'package:fleek/widgetClasses/SettingsDrawer.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';

class ProfileWidget extends StatefulWidget {
  final String title = "Your Profile";

  final String userUid;

  ProfileWidget({this.userUid});

  _ProfileState createState() => _ProfileState();
}

class _ProfileState extends State<ProfileWidget> with SingleTickerProviderStateMixin {
  String userUid;
  PUser userCollection;
  bool isCurrentUser = false;

  double _rating = 0;
  Map<String, Review> _reviewMap = {};

  static const String TITLE_FOLLOWING = 'is following';
  static const String TITLE_FOLLOWERS = 'is followed by';
  double _followingCount = 0;
  double _followersCount = 0;
  static final double paddingProfile = Dimens.paddingProfileAround;
  static final imageWidth = Dimens.imageSizeMedium;

  double _expandedHeight = 5 * paddingProfile + imageWidth + 25*6;

  StreamSubscription modifiedListener;

  bool _reachedTop = false;
  TabController _tabController;
  ScrollController customController = new ScrollController();
  List<List<DisplayItem>> _tabLists = [[],[]];

  List<ScrollController> _tabScrollControllers = [
    new ScrollController(),
    new ScrollController(),
  ];

  @override
  void initState() {
    super.initState();
    _tabController = new TabController(length: 2, vsync: this);

    userUid = widget.userUid;
    userCollection = parseUsersCollection[userUid];
    isCurrentUser = userUid == currentParseUserUid;

    print(userCollection.toString());
    refreshRatings();
    refreshCounts();

    modifiedListener = aUserModifyId.stream.listen((id) {
      if (id == userUid) setState(() {
        userCollection = parseUsersCollection[id];
        refreshCounts();
      });
    });

    _tabLists[0] = populateList(true);
    _tabLists[1] = populateList(false);

    bool customHandling = false;
    final double scrollThreshold = 100;
    final double verticalThreshold = 5;
    final Duration scrollDuration = new Duration(milliseconds: AnimInfo.profileSwipeMillis);
    //final Duration slowerDuration = new Duration(milliseconds: millis*3);
    final Curve scrollCurve = Curves.ease;

    double customPrevPixels;
    customController.addListener(() {
      ScrollPosition pos = customController.position;
      if (customPrevPixels == null) customPrevPixels = pos.pixels;
      bool isVertical = (pos.pixels - customPrevPixels).abs() > verticalThreshold;
      customPrevPixels = pos.pixels;
      if (pos.userScrollDirection == ScrollDirection.forward && isVertical) {
        setState(() {
          _reachedTop = false;
        });
        pos.animateTo(pos.minScrollExtent, duration: scrollDuration,
            curve: scrollCurve);
      }

      //var maxExtent = pos.maxScrollExtent - scrollThreshold;
      var minExtent = pos.minScrollExtent + scrollThreshold;
      if (pos.userScrollDirection == ScrollDirection.reverse && isVertical) {
        ScrollController childController = _tabScrollControllers[_tabController
            .index];
        setState(() {
          _reachedTop = true;
        });
        customHandling = true;
        if (!_tabLists[_tabController.index][0].isEmpty) childController.animateTo(
            scrollThreshold * 1.5, duration: scrollDuration,
            curve: scrollCurve);
        pos.animateTo(pos.maxScrollExtent, duration: scrollDuration,
            curve: scrollCurve);
        customHandling = false;
      }
    });

    void tabsListener(ScrollController controller) {
      ScrollPosition pos = controller.position;
      var triggerScroll = pos.minScrollExtent + scrollThreshold;

      if (!customHandling && pos.pixels < triggerScroll && pos.userScrollDirection == ScrollDirection.forward) {
        controller.animateTo(pos.minScrollExtent, duration: scrollDuration, curve: scrollCurve);
        setState(() {
          _reachedTop = false;
        });
        customController.animateTo(customController.position.minScrollExtent, duration: scrollDuration, curve: scrollCurve);

      }
    }
    _tabScrollControllers.forEach((controller) => controller.addListener(
        () => tabsListener(controller)
    ));
  }

  @override
  void dispose() {
    modifiedListener.cancel();

    customController.dispose();
    _tabScrollControllers.forEach((controller) => controller.dispose());
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_expandedHeight == null) _expandedHeight = getScreenHeight(context)/2;
    return Container(
      child: CustomScrollView(
        controller: customController,
        slivers: <Widget>[
          collapsibleWidget(context),
          SliverPersistentHeader(
            pinned: true,
            floating: false,
            delegate: _PersistentDelegate(
              minHeight: 50,
              maxHeight: 60,
              child: Container(
                color: CustomColors.colorPrimary,
                child: TabBar(
                  controller: _tabController,
                  labelColor: CustomColors.colorPrimaryDark,
                  tabs: <Widget>[
                    Tab(child: Text(Strings.tabLabelProfileSelling)),
                    Tab(child: Text(Strings.tabLabelProfilePosted)),
                  ],
                ),
              ),
            ),
          ),
          new SliverFillRemaining(
            child: TabBarView(
              controller: _tabController,
              children: <Widget>[
                sellingWidget(),
                postedWidget(),
              ],
            ),
          ),
        ],
      ),
    );
  }
  
  Widget collapsibleWidget(BuildContext context) {
    final paddingAround = EdgeInsets.all(paddingProfile);
    final paddingTop = EdgeInsets.only(top: paddingProfile);

    final followersCount = numberAdjusted(_followersCount);
    final followingCount = numberAdjusted(_followingCount);

    final screenWidth = getScreenWidth(context);
    final double offset = screenWidth / 15;
    final imgRadius = imageWidth/2;

    final double paddingTray = Dimens.paddingProfileTray;
    final double tabSize = Dimens.sizeProfileTrayTab;
    final double height = Dimens.heightProfileTray;

    final double previewWidth = imageWidth + 2 * paddingTray;
    final double childWidth = screenWidth - paddingTray - previewWidth - 2 * paddingTray - tabSize;
    final double childHeight = height - 4 * paddingTray;

    final double bgHeight = offset + imgRadius;
    final double containerWidth = screenWidth - (imageWidth + 2 * offset);

    return SliverList(
      delegate: SliverChildListDelegate([
        Stack(
          children: <Widget>[
            PullableTray(
              color: CustomColors.translucent(0.9),
              tabRadius: tabSize,
              height: height,
              padding: paddingTray,
              backgroundImage: DefaultImageNetwork(
                image: "https://images.unsplash.com/photo-1484766280341-87861644c80d?ixlib=rb-1.2.1&w=1000&q=80",
                width: screenWidth,
                height: height,
                fit: BoxFit.cover,
              ),
              alignment: Alignment.centerLeft,
              preview: Column(
                mainAxisSize: MainAxisSize.max,
                crossAxisAlignment: CrossAxisAlignment.center,
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: <Widget>[
                  ClipRRect(
                    borderRadius: BorderRadius.circular(imgRadius),
                    child: DefaultImageNetwork(
                      image: userCollection.profilePicture.url,
                      width: imageWidth,
                      height: imageWidth,
                      fit: BoxFit.cover,
                    ),
                  ),
                  Text(
                    "@${userCollection.displayName}",
                  ),
                  InkWell(
                    onTap: () => loadReviewDisplayWidget(context),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.start,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: <Widget>[
                        RatingBarIndicator(
                          itemSize: 20,
                          rating: _rating,
                          itemCount: 5,
                          itemBuilder: (context, _) => Icon(
                            Icons.star,
                            color: Colors.amber,
                          ),
                        ),
                        Padding(
                          padding: EdgeInsets.only(left: paddingProfile),
                          child: Text(
                            "($_rating)",
                            style: Styles.indicator,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              child: ConstrainedBox(
                constraints: BoxConstraints.tight(Size(childWidth, childHeight)),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: <Widget>[
                        InkWell(
                          onTap: () => loadUserList(context, TITLE_FOLLOWING),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            mainAxisAlignment: MainAxisAlignment.start,
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: <Widget>[
                              Text(
                                numberAdjusted(_followingCount),
                                style: TextStyle(
                                  fontSize: bgHeight * 1/2,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Text(
                                Strings.counterLabelFollowing,
                                style: Styles.bigCounterLabel,
                              )
                            ],
                          ),
                        ),
                        InkWell(
                          onTap: () => loadUserList(context, TITLE_FOLLOWERS),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            mainAxisAlignment: MainAxisAlignment.start,
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: <Widget>[
                              Text(
                                numberAdjusted(_followersCount),
                                style: TextStyle(
                                  fontSize: bgHeight * 1/2,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Text(
                                Strings.counterLabelFollowers,
                                style: Styles.bigCounterLabel,
                              )
                            ],
                          ),
                        ),
                      ],
                    ),
                    Expanded(
                      child: Scrollbar(
                        child: Padding(
                          padding: paddingAround,
                          child: SingleChildScrollView(
                            child: Text(userCollection.bio),
                          ),
                        ),
                      ),
                    ),
                    ButtonTheme(
                      minWidth: double.infinity,
                      child: isCurrentUser ? updateProfileButton() : followButton(),
                    ),
                  ],
                ),
              ),
            ),
            /*
            Stack(
              children: <Widget>[
                Column(
                  mainAxisAlignment: MainAxisAlignment.start,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    DefaultImageNetwork(
                      image: "https://images.unsplash.com/photo-1484766280341-87861644c80d?ixlib=rb-1.2.1&w=1000&q=80",
                      width: getScreenWidth(context),
                      height: bgHeight,
                      fit: BoxFit.cover,
                    ),
                    Align(
                      alignment: Alignment.centerRight,
                      child: Container(
                        width: containerWidth,
                        height: bgHeight,
                        padding: paddingAround,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: <Widget>[
                            InkWell(
                              onTap: () => loadUserList(context, TITLE_FOLLOWING),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                mainAxisAlignment: MainAxisAlignment.start,
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: <Widget>[
                                  Text(
                                    numberAdjusted(_followingCount),
                                    style: TextStyle(
                                      fontSize: bgHeight * 1/2,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  Text(
                                    Strings.counterLabelFollowing,
                                    style: Styles.bigCounterLabel,
                                  )
                                ],
                              ),
                            ),
                            Padding(
                              padding: EdgeInsets.only(left: paddingProfile),
                              child: InkWell(
                                onTap: () => loadUserList(context, TITLE_FOLLOWERS),
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  mainAxisAlignment: MainAxisAlignment.start,
                                  crossAxisAlignment: CrossAxisAlignment.center,
                                  children: <Widget>[
                                    Text(
                                      numberAdjusted(_followersCount),
                                      style: TextStyle(
                                        fontSize: bgHeight * 1/2,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    Text(
                                      Strings.counterLabelFollowers,
                                      style: Styles.bigCounterLabel,
                                    )
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    Padding(
                      padding: paddingAround,
                      child: Text(userCollection.bio),
                    ),
                    ButtonTheme(
                      minWidth: double.infinity,
                      child: isCurrentUser ? updateProfileButton() : followButton(),
                    ),
                  ],
                ),
                Positioned(
                  top: offset,
                  left: offset,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    mainAxisAlignment: MainAxisAlignment.start,
                    children: <Widget>[
                      ClipRRect(
                        borderRadius: BorderRadius.circular(imgRadius),
                        child: DefaultImageNetwork(
                          image: userCollection.profilePicture.url,
                          width: imageWidth,
                          height: imageWidth,
                          fit: BoxFit.cover,
                        ),
                      ),
                      Text(
                        "@${userCollection.displayName}",
                      ),
                      InkWell(
                        onTap: () => loadReviewDisplayWidget(context),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.start,
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: <Widget>[
                            RatingBarIndicator(
                              itemSize: 20,
                              rating: _rating,
                              itemCount: 5,
                              itemBuilder: (context, _) => Icon(
                                Icons.star,
                                color: Colors.amber,
                              ),
                            ),
                            Padding(
                              padding: EdgeInsets.only(left: paddingProfile),
                              child: Text(
                                "($_rating)",
                                style: Styles.indicator,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),

             */
            /*
            Row(
              mainAxisAlignment: MainAxisAlignment.start,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: <Widget>[
                Padding(
                  padding: paddingAround,
                  child: Align(
                    alignment: Alignment.center,
                    child: CircleAvatar(
                      radius: imageWidth/2,
                      backgroundColor: Colors.transparent,
                      backgroundImage: Image.network(
                        userCollection.profilePicture.url,
                        width: imageWidth,
                        height: imageWidth,
                        fit: BoxFit.cover,
                      ).image,
                    ),
                  ),
                ),
                Expanded(
                  child: ListView(
                    shrinkWrap: true,
                    physics: new NeverScrollableScrollPhysics(),
                    children: <Widget>[
                      Text(
                        "@${userCollection.displayName}",
                        style: Styles.listHeader,
                      ),
                      Padding(
                        padding: paddingTop,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.start,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: <Widget>[
                            Expanded(
                              flex: followersCount.length*10,
                              child: InkWell(
                                onTap: () => loadUserList(context, TITLE_FOLLOWERS),
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.start,
                                  crossAxisAlignment: CrossAxisAlignment.center,
                                  children: <Widget>[
                                    Text(
                                      followersCount,
                                      style: Styles.bigCounter,
                                    ),
                                    Text(
                                      Strings.counterLabelFollowers,
                                      style: Styles.bigCounterLabel,
                                    )
                                  ],
                                ),
                              ),
                            ),
                            Spacer(flex: 1,),
                            Expanded(
                              flex: followingCount.length*10,
                              child: InkWell(
                                onTap: () => loadUserList(context, TITLE_FOLLOWING),
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.start,
                                  crossAxisAlignment: CrossAxisAlignment.center,
                                  children: <Widget>[
                                    Text(
                                      numberAdjusted(_followingCount),
                                      style: Styles.bigCounter,
                                    ),
                                    Text(
                                      Strings.counterLabelFollowing,
                                      style: Styles.bigCounterLabel,
                                    )
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      Padding(
                        padding: paddingTop,
                        child: InkWell(
                          onTap: () => loadReviewDisplayWidget(context),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.start,
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: <Widget>[
                              RatingBarIndicator(
                                itemSize: 20,
                                rating: _rating,
                                itemCount: 5,
                                itemBuilder: (context, _) => Icon(
                                  Icons.star,
                                  color: Colors.amber,
                                ),
                              ),
                              Padding(
                                padding: EdgeInsets.only(left: paddingProfile),
                                child: Text(
                                  "($_rating)",
                                  style: Styles.indicator,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

              ],
            ),

             */
            Positioned(
              top: 5,
              right: 5,
              child: IconButton(
                icon: Icon(Icons.settings),
                onPressed: () => slidePageTransition(context, new SettingsDrawer(), LEFT),
              ),
            ),
          ],
        ),
        /*
        ButtonTheme(
          minWidth: double.infinity,
          child: isCurrentUser ? updateProfileButton() : followButton(),
        ),
        Padding(
          padding: paddingAround,
          child: Text(userCollection.bio),
        ),

         */
      ]),
    );
  }

  //Buttons
  Widget updateProfileButton() {
    return RaisedButton(
      shape: Styles.roundedButtonShape,
      color: CustomColors.colorPrimary,
      textColor: CustomColors.colorPrimaryDark,
      child: Text(
        Strings.buttonUpdateProfile
      ),
      onPressed: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => UpdateProfileWidget(updateProfileIntent: INTENT_UPDATE_PROFILE_EXISTING_USER,),
          )
        );
      },
    );
  }

  Widget followButton() {
    bool isFollowed = userCollection.followers.contains(currentParseUserUid);

    return RaisedButton(
      shape: Styles.roundedButtonShape,
      color: isFollowed ? CustomColors.colorGreyedOut : CustomColors.colorPrimary,
      textColor: isFollowed ? CustomColors.colorPrimary : CustomColors.colorPrimaryDark,
      child: Text(
        isFollowed ? Strings.buttonFollowed : Strings.buttonFollow,
      ),
      onPressed: () async {
        final setType = isFollowed ? SET_REMOVE : SET_ADD_UNIQUE;
        await updateParseUserData(userUid, {
          USER_FOLLOWERS : currentParseUserUid
        }, setType: setType);
        await updateParseUserData(currentParseUserUid, {
          USER_FOLLOWING : userUid
        }, setType: setType);
      },
    );
  }

  //Tabs
  Widget sellingWidget() {
    final list = _tabLists[0];
    return new DisplayGrid(
      controller: _tabScrollControllers[0],
      physics: (_reachedTop && list.length > 5) ? const AlwaysScrollableScrollPhysics() : const NeverScrollableScrollPhysics(),
      isScrollable: _reachedTop,
      isProduct: true,
      displayList: list,
    );
  }

  Widget postedWidget() {
    final list = _tabLists[1];
    return new DisplayGrid(
      controller: _tabScrollControllers[1],
      physics: (_reachedTop && list.length > 5) ? const AlwaysScrollableScrollPhysics() : const NeverScrollableScrollPhysics(),
      isScrollable: _reachedTop,
      isProduct: false,
      displayList: list,
    );
  }

  List<DisplayItem> populateList(bool isProduct) {
    List<DisplayItem> returnList = [];

    List<String> idList = isProduct ? userCollection.selling : userCollection.posted;
    for (String id in idList) {
      returnList.add(isProduct
          ? DisplayItem().fromProduct(parseShopCollection[id])
          : DisplayItem().fromPost(parseSocialCollection[id])
      );
    }

    if (returnList.isEmpty) returnList.add(DisplayItem(isEmpty: true));
    return returnList;
  }

  Future<void> refreshRatings() async {
    _reviewMap = await getParseReviews(userUid);
    double total = 0;
    _reviewMap.forEach((key, review) => total += review.rating);
    setState(() {
      _rating = _reviewMap.isNotEmpty ? total/_reviewMap.length : 0;
    });

    return;
  }

  void refreshCounts() {
    setState(() {
      _followingCount = userCollection.following.length.toDouble();
      _followersCount = userCollection.followers.length.toDouble();
    });
  }

  void loadReviewDisplayWidget(BuildContext context) async {
    await refreshRatings();
    fadePageTransition(context, ReviewDisplayWidget(
      reviewMap: _reviewMap,
      userUid: userUid,
    ));
  }

  void loadUserList(BuildContext context, String title) {
    Navigator.push(context, MaterialPageRoute(
      builder: (context) => UserListWidget(
        title: "@${userCollection.displayName} $title",
        userUids: (title == TITLE_FOLLOWERS) ? userCollection.followers : userCollection.following,
      ),
    ));
  }

}

class DisplayGrid extends StatelessWidget {
  final ScrollController controller;
  final ScrollPhysics physics;
  final bool isProduct;
  final bool isScrollable;
  final List<DisplayItem> displayList;
  DisplayGrid({this.controller, this.physics, this.isScrollable, this.isProduct, this.displayList});

  @override
  Widget build(BuildContext context) {
    final gridSpacing = Dimens.paddingStaggeredGrid;
    if (displayList[0].isEmpty) return Center(
      child: Text(
        "You haven't made any ${isProduct ? 'listings' : 'posts'} yet.",
        style: Styles.indicator,
      ),
    );
    return Padding(
      padding: EdgeInsets.all(gridSpacing),
      child: StaggeredGridView.countBuilder(
          physics: physics,
          controller: controller,
          mainAxisSpacing: gridSpacing,
          crossAxisSpacing: gridSpacing,
          crossAxisCount: 4,
          staggeredTileBuilder: (int index) => StaggeredTile.fit(2),
          itemBuilder: (BuildContext context, int index) {
            DisplayItem item = displayList[index];
            final imageWidth = (getScreenWidth(context) - 3 * gridSpacing) / 2;
            /*
            return SizedBox(
              width: imageWidth,
              height: imageWidth,
              child: Text(index.toString()),
            );
            */
            return Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.center,
              mainAxisAlignment: MainAxisAlignment.start,
              children: <Widget>[
                ClipRRect(
                  borderRadius: BorderRadius.circular(8.0),
                  child: DefaultImageNetwork(
                    image: item.coverImage.url,
                    width: imageWidth,
                    fit: BoxFit.cover,
                  ),
                ),
                Padding(
                  padding: EdgeInsets.all(gridSpacing),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: <Widget>[
                      Text(item.title),
                      trailing(item, gridSpacing),
                    ],
                  ),
                ),
              ],
            );
            //*/

          },
          itemCount: displayList.length,
        ),
    );
  }

  Widget trailing(DisplayItem item, double gridSpacing) {
    if (item.isProduct) return Text("\$${item.price}");

    return Row(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: <Widget>[
        Padding(
          padding: EdgeInsets.only(right: gridSpacing),
          child: Text(item.likedBy.length.toString()),
        ),
        Icon(CustomIcons.heart_empty),
      ],
    );
  }
}

class _PersistentDelegate extends SliverPersistentHeaderDelegate {
  _PersistentDelegate({
    @required this.minHeight,
    @required this.maxHeight,
    @required this.child,
  });
  final double minHeight;
  final double maxHeight;
  final Widget child;
  @override
  double get minExtent => minHeight;
  @override
  double get maxExtent => max(maxHeight, minHeight);
  @override
  Widget build(
      BuildContext context,
      double shrinkOffset,
      bool overlapsContent)
  {
    return new SizedBox.expand(child: child);
  }
  @override
  bool shouldRebuild(_PersistentDelegate oldDelegate) {
    return maxHeight != oldDelegate.maxHeight ||
        minHeight != oldDelegate.minHeight ||
        child != oldDelegate.child;
  }

}