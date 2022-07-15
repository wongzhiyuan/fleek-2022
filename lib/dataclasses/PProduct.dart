import 'dart:io';
import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fleek/global/globalFunctions.dart';
import 'package:fleek/global/globalItems.dart';
import 'package:parse_server_sdk/parse_server_sdk.dart';

class PProduct {
  String id = "";
  String title = "";
  String buyer = "";
  String seller = "";
  double price = 0.0;
  String description = "";
  List<ParseFile> images = List(0);
  String cat = "";
  String type = "";
  List<String> hashtagIDs = [];
  List<String> styles = List(0);
  List<String> likedBy = List(0);
  bool isReserved = false;
  bool isSold = false;
  int timestamp = Timestamp.now().millisecondsSinceEpoch;
  String gender = "";
  String itemCondition = "";
  String size = "";

  PProduct();

  void init(String id,
    String title,
    String buyer,
    String seller,
    double price,
    String description,
    List<ParseFile> images,
    String cat,
    String type,
    List<String> hashtagIDs,
    List<String> styles,
    List<String> likedBy,
    bool isReserved,
    bool isSold,
    int timestamp,
    String gender,
    String itemCondition,
    String size,
  ) {
    this.id = id;
    this.title = title;
    this.buyer = buyer;
    this.seller = seller;
    this.price = price;
    this.description = description;
    this.images = images;
    this.cat = cat;
    this.type = type;
    this.hashtagIDs = hashtagIDs;
    this.styles = styles;
    this.likedBy = likedBy;
    this.isReserved = isReserved;
    this.isSold = isSold;
    this.timestamp = timestamp;
    this.gender = gender;
    this.itemCondition = itemCondition;
    this.size = size;
  }

  PProduct fromMap(Map<String, dynamic> map) {
    List<dynamic> rawImageList = map[SHOP_IMAGE_URI_LIST];
    List<ParseFile> imageList = [];
    tempImgPath = getTempImgPath();
    rawImageList.forEach((json) {
      final parseFile = new ParseFile(File(tempImgPath)).fromJson(json) as ParseFile;
      imageList.add(parseFile);
    });
    
    PProduct product = PProduct();
    product.init(
      map[SHOP_ITEM_ID].toString(),
      map[SHOP_TITLE].toString(),
      map[SHOP_BUYER].toString(),
      map[SHOP_SELLER].toString(),
      double.parse(map[SHOP_PRICE].toString()),
      map[SHOP_DESCRIPTION].toString(),
      imageList,
      map[SHOP_CAT].toString(),
      map[SHOP_TYPE].toString(),
      new List<String>.from(map[SHOP_HASHTAGS_LIST]),
      new List<String>.from(map[SHOP_STYLES_LIST]),
      new List<String>.from(map[SHOP_LIKED_BY_LIST]),
      map[SHOP_IS_RESERVED] as bool,
      map[SHOP_IS_SOLD] as bool,
      int.parse(map[SHOP_TIMESTAMP].toString()),
      map[SHOP_GENDER].toString(),
      map[SHOP_ITEM_CONDITION].toString(),
      map[SHOP_SIZE].toString(),
    );
    return product;
  }
  
  Map<String, dynamic> toMap() {
    return {
      SHOP_ITEM_ID: this.id,
      SHOP_TITLE: this.title,
      SHOP_SELLER: this.seller,
      SHOP_PRICE: this.price,
      SHOP_DESCRIPTION: this.description,
      SHOP_IMAGE_URI_LIST: this.images,
      SHOP_CAT: this.cat,
      SHOP_TYPE: this.type,
      SHOP_HASHTAGS_LIST : this.hashtagIDs,
      SHOP_STYLES_LIST: this.styles,
      SHOP_LIKED_BY_LIST: this.likedBy,
      SHOP_IS_RESERVED: this.isReserved,
      SHOP_IS_SOLD: this.isSold,
      SHOP_TIMESTAMP: this.timestamp,
      SHOP_GENDER: this.gender,
      SHOP_ITEM_CONDITION: this.itemCondition,
      SHOP_SIZE: this.size,
    };
  }
}