import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fleek/global/globalItems.dart';

class Post {
  String id = "";
  String author = "";
  String title = "";
  int timestamp = Timestamp.now().millisecondsSinceEpoch;
  String imageUri = "";
  String imageUUID = "";
  List<String> likedBy = List(0);
  String type = "";
  List<String> styles = [];

  Post();

  void init(
  String id,
  String author,
  String title,
  int timestamp,
  String imageUri,
  String imageUUID,
  List<String> likedBy,
  String type,
  List<String> styles
  ) {
    this.id = id;
    this.author = author;
    this.title = title;
    this.timestamp = timestamp;
    this.imageUri = imageUri;
    this.imageUUID = imageUUID;
    this.likedBy = likedBy;
    this.type = type;
    this.styles = styles;
  }
  
  Post fromMap(Map<String, dynamic> map) {
    Post post = Post();
    post.init(
      map[SOCIAL_POST_ID].toString(),
      map[SOCIAL_USER_UID].toString(),
      map[SOCIAL_TITLE].toString(),
      int.parse(map[SOCIAL_TIMESTAMP].toString()),
      map[SOCIAL_IMAGE_URI].toString(),
      map[SOCIAL_IMAGE_UUID].toString(),
      new List<String>.from(map[SOCIAL_LIKED_BY]),
      map[SOCIAL_TYPE].toString(),
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
      SOCIAL_IMAGE_URI : this.imageUri,
      SOCIAL_IMAGE_UUID : this.imageUUID,
      SOCIAL_LIKED_BY : this.likedBy,
      SOCIAL_TYPE : this.type,
      SOCIAL_STYLES_LIST : this.styles,
    };
  }
}