import 'package:fleek/global/globalItems.dart';

class User {
  String id = "";
  String displayName = "";
  String profilePictureUri = "";
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

  User();

  void init(
    String id,
    String displayName,
    String profilePictureUri,
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
  ) {
    this.id = id;
    this.displayName = displayName;
    this.profilePictureUri = profilePictureUri;
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
  }
  
  User fromMap(Map<String, dynamic> map) {
    User user = User();

    user.init(
      map[USER_USER_UID].toString(),
      map[USER_DISPLAY_NAME].toString(),
      map[USER_PROFILE_PICTURE_URI].toString(),
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
    );
    return user;
  }

  Map<String, dynamic> toMap() {
    return {
      USER_USER_UID : this.id,
      USER_DISPLAY_NAME : this.displayName,
      USER_PROFILE_PICTURE_URI : this.profilePictureUri,
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
    };
  }
}