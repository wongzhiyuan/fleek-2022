import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fleek/dataclasses/PProduct.dart';
import 'package:fleek/dataclasses/Product.dart';
import 'package:fleek/global/globalFunctions.dart';
import 'package:fleek/global/globalItems.dart';
import 'package:fleek/values/dimens.dart';
import 'package:fleek/values/ints.dart';
import 'package:fleek/values/styles.dart';
import 'package:fleek/widgetClasses/DefaultImageFile.dart';
import 'package:fleek/widgetClasses/DefaultImageNetwork.dart';
import 'package:flutter/material.dart';
import 'package:flutter_swiper/flutter_swiper.dart';
import 'package:parse_server_sdk/parse_server_sdk.dart';
import 'package:swipe_stack/swipe_stack.dart';

class DiscoverSwipeWidget extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final firstProduct = intentMap[INTENT_SWIPE] as PProduct;
    final style = (firstProduct.styles.isNotEmpty) ? firstProduct.styles.first : "";
    var displayList = getRecommendedProductList(getRecommendedProductMap(currentFilters, [firstProduct.type], style));
    displayList = displayList.sublist(0, min(displayList.length, Ints.discoverSwipeMaxCards));
    displayList.remove(firstProduct);
    displayList.add(firstProduct);

    List<String> likedProducts = [];
    List<String> dislikedProducts = [];

    return WillPopScope(
      onWillPop: () async {
        handleSwipeEnd(context, likedProducts, dislikedProducts);
        return true;
      },
      child: Scaffold(
        backgroundColor: Colors.white30,
        body: SwipeStack(
          maxAngle: 0,
          children: displayList.map((PProduct product) {
            return SwiperItem(
              builder: (SwiperPosition position, double progress) {
                var imageList = product.images;
                final paddingText = EdgeInsets.all(Dimens.paddingDiscoverSwipeText);
                return Material(
                  elevation: 4,
                  borderRadius: BorderRadius.all(Radius.circular(6)),
                  child: ConstrainedBox(
                    constraints: BoxConstraints.expand(),
                    child: Column(
                      children: <Widget>[
                        Container(
                          height: getScreenHeight(context)/2,
                          child: Swiper(
                            itemCount: imageList.length,
                            itemBuilder: (context, index) {
                              return DefaultImageNetwork(
                                image: imageList[index].url,
                                fit: BoxFit.cover,
                              );
                            },
                            pagination: new SwiperPagination(),
                            autoplay: true,
                          ),
                        ),
                        Expanded(
                          child: ListView(
                            shrinkWrap: true,
                            children: <Widget>[
                              Padding(
                                padding: paddingText,
                                child: Align(
                                  alignment: Alignment.center,
                                  child: Text(product.title, style: Styles.listHeader,),
                                ),
                              ),

                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                );
              },
            );
          }).toList(),
          visibleCount: displayList.length,
          stackFrom: StackFrom.Top,
          translationInterval: 0,
          scaleInterval: 0,
          onEnd: () => handleSwipeEnd(context, likedProducts, dislikedProducts),
          onSwipe: (int index, SwiperPosition position) {
            String swipedProductId = displayList[index].id;

            switch (position) {
              case SwiperPosition.None:
                break;
              case SwiperPosition.Left:
                dislikedProducts.add(swipedProductId);
                break;
              case SwiperPosition.Right:
                likedProducts.add(swipedProductId);
                break;
            }
          },
        ),
      ),
    );
  }

  void handleSwipeEnd(BuildContext context, List<String> liked, List<String> disliked) async {
    //TODO: update most recent type and style
    Navigator.pop(context);

    void addUserUid(String id) async {
      ParseObject object = new ParseObject(OBJECT_SHOP)
          ..objectId = id
          ..setAddUnique(SHOP_LIKED_BY_LIST, currentParseUserUid);
      var response = await object.save();
      if (!response.success) print(response.error);
    }
    liked.forEach(addUserUid);

    /*
    var batch = db.batch();
    Map<String, dynamic> shopUpdateMap = {
      SHOP_LIKED_BY_LIST : FieldValue.arrayUnion([currentUserUid]),
    };

    for (String id in liked) {
      batch.updateData(shopRef.document(id), shopUpdateMap);
    }

    batch.commit().whenComplete(() {
      DocumentReference userRef = userCollectionRef.document(currentUserUid);
      Map<String, dynamic> userUpdateMap = {
        USER_LIKED_PRODUCTS : FieldValue.arrayUnion(liked),
        USER_DISLIKED_PRODUCTS : FieldValue.arrayUnion(disliked),
      };
      userRef.updateData(userUpdateMap);
    });
     */

  }
  
}