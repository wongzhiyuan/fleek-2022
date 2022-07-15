import 'package:fleek/dataclasses/Filter.dart';
import 'package:fleek/global/globalFunctions.dart';
import 'package:fleek/global/globalItems.dart';
import 'package:fleek/values/colors.dart';
import 'package:fleek/values/animInfo.dart';
import 'package:fleek/values/strings.dart';
import 'package:flutter/material.dart';

class FilterOverlayEntry extends StatefulWidget {
  final Size buttonSize;
  final Offset buttonPosition;
  final AnimationController controller;

  FilterOverlayEntry({
    this.buttonSize,
    this.buttonPosition,
    this.controller,
  });

  _FilterOverlayEntryState createState() => _FilterOverlayEntryState();
}

class _FilterOverlayEntryState extends State<FilterOverlayEntry> with TickerProviderStateMixin {
  Map<String, Map<String, bool>> filterMap = Map();
  Size filterButtonSize;
  Offset filterButtonPosition;
  AnimationController _controller;

  @override
  void initState() {
    super.initState();

    _controller = widget.controller;
    filterButtonSize = widget.buttonSize;
    filterButtonPosition = widget.buttonPosition;
  }

  @override
  Widget build(BuildContext context) {
    List<String> sizesList = [];
    List<String> conditionsList = [];

    if (defaultSettings.isDownloaded) {
      sizesList = defaultSettings.sizes;
      conditionsList = defaultSettings.productConditions;
    }
    else {
      sizesList = defaultSizes;
      conditionsList = defaultProductConditions;
    }

    filterMap[FILTER_GENDER] = {};
    filterSetCheck(FILTER_GENDER, FILTER_GENDER_MALE);
    filterSetCheck(FILTER_GENDER, FILTER_GENDER_FEMALE);

    filterMap[FILTER_SIZE] = {};
    for (String size in sizesList) {
      filterSetCheck(FILTER_SIZE, size);
    }

    filterMap[FILTER_CONDITION] = {};
    for(String condition in conditionsList) {
      filterSetCheck(FILTER_CONDITION, condition);
    }

    print(filterMap);
    Icon checkedIcon = Icon(Icons.done);

    return Positioned(
      top: filterButtonPosition.dy + filterButtonSize.height,
      left: 0,
      width: getScreenWidth(context),
      child: Material(
        color: Colors.transparent,
        child: SizeTransition(
          sizeFactor: CurvedAnimation(
            curve: AnimInfo.expandingHeightCurve,
            parent: _controller,
          ),
          child: Container(
            decoration: BoxDecoration(
              color: CustomColors.colorPrimary,
            ),
            child: ListView(
              shrinkWrap: true,
              children: <Widget>[
                ExpansionTile(
                  leading: Icon(Icons.accessibility),
                  title: Text(Strings.filterGender),
                  children: <Widget>[
                    ListTile(
                      title: Text(Strings.filterGenderMale),
                      trailing: filterMap[FILTER_GENDER][FILTER_GENDER_MALE] ? checkedIcon : null,
                      onTap: () => handleFilterListItemClick(FILTER_GENDER, FILTER_GENDER_MALE),
                    ),
                    ListTile(
                      title: Text(Strings.filterGenderFemale),
                      trailing: filterMap[FILTER_GENDER][FILTER_GENDER_FEMALE] ? checkedIcon : null,
                      onTap: () => handleFilterListItemClick(FILTER_GENDER, FILTER_GENDER_FEMALE),
                    ),
                  ],
                ),
                ExpansionTile(
                    leading: Icon(Icons.shop_two),
                    title: Text(Strings.filterSize),
                    children: List.generate(sizesList.length, (index) {
                      var currentSize = sizesList[index];
                      return ListTile(
                        title: Text(currentSize),
                        trailing: filterMap[FILTER_SIZE][currentSize] ? checkedIcon : null,
                        onTap: () => handleFilterListItemClick(FILTER_SIZE, currentSize),
                      );
                    })
                ),
                ExpansionTile(
                    leading: Icon(Icons.content_cut),
                    title: Text(Strings.filterCondition),
                    children: List.generate(conditionsList.length, (index) {
                      var currentCondition = conditionsList[index];
                      return ListTile(
                        title: Text(currentCondition),
                        trailing: filterMap[FILTER_CONDITION][currentCondition] ? checkedIcon : null,
                        onTap: () => handleFilterListItemClick(FILTER_CONDITION, currentCondition),
                      );
                    })
                ),
              ],
            ),
          ),
        ),

      ),
    );
  }

  void filterSetCheck(String filterGroup, String filterType) {
    setState(() {
      if (!currentFilters.containsKey(filterGroup)) filterMap[filterGroup][filterType] = false;
      else filterMap[filterGroup][filterType] = currentFilters[filterGroup].values.contains(filterType);
    });
  }

  void handleFilterListItemClick(String filterGroup, String filterType) {
    if (currentFilters.containsKey(filterGroup)) {
      if (currentFilters[filterGroup].values.contains(filterType)) {
        currentFilters[filterGroup].values.remove(filterType);
      }
      else currentFilters[filterGroup].values.add(filterType);
    }
    else {
      Filter newFilter = Filter(filterGroup);
      newFilter.values.add(filterType);

      currentFilters[filterGroup] = newFilter;
    }

    filterSetCheck(filterGroup, filterType);
    print(currentFilters[filterGroup].values);
    print(filterMap[filterGroup][filterType]);
  }

}