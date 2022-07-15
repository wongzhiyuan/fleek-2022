import 'dart:async';
import 'dart:math';

import 'package:fleek/dataclasses/Filter.dart';
import 'package:fleek/dataclasses/PProduct.dart';
import 'package:fleek/dataclasses/PUser.dart';
import 'package:fleek/dataclasses/Product.dart';
import 'package:fleek/dataclasses/User.dart';
import 'package:fleek/discoverExtras/DiscoverSwipeWidget.dart';
import 'package:fleek/global/globalFunctions.dart';
import 'package:fleek/global/globalItems.dart';
import 'package:fleek/main/ProfileWidget.dart';
import 'package:fleek/values/colors.dart';
import 'package:fleek/values/animInfo.dart';
import 'package:fleek/values/dimens.dart';
import 'package:fleek/values/ints.dart';
import 'package:fleek/values/strings.dart';
import 'package:fleek/values/styles.dart';
import 'package:fleek/widgetClasses/CircularImage.dart';
import 'package:fleek/widgetClasses/DefaultImageFile.dart';
import 'package:fleek/widgetClasses/DefaultImageNetwork.dart';
import 'package:fleek/widgetClasses/FilterOverlayEntry.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';

class DiscoverEndlessScrollWidget extends StatefulWidget {
  final String title = "Discover Endless Scroll";
  final String query;
  final String queryType;
  final String gender;

  DiscoverEndlessScrollWidget({this.query, this.queryType, this.gender});

  _DiscoverEndlessScrollState createState() => _DiscoverEndlessScrollState();
}

class _DiscoverEndlessScrollState extends State<DiscoverEndlessScrollWidget> with WidgetsBindingObserver, TickerProviderStateMixin {
  bool isSortMenuOpen = false;
  bool isFilterMenuOpen = false;
  bool shouldShowTypesFilter = false;

  final sortString = Strings.buttonSort;
  OverlayEntry _sortOverlayEntry;
  final filterString = Strings.buttonFilter;
  OverlayEntry _filterOverlayEntry;

  final _sortKey = LabeledGlobalKey(Strings.buttonSort);
  Size sortButtonSize;
  Offset sortButtonPosition;
  final _filterKey = LabeledGlobalKey(Strings.buttonFilter);
  Size filterButtonSize;
  Offset filterButtonPosition;

  String query;
  String queryType;
  String gender;
  List<String> typeList = [];

  List<PProduct> _displayList = [];
  List<PProduct> _completeList = [];

  int _pageNum = 1;
  final threshold = Ints.discoverEndlessScrollThreshold;

  ScrollController _scrollController = new ScrollController();

  final padding = Dimens.paddingDiscoverEndlessScrollAround;
  StreamSubscription<String> addedListener;
  StreamSubscription<String> modifiedListener;
  StreamSubscription<String> removedListener;

  bool isSearch = false;
  StreamSubscription<String> searchListener;

  AnimationController _sortController, _filterController;

  @override
  void initState() {
    super.initState();

    const int millis = AnimInfo.expandingHeightMillis;
    _sortController = new AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: millis),
    );
    _filterController = new AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: millis),
    );

    query = widget.query.toString();
    queryType = widget.queryType;
    gender = widget.gender;

    isSearch = queryType == INTENT_SEE_ALL_SEARCH;
    refreshDisplayList();

    if (isSearch) {
      searchListener = aSearchUpdated.stream.listen((newQuery) {
        query = newQuery;
        refreshDisplayList();
      });
    }

    if (queryType == INTENT_ENDLESS_SCROLL_CATS) {
      typeList = getTypeList(gender, query);
      shouldShowTypesFilter = true;
    }

    addedListener = aShopAddId.stream.listen((id) {
      if ((_completeList.length - _displayList.length) < 5) {
        refreshDisplayList();
      }
    });

    modifiedListener = aShopModifyId.stream.listen((id) {
      if (parseShopCollection[id].likedBy.contains(currentParseUserUid)) {
        setState(() {
          _displayList.removeWhere((product) => (id == product.id));
        });
      }
    });

    removedListener = aShopDeleteId.stream.listen((id) {
      var idCheck = (product) => product.id == id;
      setState(() {
        _displayList.removeWhere(idCheck);
      });
      _completeList.removeWhere(idCheck);
    });
    
    _scrollController.addListener(() {
      var triggerFetchMoreSize = 0.9 * _scrollController.position.maxScrollExtent;
      final _completeSize = _completeList.length;

      if (_scrollController.position.pixels > triggerFetchMoreSize) {
        int startIndex = _pageNum * threshold;
        int stopIndex = (_pageNum + 1) * threshold;

        if (startIndex < _completeSize) {
          //can add
          if (stopIndex > _completeSize) {
            stopIndex = _completeSize;
          }

          print("start: $startIndex, stop: $stopIndex");
          _pageNum += 1;
          setState(() {
            _displayList.addAll(
                _completeList.sublist(startIndex, stopIndex)
            );
          });
        }

      }
    });
  }

  @override
  void dispose() {
    print("disposing");
    _scrollController.dispose();
    addedListener.cancel();
    modifiedListener.cancel();
    removedListener.cancel();
    if (isSearch) searchListener.cancel();
    if (currentFilters.containsKey(FILTER_TYPE)) currentFilters.remove(FILTER_TYPE);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      refreshDisplayList();
    }
  }

  @override
  Widget build(BuildContext context) {
    final imageWidth = (getScreenWidth(context) - 3 * padding) / 2;

    return WillPopScope(
      onWillPop: () async {
        closeAllMenus();
        return true;
      },
      child: Column(
        children: <Widget>[
          if (shouldShowTypesFilter) filterTypes(query),
          Row(
            children: <Widget>[
              Expanded(
                flex: 1,
                child: ButtonTheme(
                  minWidth: double.infinity,
                  child: FlatButton(
                    key: _sortKey,
                    color: CustomColors.colorPrimary,
                    textColor: CustomColors.colorPrimaryDark,
                    child: Text(sortString),
                    onPressed: handleSortButton,
                  ),
                ),
              ),
              Expanded(
                flex: 1,
                child: ButtonTheme(
                  minWidth: double.infinity,
                  child: FlatButton(
                    key: _filterKey,
                    color: CustomColors.colorPrimary,
                    textColor: CustomColors.colorPrimaryDark,
                    child: Text(filterString),
                    onPressed: handleFilterButton,
                  ),
                ),
              ),
            ],
          ),
          Expanded(
            child: GestureDetector(
              onTap: closeAllMenus,
              child: Padding(
                padding: EdgeInsets.all(padding),
                child: (_displayList.length > 0)
                    ? StaggeredGridView.countBuilder(
                  controller: _scrollController,
                  crossAxisCount: 4,
                  crossAxisSpacing: padding,
                  mainAxisSpacing: padding,
                  itemCount: _displayList.length,
                  itemBuilder: (context, index) {
                    PProduct currentProduct = _displayList[index];
                    PUser seller = parseUsersCollection[currentProduct.seller];

                    final paddingD = Dimens.paddingDiscoverEndlessScrollDetails;
                    final radius = 8.0;
                    final paddingR = radius / 2;
                    return Column(
                      mainAxisSize: MainAxisSize.min,
                      mainAxisAlignment: MainAxisAlignment.start,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        InkWell(
                            onTap: () {
                              closeAllMenus();
                              launchSwipeWidget(context, currentProduct);
                            },
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(radius),
                              child: DefaultImageNetwork(
                                image: currentProduct.images[0].url,
                                width: imageWidth,
                                fit: BoxFit.cover,
                              ),
                            ),
                        ),
                        Padding(
                          padding: EdgeInsets.only(top: paddingD, left: paddingR, right: paddingR),
                          child: Row(
                            mainAxisSize: MainAxisSize.max,
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: <Widget>[
                              Expanded(
                                child: Text(
                                  currentProduct.title,
                                  style: Styles.detailsHeader,
                                ),
                              ),
                              ConstrainedBox(
                                constraints: BoxConstraints.tightFor(width: 20),
                                child: Text(
                                  currentProduct.size,
                                  style: Styles.detailsHeader,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Padding(
                          padding: EdgeInsets.only(top: paddingD, left: paddingR),
                          child: GestureDetector(
                            onTap: () => fadePageTransition(context, ProfileWidget(userUid: currentProduct.seller,)),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: <Widget>[
                                CircularImage(
                                  uri: seller.profilePicture.url,
                                  size: Dimens.imageSizeTiny,
                                ),
                                Padding(
                                  padding: EdgeInsets.only(left: paddingD),
                                  child: Text(seller.displayName),
                                )
                              ],
                            ),
                          ),
                        ),

                        Padding(
                          padding: EdgeInsets.only(top: paddingD, left: paddingR),
                          child: Text(
                            "POSTED ${formatTimestamp(currentProduct.timestamp)}",
                            style: Styles.details,
                          ),
                        ),

                      ],
                    );
                  },
                  staggeredTileBuilder: (int index) => new StaggeredTile.fit(2),
                )
                    : centeredEmptyWidget("No products yet."),
              ),
            ),

          ),
        ],
      ),
    );
  }

  void refreshDisplayList() {
    _completeList.clear();
    _displayList.clear();
    _pageNum = 1;

    var comparator;
    switch(currentSortMethod) {
      case (SORT_RECOMMENDED): {
        comparator = defaultComparator;
      }
      break;
      case (SORT_TIME): {
        comparator = timeComparator;
      }
      break;
      case (SORT_PRICE_LOW_HIGH): {
        comparator = priceComparator;
      }
      break;
      case (SORT_PRICE_HIGH_LOW): {
        comparator = priceComparatorReversed;
      }
      break;
      default: {
        comparator = defaultComparator;
      }
      break;
    }

    if (queryType != INTENT_SEE_ALL_SEARCH) {
      Map<String, List<PProduct>> completeMap = Map();
      if (queryType == INTENT_ENDLESS_SCROLL_CATS) {
        completeMap = getRecommendedProductMap(currentFilters, typeList, "");
      }
      else if (queryType == INTENT_SEE_ALL_TYPES)
        completeMap = getRecommendedProductMap(currentFilters, [query], "");
      else if (queryType == INTENT_SEE_ALL_STYLES)
        completeMap = getRecommendedProductMap(currentFilters, [], query);
      else if (queryType == INTENT_SEE_ALL_HASHTAGS)
        completeMap = getRecommendedProductMap(currentFilters, [], "", hashtagIDs: [query]);
      else
        completeMap = getRecommendedProductMap(currentFilters, [], "");

      completeMap[RECOMMENDED_PRIORITY].sort(comparator);
      completeMap[RECOMMENDED_SECONDARY].sort(comparator);

      _completeList.addAll(completeMap[RECOMMENDED_PRIORITY]);
      _completeList.addAll(completeMap[RECOMMENDED_SECONDARY]);
    }
    else if (queryType == INTENT_SEE_ALL_SEARCH) {
      _completeList = databaseSearch(query, SHOP_TITLE, true, currentFilters);
      _completeList.sort(comparator);
    }

    setState(() {
      _displayList.addAll(
        _completeList.sublist(
          0,
          min(_completeList.length, threshold)
        )
      );
    });
  }

  Widget filterTypes(String cat) {
    typeList.sort();

    final double height = 65;
    final double padding = (height - Styles.discoverFilterTypesListText(false).fontSize) / 2 - 2;

    return Container(
      color: CustomColors.colorPrimary,
      padding: EdgeInsets.symmetric(vertical: padding),
      height: height,
      alignment: Alignment.center,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        shrinkWrap: true,
        itemCount: typeList.length,
        itemBuilder: (BuildContext context, int index) {
          String type = typeList[index];
          bool typeSelected = currentFilters.containsKey(FILTER_TYPE)
              ? currentFilters[FILTER_TYPE].values.contains(type)
              : false;

          return Padding(
            padding: EdgeInsets.only(left: padding, right: (index == typeList.length - 1) ? padding : 0),
            child: GestureDetector(
              onTap: () {
                Filter filter = Filter(type);
                filter.values.add(type);

                if (currentFilters.containsKey(FILTER_TYPE)) {
                  filter = currentFilters[FILTER_TYPE];
                  (filter.values.contains(type)) ? filter.values.remove(type) : filter.values.add(type);
                }
                else currentFilters[FILTER_TYPE] = filter;
                refreshDisplayList();
              },
              child: Text(
                type,
                style: Styles.discoverFilterTypesListText(typeSelected),
              ),
            ),
          );
        }
      ),
    );
  }

  void handleSortButton() {
    if (isSortMenuOpen) {
      //close sort menu
      closeSortMenu();
    }
    else if (isFilterMenuOpen) {
      //close filter menu, open sort menu
      closeFilterMenu();
      openSortMenu();
    }
    else {
      //open sort menu
      openSortMenu();
    }
  }

  void handleFilterButton() {
    if (isFilterMenuOpen) {
      //close filter menu
      closeFilterMenu();
    }
    else if (isSortMenuOpen) {
      //close sort menu, open filter menu
      closeSortMenu();
      openFilterMenu();
    }
    else {
      //open filter menu
      openFilterMenu();
    }
  }

  void findButton(LabeledGlobalKey key, String buttonType) {
    RenderBox renderBox = key.currentContext.findRenderObject();
    switch (buttonType) {
      case (Strings.buttonSort): {
        sortButtonSize = renderBox.size;
        sortButtonPosition = renderBox.localToGlobal(Offset.zero);
      }
      break;
      case (Strings.buttonFilter): {
        filterButtonSize = renderBox.size;
        filterButtonPosition = renderBox.localToGlobal(Offset.zero);
      }
      break;
    }
  }
  void openSortMenu() {
    findButton(_sortKey, sortString);
    _sortOverlayEntry = sortOverlayBuilder();
    Overlay.of(context).insert(_sortOverlayEntry);
    _sortController.forward();
    isSortMenuOpen = true;
  }

  void closeSortMenu() async {
    await _sortController.reverse();
    _sortOverlayEntry.remove();
    refreshDisplayList();
    isSortMenuOpen = false;
  }

  void openFilterMenu() {
    findButton(_filterKey, filterString);
    _filterOverlayEntry = filterOverlayBuilder();
    Overlay.of(context).insert(_filterOverlayEntry);
    _filterController.forward();
    isFilterMenuOpen = true;
  }

  void closeFilterMenu() async {
    await _filterController.reverse();
    _filterOverlayEntry.remove();
    refreshDisplayList();
    final List<String> genderValues = (currentFilters.containsKey(FILTER_GENDER))
        ? currentFilters[FILTER_GENDER].values
        : [];

    final String setGender = (genderValues.length > 1)
        ? FILTER_GENDER_BOTH
        : (genderValues.length == 0) ? null : genderValues[0];
    setState(() {
      if (setGender != null) {
        typeList = getTypeList(setGender, query);
        currentFilters[FILTER_TYPE].values.removeWhere((type) => !typeList.contains(type));
      }
    });
    isFilterMenuOpen = false;
  }

  void closeAllMenus() {
    if (isSortMenuOpen) closeSortMenu();
    if (isFilterMenuOpen) closeFilterMenu();
  }

  OverlayEntry sortOverlayBuilder() {
    Icon checkedIcon = Icon(Icons.done);
    return OverlayEntry(builder: (context) {
      return Positioned(
        top: sortButtonPosition.dy + sortButtonSize.height,
        left: sortButtonPosition.dx,
        width: getScreenWidth(context),
        child: Material(
          color: Colors.transparent,
          child: SizeTransition(
            child: Container(
              decoration: BoxDecoration(
                color: CustomColors.colorPrimary,
              ),
              child: ListView(
                shrinkWrap: true,
                children: <Widget>[
                  ListTile(
                    leading: Icon(Icons.thumb_up),
                    title: Text(Strings.sortRecommended),
                    trailing: currentSortMethod == SORT_RECOMMENDED ? checkedIcon : null,
                    onTap: () => handleSortListItemClick(SORT_RECOMMENDED),
                  ),
                  ListTile(
                    leading: Icon(Icons.timer),
                    title: Text(Strings.sortTime),
                    trailing: currentSortMethod == SORT_TIME ? checkedIcon : null,
                    onTap: () => handleSortListItemClick(SORT_TIME),
                  ),
                  ListTile(
                    leading: Icon(Icons.arrow_downward),
                    title: Text(Strings.sortPriceHighLow),
                    trailing: currentSortMethod == SORT_PRICE_HIGH_LOW ? checkedIcon : null,
                    onTap: () => handleSortListItemClick(SORT_PRICE_HIGH_LOW),
                  ),
                  ListTile(
                    leading: Icon(Icons.arrow_upward),
                    title: Text(Strings.sortPriceLowHigh),
                    trailing: currentSortMethod == SORT_PRICE_LOW_HIGH ? checkedIcon : null,
                    onTap: () => handleSortListItemClick(SORT_PRICE_LOW_HIGH),
                  ),
                ],
              ),
            ),
            sizeFactor: CurvedAnimation(
              curve: AnimInfo.expandingHeightCurve,
              parent: _sortController,
            ),
          ),
        ),
      );
    });
  }

  OverlayEntry filterOverlayBuilder() {
    return OverlayEntry(
      builder: (context) {
        return FilterOverlayEntry(
          buttonSize: filterButtonSize,
          buttonPosition: filterButtonPosition,
          controller: _filterController,
        );
      },
      maintainState: false,
    );
  }


  void handleSortListItemClick(String sortType) {
    currentSortMethod = sortType;
    closeSortMenu();
  }
}