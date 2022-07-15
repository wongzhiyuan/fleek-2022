import 'dart:io';

import 'package:fleek/global/globalFunctions.dart';
import 'package:fleek/global/globalItems.dart';
import 'package:parse_server_sdk/parse_server_sdk.dart';

class PUser {
  String id = "";
  String displayName = "";
  ParseFile profilePicture;
  String bio = "";
  List<String> selling = List();
  List<String> posted = List();
  List<String> likedPosts = List();
  List<String> likedProducts = List();
  List<String> dislikedProducts = List();
  String mostRecentType = "";
  String mostRecentStyle = "";
  List<String> bought = List();
  List<String> sold = List();
  List<String> followers = List();
  List<String> following = List();
  List<String> buyingChats = [];
  List<String> sellingChats = [];

  PUser();

  void init(
    String id,
    String displayName,
    ParseFile profilePicture,
    String bio,
    List<String> selling,
    List<String> posted,
    List<String> likedPosts,
    List<String> likedProducts,
    List<String> dislikedProducts,
    String mostRecentType,
    String mostRecentStyle,
    List<String> bought,
    List<String> sold,
    List<String> followers,
    List<String> following,
    List<String> buyingChats,
    List<String> sellingChats,
  ) {
    this.id = id;
    this.displayName = displayName;
    this.profilePicture = profilePicture;
    this.bio = bio;
    this.selling = selling;
    this.posted = posted;
    this.likedPosts = likedPosts;
    this.likedProducts = likedProducts;
    this.dislikedProducts = dislikedProducts;
    this.mostRecentType = mostRecentType;
    this.mostRecentStyle = mostRecentStyle;
    this.bought = bought;
    this.sold = sold;
    this.followers = followers;
    this.following = following;
    this.buyingChats = buyingChats;
    this.sellingChats = sellingChats;
  }
  
  PUser fromMap(Map<String, dynamic> map) {
    PUser user = PUser();

    user.init(
      map[USER_USER_UID].toString(),
      map[USER_DISPLAY_NAME].toString(),
      new ParseFile(File(getTempImgPath())).fromJson(
          new Map<String, dynamic>.from(map[USER_PROFILE_PICTURE_URI])
      ) as ParseFile,
      map[USER_BIO].toString(),
      new List<String>.from(map[USER_SELLING]),
      new List<String>.from(map[USER_POSTED]),
      new List<String>.from(map[USER_LIKED_POSTS]),
      new List<String>.from(map[USER_LIKED_PRODUCTS]),
      new List<String>.from(map[USER_DISLIKED_PRODUCTS]),
      map[USER_MOST_RECENT_TYPE].toString(),
      map[USER_MOST_RECENT_STYLE].toString(),
      new List<String>.from(map[USER_BOUGHT]),
      new List<String>.from(map[USER_SOLD]),
      new List<String>.from(map[USER_FOLLOWERS]),
      new List<String>.from(map[USER_FOLLOWING]),
      new List<String>.from(map[USER_BUYING_CHATS]),
      new List<String>.from(map[USER_SELLING_CHATS]),
    );
    return user;
  }

  Map<String, dynamic> toMap() {
    return {
      USER_USER_UID : this.id,
      USER_DISPLAY_NAME : this.displayName,
      USER_PROFILE_PICTURE_URI : this.profilePicture,
      USER_BIO : this.bio,
      USER_SELLING : this.selling,
      USER_POSTED : this.posted,
      USER_LIKED_POSTS : this.likedPosts,
      USER_LIKED_PRODUCTS : this.likedProducts,
      USER_DISLIKED_PRODUCTS : this.dislikedProducts,
      USER_MOST_RECENT_TYPE : this.mostRecentType,
      USER_MOST_RECENT_STYLE : this.mostRecentStyle,
      USER_BOUGHT : this.bought,
      USER_SOLD : this.sold,
      USER_FOLLOWERS : this.followers,
      USER_FOLLOWING : this.following,
      USER_BUYING_CHATS : this.buyingChats,
      USER_SELLING_CHATS : this.sellingChats,
    };
  }
}