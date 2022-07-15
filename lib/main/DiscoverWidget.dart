import 'dart:async';
import 'dart:math';

import 'package:fleek/dataclasses/Hashtag.dart';
import 'package:fleek/dataclasses/PProduct.dart';
import 'package:fleek/dataclasses/Product.dart';
import 'package:fleek/discoverExtras/DiscoverBrowseWidget.dart';
import 'package:fleek/discoverExtras/DiscoverSearchWidget.dart';
import 'package:fleek/discoverExtras/DiscoverSeeAllWidget.dart';
import 'package:fleek/global/globalFunctions.dart';
import 'package:fleek/global/globalItems.dart';
import 'package:fleek/values/animInfo.dart';
import 'package:fleek/values/colors.dart';
import 'package:fleek/values/dimens.dart';
import 'package:fleek/values/ints.dart';
import 'package:fleek/values/styles.dart';
import 'package:fleek/widgetClasses/CustomChip.dart';
import 'package:fleek/widgetClasses/DefaultImageFile.dart';
import 'package:fleek/widgetClasses/DefaultImageNetwork.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import '../values/strings.dart';

class DiscoverWidget extends StatefulWidget {
  final String title = "Discover";

  @override
  _DiscoverWidgetState createState() => _DiscoverWidgetState();
}

class _DiscoverWidgetState extends State<DiscoverWidget> with TickerProviderStateMixin {
  String itemGender = FILTER_GENDER_BOTH;
  List<String> _catsDisplayList = defaultCatsList;
  List<String> _stylesDisplayList = initialSixStyles;
  List<PProduct> _forYouDisplayList = [new PProduct()];
  List<PProduct> _latestDisplayList = [new PProduct()];

  StreamSubscription<bool> defaultSettingsListener;
  StreamSubscription<bool> shopDownloadCompleteListener;
  StreamSubscription<String> shopAddedListener;
  StreamSubscription<String> shopModifiedListener;
  StreamSubscription<Hashtag> hashtagListener;

  final _scrollController = new ScrollController();
  
  static final maxHashtags = Ints.discoverMaxHashtags;
  List<Hashtag> topHashtagsList = getTopHashtags(maxHashtags);
  
  @override
  void initState() {
    super.initState();
    
    refreshProductLists();

    hashtagListener = aHashtagChanged.stream.listen((hashtag) {
      print("hashtag with id listened: ${hashtag.objectId}");
      setState(() => topHashtagsList = getTopHashtags(maxHashtags));
    });
    
    shopDownloadCompleteListener = aInitialShopDownloadComplete.stream.listen((event) {
      if (event) {
        refreshProductLists();
      }
    });

    defaultSettingsListener = aSettingsDownloaded.stream.listen((isDownloaded) {
      if (isDownloaded) setState(() {});
      print("downloaded: $isDownloaded");
    });

    shopAddedListener = aShopAddId.stream.listen((id) => refreshProductLists());
    shopModifiedListener = aShopModifyId.stream.listen((id) {
      refreshProductLists();
    });

  }


  @override
  void dispose() {
    shopDownloadCompleteListener.cancel();
    defaultSettingsListener.cancel();
    shopAddedListener.cancel();
    shopModifiedListener.cancel();
    hashtagListener.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final TextStyle labelStyle = Styles.smallLabel;
    final double paddingVal = Dimens.paddingDiscoverColumn;
    final paddingTop = EdgeInsets.only(top: paddingVal);
    final paddingAround = EdgeInsets.all(paddingVal);
    final paddingThree = EdgeInsets.fromLTRB(paddingVal, paddingVal, paddingVal, 0);
    final double ratioAdjust = paddingVal + labelStyle.fontSize;

    final double screenWidthHalf = getScreenWidth(context) / 2;
    final double typeGridViewContainerWidth = screenWidthHalf - paddingVal * 3/2;
    final double typeGridViewContainerHeight = typeGridViewContainerWidth + ratioAdjust;
    final double typeGridViewAspectRatio = typeGridViewContainerWidth/typeGridViewContainerHeight;

    final double screenWidthThird = getScreenWidth(context) / 3;
    final double styleGridViewContainerWidth = screenWidthThird - (paddingVal *4/3);
    final double styleGridViewContainerHeight = styleGridViewContainerWidth + ratioAdjust;
    final double styleGridViewAspectRatio = styleGridViewContainerWidth/styleGridViewContainerHeight;

    double imageMaxDiff;
    double textMaxDiff;

    final double hashtagPaddingH = 15;
    final double hashtagPaddingV = 10;
    final double hashtagHeight = 4 * hashtagPaddingV + Styles.discoverChipText.fontSize;

    double paddingSearchTop;
    double imageOpacity, textOpacity;

    return NestedScrollView(
      controller: _scrollController,
      headerSliverBuilder: (BuildContext context, bool innerBoxIsScrolled) {
        final borderRadius = BorderRadius.vertical(bottom: Radius.circular(25));
        return <Widget>[
          SliverAppBar(
            shape: RoundedRectangleBorder(
              borderRadius: borderRadius,
            ),
            backgroundColor: Colors.transparent,
            actionsIconTheme: IconThemeData(opacity: 0.0),
            pinned: true,
            floating: false,
            elevation: 0,
            flexibleSpace: LayoutBuilder(
              builder: (BuildContext context, BoxConstraints constraints) {
                final top = constraints.biggest.height;
                final collapsed = MediaQuery.of(context).padding.top + kToolbarHeight;

                final paddingSide = Dimens.paddingDiscoverColumn;
                paddingSearchTop = (top - collapsed) / 50;

                final textCollapsed = (getScreenHeight(context)/3.4 + paddingSearchTop);
                if (imageMaxDiff == null) imageMaxDiff = top - collapsed;
                if (textMaxDiff == null) textMaxDiff = top - textCollapsed;

                imageOpacity = ((top - collapsed) / imageMaxDiff).clamp(0.0, 1.0);
                textOpacity = ((top - textCollapsed) / textMaxDiff).clamp(0.0, 1.0);

                bool isExpanded = top > textCollapsed;

                return Stack(
                  children: <Widget>[
                    ClipRRect(
                      child: ColorFiltered(
                        colorFilter: ColorFilter.mode(Colors.white.withOpacity(imageOpacity), BlendMode.dstATop),
                        child: DefaultImageNetwork(
                          image: "https://i.pinimg.com/originals/71/a7/f8/71a7f826e0d59cabae43ef9682a4a527.jpg",
                          colorFilter: ColorFilter.mode(CustomColors.coverTint(), BlendMode.color),
                          fit: BoxFit.cover,
                          width: getScreenWidth(context),
                        ),
                      ),
                      borderRadius: borderRadius,
                    ),

                    SafeArea(
                      child: ConstrainedBox(
                        constraints: BoxConstraints.expand(),
                        child: Container(
                          decoration: BoxDecoration(
                            borderRadius: borderRadius,
                            color: Colors.transparent,
                          ),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: <Widget>[
                              Padding(
                                padding: EdgeInsets.only(
                                  left: paddingSide,
                                  right: paddingSide,
                                  top: paddingSearchTop,
                                ),
                                child: ButtonTheme(
                                  minWidth: double.infinity,
                                  child: RaisedButton(
                                    shape: Styles.roundedButtonShape,
                                    color: CustomColors.colorPrimary,
                                    child: Stack(
                                      children: <Widget>[
                                        Icon(Icons.search),
                                        Container(
                                          alignment: Alignment.center,
                                          child: Text('Search'),
                                        ),
                                      ],
                                    ),
                                    onPressed: () => launchSearchWidget(context),
                                  ),
                                ),
                              ),
                              if (isExpanded) Padding(
                                padding: EdgeInsets.all(paddingVal),
                                child: Opacity(
                                  opacity: textOpacity,
                                  child: Text(
                                    Strings.discoverBanner,
                                    textAlign: TextAlign.left,
                                    style: Styles.discoverBanner,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
            expandedHeight: getScreenHeight(context)/3,
          ),
        ];
      },
      body: ListView(
        shrinkWrap: true,
        children: <Widget>[
          //top hashtags layout
          Padding(
            padding: paddingThree,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.start,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  Strings.discoverHashtagsHeader,
                  style: Styles.listHeader,
                ),
                Container(
                  padding: paddingTop,
                  height: hashtagHeight,
                  child: (topHashtagsList.isEmpty)
                      ? centeredEmptyWidget("No hashtags in use currently.")
                      : ListView(
                    shrinkWrap: true,
                    scrollDirection: Axis.horizontal,
                    children: List.generate(topHashtagsList.length, (index) {
                      final hashtag = topHashtagsList[index];
                      return Container(
                        padding: index == 0 ? null : EdgeInsets.only(left: paddingVal),
                        alignment: Alignment.center,
                        child: CustomChip(
                          backgroundColor: CustomColors.chipGrey,
                          label: Text(
                            "${hashtag.name}".toUpperCase(),
                            style: Styles.discoverChipText,
                          ),
                          onPressed: () => launchEndlessScrollWidget(
                            context,
                            hashtag.objectId,
                            INTENT_SEE_ALL_HASHTAGS,
                          ),
                          borderRadius: 10,
                          paddingH: hashtagPaddingH,
                          paddingV: hashtagPaddingV,
                        ),
                      );
                    }),
                  ),
                ),
              ],
            ),
          ),
          //types display layout
          Padding(
            padding: paddingThree,
            child: Column(
              children: <Widget>[
                //title row
                Row(
                  //mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: <Widget>[
                    Text(
                      Strings.discoverCategoriesHeader,
                      style: Styles.listHeader,
                    ),
                    /*
                    OutlineButton(
                        child: new Text(
                          Strings.buttonSeeAll,
                          style: Styles.seeAllButton,
                        ),
                        onPressed: () => launchSeeAllWidget(context, SEE_ALL_CATEGORIES),
                        shape: new RoundedRectangleBorder(borderRadius: new BorderRadius.circular(Dimens.radiusSeeAllButton))
                    ),

                     */
                  ],
                ),

                //grid layout
                Padding(
                  padding: paddingTop,
                  child: GridView.count(
                    mainAxisSpacing: paddingVal,
                    crossAxisSpacing: paddingVal,
                    childAspectRatio: typeGridViewAspectRatio,
                    physics: new NeverScrollableScrollPhysics(),
                    shrinkWrap: true,
                    crossAxisCount: 2,
                    children: List.generate(_catsDisplayList.length, (index) {
                      String currentHeader = _catsDisplayList[index];
                      String firstType = getTypeList(itemGender, currentHeader)[0];
                      String imageUri = defaultSettings.types[firstType];

                      if (imageUri != null) {
                        double adjustedWidth = typeGridViewContainerWidth;
                        return InkWell(
                          onTap: () {launchEndlessScrollWidget(context, currentHeader, INTENT_ENDLESS_SCROLL_CATS);},
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            mainAxisSize: MainAxisSize.max,
                            children: <Widget>[
                              ClipRRect(
                                borderRadius: BorderRadius.circular(8.0),
                                child: DefaultImageNetwork(
                                  colorFilter: CustomColors.coverFilter,
                                  image: imageUri,
                                  width: adjustedWidth,
                                  height: adjustedWidth,
                                  fit: BoxFit.cover,
                                ),
                              ),
                              Padding(
                                padding: EdgeInsets.only(top: paddingVal),
                                child: Text(
                                  currentHeader,
                                  style: labelStyle,
                                ),
                              ),

                            ],
                          ),
                        );

                      }
                      else {
                        return Container(
                          color: Colors.white,
                        );
                      }

                    })
                      ..add(InkWell(
                        onTap: () => launchSeeAllWidget(context, SEE_ALL_CATEGORIES),
                        child: Container(
                          decoration: BoxDecoration(
                            color: CustomColors.createGrey,
                            borderRadius: BorderRadius.circular(8.0),
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            'See All',
                            style: TextStyle(
                              fontSize: 30,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      )),
                  ),
                ),
              ],
            ),
          ),

          //styles display layout
          Padding(
            padding: paddingThree,
            child: Column(
              children: <Widget>[
                //title row
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: <Widget>[
                    Text(
                      Strings.discoverStylesHeader,
                      style: Styles.listHeader,
                    ),
                    OutlineButton(
                        child: new Text(
                          Strings.buttonSeeAll,
                          style: Styles.seeAllButton,
                        ),
                        onPressed: () {launchSeeAllWidget(context, SEE_ALL_STYLES);},
                        shape: new RoundedRectangleBorder(borderRadius: new BorderRadius.circular(Dimens.radiusSeeAllButton))
                    ),
                  ],
                ),

                //grid layout
                Padding(
                  padding: paddingTop,
                  child: GridView.count(
                    mainAxisSpacing: paddingVal,
                    crossAxisSpacing: paddingVal,
                    childAspectRatio: styleGridViewAspectRatio,
                    physics: const NeverScrollableScrollPhysics(),
                    shrinkWrap: true,
                    crossAxisCount: 3,
                    children: List.generate(6, (index) {
                      String currentHeader = _stylesDisplayList[index];
                      String imageUri = defaultSettings.styles[currentHeader];

                      if (imageUri != null) {
                        double adjustedWidth = styleGridViewContainerWidth;
                        return InkWell(
                          onTap: () {launchEndlessScrollWidget(context, currentHeader, INTENT_SEE_ALL_STYLES);}, //set later
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            mainAxisSize: MainAxisSize.max,
                            children: <Widget>[
                              ClipRRect(
                                borderRadius: BorderRadius.circular(8.0),
                                child: DefaultImageNetwork(
                                  image: imageUri,
                                  width: adjustedWidth,
                                  height: adjustedWidth,
                                  fit: BoxFit.cover,
                                ),
                              ),
                              Padding(
                                padding: paddingTop,
                                child: Text(
                                  currentHeader,
                                  style: labelStyle,
                                ),
                              ),
                            ],
                          ),
                        );

                      }
                      else {
                        return Container(
                          child: Text(index.toString()),
                        );
                      }

                    }),
                  ),
                ),
              ],
            ),
          ),

          //for you display layout
          Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: <Widget>[
              Padding(
                padding: paddingAround,
                child: Text(
                  Strings.discoverForYouHeader,
                  style: Styles.listHeader,
                ),
              ),
              Container(
                height: screenWidthThird,
                child: ListView(
                  shrinkWrap: true,
                  scrollDirection: Axis.horizontal,
                  children: List.generate(_forYouDisplayList.length, (index){
                    PProduct currentProduct = _forYouDisplayList[index];
                    if (currentProduct.title.isEmpty) {
                      return centeredEmptyWidget("There aren't any listings right now. Try again later.");
                    }
                    return InkWell(
                      onTap: () => launchSwipeWidget(context, currentProduct),
                      child: DefaultImageNetwork(
                        image: currentProduct.images[0].url,
                        width: screenWidthThird,
                        height: screenWidthThird,
                        fit: BoxFit.cover,
                      ),
                    );
                  }),
                ),
              ),
            ],
          ),

          //latest display layout
          Column(
            children: <Widget>[
              Padding(
                padding: paddingAround,
                child: Text(
                  Strings.discoverLatestHeader,
                  style: Styles.listHeader,
                ),
              ),
              Container(
                height: screenWidthThird,
                child: ListView(
                  shrinkWrap: true,
                  scrollDirection: Axis.horizontal,
                  children: List.generate(_latestDisplayList.length, (index){
                    PProduct currentProduct = _latestDisplayList[index];

                    if (currentProduct.images.isEmpty) {
                      return centeredEmptyWidget("There aren't any listings right now. Try again later.");
                    }
                    return InkWell(
                      onTap: () => launchSwipeWidget(context, currentProduct),
                      child: DefaultImageNetwork(
                        image: currentProduct.images[0].url,
                        width: screenWidthThird,
                        height: screenWidthThird,
                        fit: BoxFit.cover,
                      ),
                    );
                  }),
                ),
              ),
            ],
          ),


        ],
      ),
    );
  }

  void launchSearchWidget(BuildContext context) {
    Navigator.push(context, MaterialPageRoute(builder: (context) => DiscoverSearchWidget()));
  }

  void launchSeeAllWidget(BuildContext context, String pageType) {
    print("launching see all");
    fadePageTransition(context, DiscoverSeeAllWidget(
      seeAllType: pageType,
      gender: itemGender,
    ));
  }

  void launchEndlessScrollWidget(
      BuildContext context,
      String query,
      String queryType
      ) {
    fadePageTransition(context, new DiscoverBrowseWidget(
      query: query,
      queryType: queryType,
      gender: itemGender,
    ));
  }

  void refreshProductLists() {
    List<PProduct> completeFilteredList = addShopCollectionToList(List(), filteredShopCollection(null));
    List<PProduct> completeRecommendedList = getRecommendedProductList(getRecommendedProductMap(null, [], ""));
    int maxProducts = Ints.discoverCarouselMaxProducts;
    completeFilteredList.sort(timeComparator);

    setState(() {
      _latestDisplayList = completeFilteredList.length > 0
      ? completeFilteredList.sublist(
          0, min(completeFilteredList.length, maxProducts)
      )
      : [new PProduct()];
      _forYouDisplayList = completeRecommendedList.length > 0
      ? completeRecommendedList.sublist(
          0, min(completeRecommendedList.length, maxProducts)
      )
      : [new PProduct()];
    });
  }

}