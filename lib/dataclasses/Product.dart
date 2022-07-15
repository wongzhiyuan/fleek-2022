import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fleek/global/globalItems.dart';
import 'package:parse_server_sdk/parse_server_sdk.dart';

class Product {
  String id = "";
  String title = "";
  String buyer = "";
  String seller = "";
  double price = 0.0;
  String description = "";
  String coverImageUri = "";
  List<String> imageUris = List(0);
  List<String> imageUUIDs = List(0);
  String cat = "";
  String type = "";
  List<String> styles = List(0);
  List<String> likedBy = List(0);
  bool isReserved = false;
  bool isSold = false;
  int timestamp = Timestamp.now().millisecondsSinceEpoch;
  String gender = "";
  String itemCondition = "";
  String size = "";

  Product();

  void init(String id,
    String title,
    String buyer,
    String seller,
    double price,
    String description,
    String coverImageUri,
    List<String> imageUris,
    List<String> imageUUIDs,
    String cat,
    String type,
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
    this.coverImageUri = coverImageUri;
    this.imageUris = imageUris;
    this.imageUUIDs = imageUUIDs;
    this.cat = cat;
    this.type = type;
    this.styles = styles;
    this.likedBy = likedBy;
    this.isReserved = isReserved;
    this.isSold = isSold;
    this.timestamp = timestamp;
    this.gender = gender;
    this.itemCondition = itemCondition;
    this.size = size;
  }

  Product fromMap(Map<String, dynamic> map) {
    Product product = Product();
    product.init(
      map[SHOP_ITEM_ID].toString(),
      map[SHOP_TITLE].toString(),
      map[SHOP_BUYER].toString(),
      map[SHOP_SELLER].toString(),
      double.parse(map[SHOP_PRICE].toString()),
      map[SHOP_DESCRIPTION].toString(),
      map[SHOP_COVER_IMAGE_URI].toString(),
      new List<String>.from(map[SHOP_IMAGE_URI_LIST]),
      new List<String>.from(map[SHOP_IMAGE_UUID_LIST]),
      map[SHOP_CAT].toString(),
      map[SHOP_TYPE].toString(),
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
      SHOP_COVER_IMAGE_URI: this.coverImageUri,
      SHOP_IMAGE_URI_LIST: this.imageUris,
      SHOP_IMAGE_UUID_LIST: this.imageUUIDs,
      SHOP_CAT: this.cat,
      SHOP_TYPE: this.type,
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