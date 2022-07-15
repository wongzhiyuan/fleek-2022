import 'package:fleek/global/globalFunctions.dart';
import 'package:fleek/global/globalItems.dart';
import 'package:fleek/values/dimens.dart';
import 'package:fleek/values/styles.dart';
import 'package:fleek/widgetClasses/DefaultImageNetwork.dart';
import 'package:flutter/material.dart';

import 'DiscoverBrowseWidget.dart';

class DiscoverSeeAllWidget extends StatelessWidget {
  final seeAllType;
  final gender;

  DiscoverSeeAllWidget({this.seeAllType, this.gender});

  @override
  Widget build(BuildContext context) {
    final labelStyle = Styles.smallLabel;
    final paddingSeeAll = Dimens.paddingDiscoverSeeAllAround;
    final gridWidth = (getScreenWidth(context) - 3 * paddingSeeAll) / 2;
    final gridHeight = gridWidth + paddingSeeAll + labelStyle.fontSize;
    final childAspectRatio = gridWidth/gridHeight;

    String header = "All ";
    Map<String, String> displayMap = Map();

    void catHandler(String cat, List<String> subCats) => subCats.forEach((cat) => displayMap[cat] = defaultSettings.types[cat]);
    switch (seeAllType) {
      case (INTENT_SEE_ALL_TYPES): {
        header += "$gender Categories";
        if (gender == FILTER_GENDER_MALE) defaultSettings.mCats.forEach(catHandler);
        else if (gender == FILTER_GENDER_FEMALE) defaultSettings.fCats.forEach(catHandler);
        else if (gender == FILTER_GENDER_BOTH) displayMap = defaultSettings.types;
      }
      break;

      case (INTENT_SEE_ALL_STYLES): {
        header += "Styles";
        displayMap = defaultSettings.styles;
      }
      break;

      default: {
        print("see all intent error");
      }
      break;
    }

    List<String> displayList = new List<String>.from(displayMap.keys);
    displayList.sort();
    return Scaffold(
      appBar: AppBar(
        title: Text(header, style: Styles.listHeader,),
      ),
      body: Padding(
        padding: EdgeInsets.all(paddingSeeAll),
        child: GridView.builder(
          shrinkWrap: true,
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: paddingSeeAll,
            mainAxisSpacing: paddingSeeAll,
            childAspectRatio: childAspectRatio,
          ),
          itemCount: displayMap.length,
          itemBuilder: (context, index) {
            final String currentItem = displayList[index];

            return InkWell(
              onTap: () {
                Navigator.push(context, MaterialPageRoute(builder: (context) => DiscoverBrowseWidget(
                  query: currentItem,
                  queryType: seeAllType,
                  gender: gender,
                )));
              },
              child: Column(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.start,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: <Widget>[
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8.0),
                    child: DefaultImageNetwork(
                      image: displayMap[currentItem],
                      width: gridWidth,
                      height: gridWidth,
                      fit: BoxFit.cover,
                    ),
                  ),
                  Padding(
                    padding: EdgeInsets.only(top: paddingSeeAll),
                    child: Text(
                      currentItem,
                      style: labelStyle,
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}