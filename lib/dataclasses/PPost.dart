import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fleek/global/globalFunctions.dart';
import 'package:fleek/global/globalItems.dart';
import 'package:parse_server_sdk/parse_server_sdk.dart';

class PPost {
  String id = "";
  String author = "";
  String title = "";
  int timestamp = Timestamp.now().millisecondsSinceEpoch;
  ParseFile image;
  List<String> likedBy = List(0);
  String type = "";
  List<String> hashtagIDs = [];
  List<String> styles = [];

  PPost();

  void init(
  String id,
  String author,
  String title,
  int timestamp,
  ParseFile image,
  List<String> likedBy,
  String type,
  List<String> hashtagIDs,
  List<String> styles,
  ) {
    this.id = id;
    this.author = author;
    this.title = title;
    this.timestamp = timestamp;
    this.image = image;
    this.likedBy = likedBy;
    this.type = type;
    this.hashtagIDs = hashtagIDs;
    this.styles = styles;
  }
  
  PPost fromMap(Map<String, dynamic> map) {
    PPost post = PPost();
    post.init(
      map[SOCIAL_POST_ID].toString(),
      map[SOCIAL_USER_UID].toString(),
      map[SOCIAL_TITLE].toString(),
      int.parse(map[SOCIAL_TIMESTAMP].toString()),
      new ParseFile(File(getTempImgPath())).fromJson(
          new Map<String, dynamic>.from(map[SOCIAL_IMAGE_URI])
      ) as ParseFile,
      new List<String>.from(map[SOCIAL_LIKED_BY]),
      map[SOCIAL_TYPE].toString(),
      new List<String>.from(map[SOCIAL_HASHTAGS_LIST]),
      new List<String>.from(map[SOCIAL_STYLES_LIST]),
    );
    return post;
  }
  
  Map<String, dynamic> toMap() {
    return {
      SOCIAL_POST_ID : this.id,
      SOCIAL_USER_UID : this.author,
      SOCIAL_TITLE : this.title,
      SOCIAL_TIMESTAMP : this.timestamp,
      SOCIAL_IMAGE_URI : this.image,
      SOCIAL_LIKED_BY : this.likedBy,
      SOCIAL_TYPE : this.type,
      SOCIAL_HASHTAGS_LIST : this.hashtagIDs,
      SOCIAL_STYLES_LIST : this.styles,
    };
  }
}