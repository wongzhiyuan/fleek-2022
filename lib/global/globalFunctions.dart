import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fleek/chat/ChatWidget.dart';
import 'package:fleek/dataclasses/Filter.dart';
import 'package:fleek/dataclasses/Hashtag.dart';
import 'package:fleek/dataclasses/Message.dart';
import 'package:fleek/dataclasses/PPost.dart';
import 'package:fleek/dataclasses/PProduct.dart';
import 'package:fleek/dataclasses/PUser.dart';
import 'package:fleek/dataclasses/ProductDefaultSettings.dart';
import 'package:fleek/dataclasses/QueryResult.dart';
import 'package:fleek/dataclasses/Review.dart';
import 'package:fleek/discoverExtras/DiscoverSwipeWidget.dart';
import 'package:fleek/values/styles.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:intl/intl.dart';
import 'package:parse_server_sdk/parse_server_sdk.dart';
import 'package:path_provider/path_provider.dart';
import 'package:progress_dialog/progress_dialog.dart';
import 'package:http/http.dart' as http;

import 'globalItems.dart';

//parse init
Future<void> parseInit() async {
  //initialise parse
  await Parse().initialize(
    appId, serverURL,
    clientKey: clientKey,
    liveQueryUrl: liveQueryURL,
    autoSendSessionId: true,
    coreStore: await CoreStoreSembastImp.getInstance(),
  );
  isParseInit = true;

  await parseRefreshUser();
  //await updateDefaultSettings();
  getDefaultSettings();
  registerAllMessageDumpListeners();

  //LiveQuery setup
  liveQuery = LiveQuery();
}

Future<void> parseRefreshUser() async {
  currentParseUser = await ParseUser.currentUser();
  currentParseUserUid = (currentParseUser != null) ? currentParseUser.objectId : "";

  aParseUserChanged.add(currentParseUser);
  print("parse user uid: " + currentParseUserUid);
}

//PDS
Future<void> getDefaultSettings() async {
  var response = await QueryBuilder<ParseObject>(ParseObject(OBJECT_PRODUCT_DEFAULT_SETTINGS)).query();
  var obj = (response.success) ? response.results.first as ParseObject : new ParseObject(OBJECT_PRODUCT_DEFAULT_SETTINGS);

  print(obj.toString());
  defaultSettings = ProductDefaultSettings().fromMap(jsonDecode(obj.toString()));
}

Future<void> updateDefaultSettings() async {
  ProductDefaultSettings settings = ProductDefaultSettings()..init(
      defaultStyles,
      defaultTypes,
      defaultMCats,
      defaultFCats,
      defaultSizes,
      defaultProductConditions
  );

  var obj = objFromMap(
    new ParseObject(OBJECT_PRODUCT_DEFAULT_SETTINGS),
    settings.toMap(),
  );
  await obj.create().then(parseSaveCallback);
}

//Update Hashtags
List<String> handleHashtagList(List<Hashtag> list) {
  List<String> idList = [];
  list.forEach((hashtag) => idList.add(hashtag.objectId));
  list.forEach((hashtag) async {
    final id = hashtag.objectId;
    if (hashtagsDB.containsKey(id)) {
      //existing object
      var object = ParseObject(OBJECT_HASHTAG)
        ..objectId = id
        ..setIncrement(HASHTAG_COUNT, 1);
      await object.save().then(parseSaveCallback);
    }
    else {
      //new object
      if (hashtag.count == 0) hashtag.count++;
      await objFromMap(new ParseObject(OBJECT_HASHTAG), hashtag.toMap()).create().then(parseSaveCallback);
    }
  });
  
  return idList;
}

//ParseObject from map
ParseObject objFromMap(ParseObject object, Map<String, dynamic> map, {String objectId, String setType = SET_SET}) {
  if (objectId != null) object.objectId = objectId;

  print(object.objectId);

  map.forEach((key, value) {
    var setValue = parseDecode(value);
    switch (setType) {
      case (SET_SET): object.set(key, setValue);
      break;
      case (SET_ADD): object.setAdd(key, setValue);
      break;
      case (SET_ADD_UNIQUE): object.setAddUnique(key, setValue);
      break;
      case (SET_REMOVE): object.setRemove(key, setValue);
      break;
    }
  });

  return object;
}

ParseUser userFromMap(ParseUser user, Map<String, dynamic> map, {String setType = SET_SET}) {
  map.forEach((key, value) {
    var setValue = parseDecode(value);
    switch (setType) {
      case (SET_SET): user.set(key, setValue);
      break;
      case (SET_ADD): user.setAdd(key, setValue);
      break;
      case (SET_ADD_UNIQUE): user.setAddUnique(key, setValue);
      break;
      case (SET_REMOVE): user.setRemove(key, setValue);
      break;
    }
  });

  return user;
}

//Common Parse Queries
QueryBuilder<ParseObject> infoFileQuery(String name) => QueryBuilder<ParseObject>(ParseObject(OBJECT_INFO))
    ..whereEqualTo(INFO_NAME, name);

Future<QueryResult> getInfoFileObject(String name) async {
  ParseObject obj;

  var response = await infoFileQuery(name).query();
  if (response.success) obj = (response.results.first) as ParseObject;
  else print(response.error);

  return new QueryResult(
    object: obj,
    success: response.success,
  );
}

QueryBuilder<ParseObject> userDataQuery(String userUid) => QueryBuilder<ParseObject>(ParseObject(OBJECT_USER_DATA))
  ..whereEqualTo(USER_USER_UID, userUid);
Future<QueryResult> getUserDataObject(String userUid) async {
  ParseObject obj;

  var response = await userDataQuery(currentParseUserUid).query();
  if (response.success) obj = response.results.first;
  else print(response.error);

  return new QueryResult(
    object: obj,
    success: response.success,
  );
}

QueryBuilder<ParseObject> allHashtagsQuery() => QueryBuilder<ParseObject>(ParseObject(OBJECT_HASHTAG));
QueryBuilder<ParseObject> hashTagSearch(String search) => allHashtagsQuery()
  ..whereContains(HASHTAG_NAME, search);
Future<Map<String, Hashtag>> getHashtags({String search}) async {
  final query = (search != null) ? hashTagSearch(search) : allHashtagsQuery();
  var response = await query.query();

  Map<String, Hashtag> returnMap = {};
  if (response.success && response.results != null) {
    response.results.forEach((obj) {
      final hashtag = Hashtag().fromObject(obj);
      print("hashtag with id ${hashtag.objectId} downloaded");
      returnMap[hashtag.objectId] = hashtag;
    });
    aInitialDownloaded.add(HASHTAG);
  } else print("hashtag download error: ${response.error}");

  return returnMap;
}

void parseSaveCallback(ParseResponse response) => print(
    (response.success) ? "parse save success with results ${response.results}" : response.error
);

//return google auth data object
Map<String, dynamic> googleAuthData(GoogleSignInAccount googleUser, GoogleSignInAuthentication googleAuth) {
  return {
    "id": googleUser.id,
    "id_token": googleAuth.idToken,
    "access_token": googleAuth.accessToken
  };
}

//interval auth checker
/*
void intervalRefreshAuth(int interval) async {
  Timer timer;
  !(await reloadUser())
      ? timer = Timer(Duration(seconds: interval), () => intervalRefreshAuth(interval))
      : timer?.cancel();
}

Future<bool> reloadUser() async {
  await currentUser.reload();
  currentUser = await FirebaseAuth.instance.currentUser();
  currentUserUid = currentUser.uid;
  if (currentUser.isEmailVerified) {
    localSettings.emailVerified = true;
    aEmailVerified.add(true);
    return true;
  }

  return false;
}

 */

//background notif handler
Future<dynamic> backgroundMessageHandler(Map<String, dynamic> message) {
  print("background: $message");

  if (message.containsKey('data')) {
    // Handle data message
    final dynamic data = message['data'];
  }

  if (message.containsKey('notification')) {
    // Handle notification message
    final dynamic notification = message['notification'];
  }
  // Or do other work.
}

void showMessageNotif(Map<String, dynamic> message) {

}

void navigateToChat(BuildContext context, dynamic data) {
  var navMap = new Map<String, String>.from(data);

  final String messageDumpUuid = navMap[CHAT_MESSAGE_DUMP];

  Navigator.push(context, MaterialPageRoute(
    builder: (context) => ChatWidget(
      messageDumpUuid: messageDumpUuid,
    ),
  ));
}

//make material color swatch
MaterialColor createMaterialColor(Color color) {
  List strengths = <double>[.05];
  Map swatch = <int, Color>{};
  final int r = color.red, g = color.green, b = color.blue;

  for (int i = 1; i < 10; i++) {
    strengths.add(0.1 * i);
  }
  strengths.forEach((strength) {
    final double ds = 0.5 - strength;
    swatch[(strength * 1000).round()] = Color.fromRGBO(
      r + ((ds < 0 ? r : (255 - r)) * ds).round(),
      g + ((ds < 0 ? g : (255 - g)) * ds).round(),
      b + ((ds < 0 ? b : (255 - b)) * ds).round(),
      1,
    );
  });
  return MaterialColor(color.value, swatch);
}

Future<Subscription<ParseObject>> registerHashtagsListener() async {
  print("hashtag listener starting");
  final query = allHashtagsQuery();
  Hashtag getHashtag(dynamic value) => new Hashtag().fromObject(value as ParseObject);

  void addUpdate(dynamic value) {
    final hashtag = getHashtag(value);
    final id = hashtag.objectId;
    hashtagsDB[id] = hashtag;
    aHashtagChanged.add(hashtag);
  }

  //first time
  hashtagsDB = await getHashtags();

  return await liveQuery.client.subscribe(query)
  ..on(LiveQueryEvent.create, addUpdate)
  ..on(LiveQueryEvent.update, addUpdate)
  ..on(LiveQueryEvent.delete, (value) => hashtagsDB.remove(getHashtag(value).objectId));
}

Future<Subscription<ParseObject>> registerShopListener() async {
  print("shop listener starting");
  final query = QueryBuilder<ParseObject>(ParseObject(OBJECT_SHOP));
  PProduct getProduct(ParseObject object) => PProduct().fromMap(jsonDecode(object.toString()));

  void addUpdate(dynamic value, StreamController controller) {
    print("shop adding/updating");
    final object = value as ParseObject;
    final id = object.objectId;

    PProduct product = getProduct(object);
    product.id = id;
    print("id: $id");
    parseShopCollection[id] = product;
    controller.add(id);
  }

  //first time
  var response = await query.query();
  print("response done");
  if (response.success && response.results != null) {
    response.results.forEach((result) => addUpdate(result, aShopAddId));
  }
  aInitialDownloaded.add(SHOP);

  print("response handling done");
  //for future events
  final sub = (await liveQuery.client.subscribe(query))
  ..on(LiveQueryEvent.create, (value) {
    addUpdate(value, aShopAddId);
  })
  ..on(LiveQueryEvent.update, (value) {
    addUpdate(value, aShopModifyId);
  })
  ..on(LiveQueryEvent.delete, (value) {
    final object = value as ParseObject;
    final id = object.objectId;
    parseShopCollection.remove(id);
    aShopDeleteId.add(id);
  });
  print("returning");
  return sub;
}

Future<Subscription<ParseObject>> registerSocialListener() async {
  print("social registered");
  final query = QueryBuilder<ParseObject>(ParseObject(OBJECT_SOCIAL));
  PPost getPost(ParseObject object) => PPost().fromMap(jsonDecode(object.toString()));

  void addUpdate(dynamic value, StreamController controller) {
    final object = value as ParseObject;
    final id = object.objectId;
    PPost post = getPost(object);
    post.id = id;
    parseSocialCollection[id] = post;
    controller.add(id);
    return;
  }

  //first time
  var response = await query.query();
  if (response.success && response.results != null) {
    response.results.forEach((result) => addUpdate(result, aSocialAddId));
  }
  else print(response.error);

  aInitialDownloaded.add(SOCIAL);

  //for future events
  final sub = (await liveQuery.client.subscribe(query))
    ..on(LiveQueryEvent.create, (value) {
      addUpdate(value, aSocialAddId);
    })
    ..on(LiveQueryEvent.update, (value) {
      addUpdate(value, aSocialModifyId);
    })
    ..on(LiveQueryEvent.delete, (value) {
      final object = value as ParseObject;
      final id = object.objectId;
      parseSocialCollection.remove(id);
      aSocialDeleteId.add(id);
    });
  return sub;
}

Future<Subscription<ParseObject>> registerUsersListener() async {
  final query = QueryBuilder<ParseObject>(ParseObject(OBJECT_USER_DATA));

  PUser getUser(ParseObject object) {
    Map<String, dynamic> map = jsonDecode(object.toString());
    return (map.containsKey(USER_PROFILE_PICTURE_URI)) ? PUser().fromMap(map) : new PUser();
  }

  void addUpdate(dynamic value, StreamController controller) {
    final object = value as ParseObject;
    final id = object.get(USER_USER_UID);

    final user = getUser(object);
    if (user.profilePicture == null) return;
    user.id = id;
    if (id == currentParseUserUid) {
      currentParseUserCollection = user;
      aUserCollectionModified.add(Random().nextInt(9999999));
    }
    parseUsersCollection[id] = user;

    takenDisplayNames[id] = user.displayName;
    controller.add(id);
    return;
  }

  //first time
  var response = await query.query();
  print(response.error);
  if (response.success && response.results != null) {
    response.results.forEach((result) => addUpdate(result, aUserAddId));
  }
  aInitialDownloaded.add(USERS);

  //for future events
  final sub = (await liveQuery.client.subscribe(query))
    ..on(LiveQueryEvent.create, (value) {
      print("created: ${value.toString()}");
      addUpdate(value, aUserAddId);
    })
    ..on(LiveQueryEvent.update, (value) {
      addUpdate(value, aUserModifyId);
    })
    ..on(LiveQueryEvent.delete, (value) {
      print("deleted");
      final object = value as ParseObject;
      final id = object.objectId;
      parseUsersCollection.remove(id);
      aUserDeleteId.add(id);
    })
    ..on(LiveQueryEvent.error, (error) {
      print(error.toString());
    });

  return sub;
}

Map<String, String> returnChatListMap(Message message) {
  final userUid = (message.sender != currentParseUserUid)
      ? message.sender
      : message.receiver;

  return {
    CHAT_USER_UID : userUid,
    CHAT_MESSAGE_DUMP : message.messageDump,
    CHAT_PRODUCT_ID : message.productId,
    CHAT_HAS_UNREAD : NO,
  };
}

Future<void> registerAllMessageDumpListeners() async {
  currentParseUserCollection.buyingChats.forEach((uuid) async {
    messageDumpListeners.add(await registerChatListener(uuid, true));
  });
  currentParseUserCollection.sellingChats.forEach((uuid) async {
    messageDumpListeners.add(await registerChatListener(uuid, false));
  });
}

Message getParseMessage(dynamic value) => new Message().fromMap(
    jsonDecode((value as ParseObject).toString())
);
Future<Subscription> registerChatListener(String uuid, bool isBuyingChat) async {
  QueryBuilder query = QueryBuilder<ParseObject>(ParseObject(OBJECT_MESSAGE_DUMPS))
      ..whereEqualTo(MESSAGE_MESSAGE_DUMP, uuid);
  
  void handleMessage(dynamic value) {
    final message = getParseMessage(value);
    final listMap = returnChatListMap(message);
    (isBuyingChat) ? buyingChatList.add(listMap) : sellingChatList.add(listMap);

    if (!unreadMessages.containsKey(uuid)) unreadMessages[uuid] = [];
    if (!message.isRead && message.receiver == currentParseUserUid) unreadMessages[uuid].add(message);
    else unreadMessages[uuid].removeWhere((msg) => msg.id == message.id);
    
    if (unreadMessages[uuid].length > 0) aMessageDumpUnread.add(uuid);
    else aMessageDumpAllRead.add(uuid);
  }

  //first time
  var response = await query.query();
  if (response.success) response.results.forEach(handleMessage);

  //listener
  return await liveQuery.client.subscribe(query)
  ..on(LiveQueryEvent.create, handleMessage)
  ..on(LiveQueryEvent.update, handleMessage);
}

void cancelAllMessageDumpListeners() {
  messageDumpListeners.forEach((sub) => liveQuery.client.unSubscribe(sub));
  messageDumpListeners.clear();
}

String getTempImgPath() => "${tempDir.path}/temp.jpg";

void registerAllSnapshotListeners() async {
  print("registering snapshot listeners");
  tempDir = await getTemporaryDirectory();
  shopListener = await registerShopListener();
  socialListener = await registerSocialListener();
  usersListener = await registerUsersListener();
  hashtagsListener = await registerHashtagsListener();
  print("parse done");

  areAllSnapshotListenersRegistered = true;
}
void cancelAllSnapshotListeners() {
  liveQuery.client
  ..unSubscribe(shopListener)
  ..unSubscribe(socialListener)
  ..unSubscribe(usersListener)
  ..unSubscribe(hashtagsListener);

  cancelAllMessageDumpListeners();
}

void clearAllData() {
  buyingChatList.clear();
  sellingChatList.clear();

  takenDisplayNames.clear();

  parseShopCollection.clear();
  parseSocialCollection.clear();
  parseUsersCollection.clear();
  currentParseUserCollection = new PUser();

  currentSortMethod = SORT_RECOMMENDED;
  currentFilters.clear();

  localSettings.reset();
}

//screen width and height
double getScreenWidth(BuildContext context) {
  return MediaQuery.of(context).size.width;
}
double getScreenHeight(BuildContext context) {
  return MediaQuery.of(context).size.height;
}

//Parse Shop Item Update by ID
Future<void> updateParseShopItem(String id, Map<String, dynamic> map, {String setType}) async {
  var response = await new ParseObject(OBJECT_SHOP).getObject(id);
  if (response.success) {
    var shopObj = objFromMap(response.result as ParseObject, map, setType: setType);
    await shopObj.save().then(parseSaveCallback);
  }
  else print(response.error);
}

//Parse User Data Update by ID
Future<void> updateParseUserData(String userUid, Map<String, dynamic> map, {String setType}) async {
  var result = await getUserDataObject(userUid);
  if (result.success) {
    var obj = objFromMap(result.object, map, setType: setType);
    await obj.save().then(parseSaveCallback);
  }
}

//Shop Filtering
bool productFailedCheck(PProduct product) {
  return (
      product.likedBy.contains(currentParseUserUid) ||
          (product.seller == currentParseUserUid) ||
          product.isReserved ||
          product.isSold
  );
}

bool postFailedCheck(PPost post) {
  return (
    post.likedBy.contains(currentParseUserUid) ||
        (post.author == currentParseUserUid)
  );
}

bool filtersCheck(PProduct product, Map<String, Filter> filters) {
  if (filters.length == 0) return true;
  bool allFiltersPassed = false;
  for (String type in filters.keys) {
    Filter filter = filters[type];
    if (filter.values.length == 0) {
      allFiltersPassed = true;
      continue;
    }

    print(filter.values);
    String compareTo = "";
    switch (type) {
      case (FILTER_GENDER): {
        if (product.gender == FILTER_GENDER_BOTH) {
          allFiltersPassed = true;
          continue;
        }
        else compareTo = product.gender;
      }
      break;

      case (FILTER_CONDITION): {
        compareTo = product.itemCondition;
      }
      break;

      case (FILTER_SIZE): {
        compareTo = product.size;
      }
      break;
      case (FILTER_TYPE): {
        compareTo = product.type;
      }
      break;
      default: {
        allFiltersPassed = true;
        continue;
      }
    }

    allFiltersPassed = filter.values.contains(compareTo);
    if (!allFiltersPassed) break;
  }

  return allFiltersPassed;
}

List<Hashtag> getTopHashtags(int max) => []
  ..addAll(hashtagsDB.values)
  ..sort(hashtagCountComparator)
  ..sublist(0, min(hashtagsDB.length, max));

List<Hashtag> hashtagSearch(String query) {
  List<Hashtag> hashtags = []..addAll(hashtagsDB.values);
  hashtags.removeWhere((ht) => !ht.name.contains(query));
  return hashtags;
}

List<PProduct> databaseSearch(
    String query,
    String queryType,
    bool avoidReservedSoldLikedAndSelf,
    Map<String, Filter> filters,
  ) {
  query = query.toLowerCase().trim();
  List<PProduct> matchingQueries = List();

  switch (queryType) {
    case (SHOP_TITLE): {
      for (PProduct product in parseShopCollection.values) {
        final String title = product.title.toLowerCase().trim();
        if (productFailedCheck(product) && avoidReservedSoldLikedAndSelf) continue;
        if (
          (title.contains(query) || query.contains(title)) &&
          filtersCheck(product, filters)
        ) {
          matchingQueries.add(product);
        }
      }
    }
    break;
    case (SHOP_TYPE): {
      for (PProduct product in parseShopCollection.values) {
        final String type = product.type.toLowerCase().trim();
        if (productFailedCheck(product) && avoidReservedSoldLikedAndSelf) continue;
        if (
        (type.contains(query) || query.contains(type)) &&
            filtersCheck(product, filters)
        ) {
          matchingQueries.add(product);
        }
      }
    }
    break;
    case (SHOP_STYLES_LIST): {
      for (PProduct product in parseShopCollection.values) {
        final List<String> styles = product.styles;
        if (productFailedCheck(product) && avoidReservedSoldLikedAndSelf) continue;
        if (filtersCheck(product, filters)) {
          for (String style in styles) {
            style.toLowerCase().trim();
            if (style.contains(query) || query.contains(style)) {
              matchingQueries.add(product);
              break;
            }
          }
        }
      }
    }
    break;
    default: {
      print("database search failed");
      return List();
    }
    break;
  }

  return matchingQueries;
}

List<PPost> postSearch(
    String query,
    String queryType
) {
  query = query.toLowerCase().trim();
  List<PPost> matchingQueries = [];

  switch (queryType) {
    case (SOCIAL_TYPE): {
      for (PPost post in parseSocialCollection.values) {
        if (postFailedCheck(post)) continue;
        final String type = post.type.toLowerCase().trim();

        if (type.contains(query) || query.contains(type)) {
          matchingQueries.add(post);
        }
      }
    }
    break;

    case (SOCIAL_STYLES_LIST): {
      for (PPost post in parseSocialCollection.values) {
        if (postFailedCheck(post)) continue;
        final List<String> styles = post.styles;

        for (String style in styles) {
          style.toLowerCase().trim();
          if (style.contains(query) || query.contains(style)) {
            matchingQueries.add(post);
            break;
          }
        }
      }
    }
    break;
  }

  return matchingQueries;
}

Map<String, PProduct> filteredShopCollection(Map<String, Filter> filters) {
  Map<String, PProduct> returnMap = Map();

  for (PProduct product in parseShopCollection.values) {
    if (!productFailedCheck(product)) {
      if (filters != null) {
        if (filtersCheck(product, filters)) returnMap[product.id] = product;
      }
      else {
        returnMap[product.id] = product;
      }
    }
  }

  return returnMap;
}

List<PProduct> addShopCollectionToList(List<PProduct> originalList, Map<String, PProduct> collection) {
  for (PProduct product in collection.values) originalList.add(product);

  return originalList;
}

List<PProduct> removeDuplicates(List<PProduct> list) {
  List<PProduct> returnList = List();
  for (PProduct product in list) {
    if (!returnList.contains(product)) returnList.add(product);
  }

  return returnList;
}

bool stringListsHaveMatches(List<String> a, List<String> b) {
  for (String aString in a) {
    if (b.contains(aString)) return true;
  }
  for (String bString in b) {
    if (a.contains(bString)) return true;
  }

  return false;
}
Map<String, List<PProduct>> getRecommendedProductMap(
    Map<String, Filter> filters,
    List<String> types,
    String style,
    {List<String> hashtagIDs,}) {
  List<PProduct> priorityList = [];
  List<PProduct> midList = [];
  List<PProduct> secondaryList = [];

  String priority = (types.isEmpty)
  ? (style.isEmpty)
      ? (hashtagIDs == null) ? NONE : HASHTAG
      : STYLE
  : (hashtagIDs == null)
      ? (style.isEmpty) ? TYPE : TYPE_STYLE
      : HASHTAG;

  List<String> userTypes = types.isEmpty ? [currentParseUserCollection.mostRecentType] : types;
  String userStyle = style.isEmpty ? currentParseUserCollection.mostRecentStyle : style;

  for (PProduct product in parseShopCollection.values) {
    int pLen = priorityList.length;
    int mLen = midList.length;

    if (productFailedCheck(product)) continue;
    if (filters != null && !filtersCheck(product, filters)) continue;

    final typeMatch = userTypes.contains(product.type);
    final styleMatch = product.styles.contains(userStyle);

    switch(priority) {
      case (NONE): {
        if (typeMatch || styleMatch) priorityList.add(product);
      }
      break;
      case (HASHTAG): {
        if (stringListsHaveMatches(hashtagIDs, product.hashtagIDs)) priorityList.add(product);
        else if (typeMatch || styleMatch) midList.add(product);
      }
      break;
      case (TYPE): {
        if (typeMatch) priorityList.add(product);
        else if (styleMatch) midList.add(product);
      }
      break;
      case (STYLE): {
        if (styleMatch) priorityList.add(product);
        else if (typeMatch) midList.add(product);
      }
      break;
      case (TYPE_STYLE): {
        if (typeMatch || styleMatch) priorityList.add(product);
      }
      break;
    }

    if (pLen == priorityList.length && mLen == midList.length) secondaryList.add(product);
  }

  midList.shuffle();
  priorityList.addAll(midList);

  secondaryList.shuffle();
  return {
    RECOMMENDED_PRIORITY : priorityList,
    RECOMMENDED_SECONDARY : secondaryList,
  };
}

List<PProduct> getRecommendedProductList(Map<String, List<PProduct>> map) {
  List<PProduct> returnList = List();
  returnList.addAll(map[RECOMMENDED_PRIORITY]);
  returnList.addAll(map[RECOMMENDED_SECONDARY]);
  return returnList;
}

ProgressDialog getLoadingDialog(BuildContext context) {
  return ProgressDialog(
    context,
    type: ProgressDialogType.Normal,
    isDismissible: false,
  );
}

List<PPost> getRecommendedPostList(String type, String style) {
  List<PPost> priorityList = List();
  List<PPost> secondaryList = List();
  String userType = type.isEmpty ? currentUserCollection.mostRecentType : type;
  String userStyle = style.isEmpty ? currentUserCollection.mostRecentStyle : style;

  for (PPost post in parseSocialCollection.values) {
    if (postFailedCheck(post)) continue;

    if (post.type == userType || post.styles.contains(userStyle)) {
      priorityList.add(post);
    }
    else {
      secondaryList.add(post);
    }
  }

  priorityList.addAll(secondaryList);

  return priorityList;
}

ProgressDialog styleDialog(ProgressDialog dialog, String message) {
  dialog.style(
    message: message,
    borderRadius: 10.0,
    backgroundColor: Colors.white,
    elevation: 10.0,
    insetAnimCurve: Curves.easeInOut,
    messageTextStyle: TextStyle(
        color: Colors.black, fontSize: 19.0, fontWeight: FontWeight.w600),
  );
  return dialog;
}

void launchSwipeWidget(BuildContext context, PProduct product) {
  intentMap[INTENT_SWIPE] = product;
  fadePageTransition(context, new DiscoverSwipeWidget(), isOpaque: false);
}

void fadePageTransition(BuildContext context, Widget destination, {bool isOpaque = true}) {
  Navigator.push(context, new PageRouteBuilder(
    opaque: isOpaque,
    pageBuilder: (_, __, ___) => destination,
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      return FadeTransition(
        opacity: animation,
        child: child,
      );
    },
  ),);
}

void slidePageTransition(BuildContext context, Widget destination, String dir) {
  double direction;

  switch (dir) {
    case (UP): direction = pi/2;
    break;
    case (DOWN): direction = - pi/2;
    break;
    case (LEFT): direction = 0;
    break;
    case (RIGHT): direction = pi;
    break;
    default: direction = 0;
    break;
  }

  final beginOffset = Offset.fromDirection(direction);

  Navigator.push(context, new PageRouteBuilder(
    pageBuilder: (_, __, ___) => destination,
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      return SlideTransition(
        child: child,
        position: Tween<Offset>(
          begin: beginOffset,
          end: Offset.zero,
        ).animate(animation),
      );
    }
  ));
}

Widget centeredEmptyWidget(String emptyText, {double height}) {
  return Container(
    alignment: Alignment.center,
    height: height,
    child: Text(
      emptyText,
      style: Styles.indicator,
    ),
  );
}

String readTimestamp(int timestamp) {
  var format = new DateFormat('HH:mm a');
  var date = new DateTime.fromMillisecondsSinceEpoch(timestamp);

  return format.format(date);
}

String formatTimestamp(int timestamp) {
  var now = DateTime.fromMillisecondsSinceEpoch(Timestamp.now().millisecondsSinceEpoch);
  var date = new DateTime.fromMillisecondsSinceEpoch(timestamp);

  String plural(diff) {
    return diff > 1 ? "S" : "";
  }
  int diff = now.second - date.second;
  String period = "SECOND";
  if (now.year != date.year) {
    diff = now.year - date.year;
    period = "YEAR";
  }
  else if (now.month != date.month) {
    diff = now.month - date.month;
    period = "MONTH";
  }
  else if (now.day != date.day) {
    diff = now.day - date.day;
    period = "DAY";
  }
  else if (now.hour != date.hour) {
    diff = now.hour - date.hour;
    period = "HOUR";
  }
  else if (now.minute != date.minute) {
    diff = now.minute - date.minute;
    period = "MINUTE";
  }

  return "$diff $period${plural(diff)} AGO";
}

String numberAdjusted(double number) {
  String numString = number.toInt().toString();
  int numLength = numString.length;
  int remainderLength;
  String firstDigits;
  String trailingDigit;
  String endingLetter;

  if (numLength < 4) return numString;
  else if (numLength < 7) {
    //thousands
    remainderLength = numLength - 3;
    endingLetter = "k";
  }
  else if (numLength < 10) {
    //millions
    remainderLength = numLength - 6;
    endingLetter = "mil";
  }
  else {
    //billions and above
    remainderLength = numLength - 9;
    endingLetter = "bil";
  }

  firstDigits = numString.substring(0, remainderLength);
  trailingDigit = numString[remainderLength];
  return "$firstDigits.$trailingDigit $endingLetter";
}

void defaultDialogFunction(BuildContext context) {
  Navigator.pop(context);
}
void showDialogWithMessage(BuildContext context, String errorMessage, String errorTitle) {
  showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: new Text(errorTitle),
          content: new Text(errorMessage),
          actions: <Widget>[
            new FlatButton(
              onPressed: () => defaultDialogFunction(context),
              child: new Text("Cancel"),
            ),
            new FlatButton(
              onPressed: () => defaultDialogFunction(context),
              child: new Text("OK"),
            ),
          ],
        );
      }
  );
}

Future<Map<String, Review>> getParseReviews(String receiver) async {
  final query = QueryBuilder<ParseObject>(ParseObject(OBJECT_REVIEW))
      ..whereEqualTo(REVIEW_RECEIVER, receiver);

  var response = await query.query();
  Map<String, Review> returnMap = {};

  if (response.success && response.results != null) response.results.forEach((result) {
    var obj = result as ParseObject;
    final review = new Review().fromMap(jsonDecode(obj.toString()));
    returnMap[review.author] = review;
  });
  else print(response.error);

  return returnMap;
}

Future<void> writeParseReview(Review review) async {
  var obj = objFromMap(new ParseObject(OBJECT_REVIEW), review.toMap());
  await obj.create().then(parseSaveCallback);
}

Future<void> deleteParseReview(String author, String receiver) async {
  final query = QueryBuilder<ParseObject>(ParseObject(OBJECT_REVIEW))
      ..whereEqualTo(REVIEW_AUTHOR, author)
      ..whereEqualTo(REVIEW_RECEIVER, receiver);
  var response = await query.query();
  if (response.success) response.results.forEach((result) async {
    var obj = result as ParseObject;
    await obj.delete().then(parseSaveCallback);
  });
  else print(response.error);
}

Future<String> getInfoUrl(String name) async {
  var result = await getInfoFileObject(name);
  return (result.success) ? (result.object.get(INFO_FILE) as ParseFile).url : "";
}

Future<void> getContactInfo() async {
  String downloadUrl = await getInfoUrl(INFO_CONTACT);

  if (downloadUrl.isNotEmpty) {
    Map<String, dynamic> contactMap = jsonDecode(
        (await http.get(downloadUrl)).body);
    localSettings.hotline = contactMap[CONTACT_HOTLINE].toString();
    localSettings.email = contactMap[CONTACT_EMAIL].toString();
  }
}

List<String> getTypeList(String gender, String query) {
  List<String> typeList = [];

  switch(gender) {
    case (FILTER_GENDER_MALE): {
      typeList.addAll(defaultSettings.mCats[query]);
    }
    break;
    case (FILTER_GENDER_FEMALE): {
      typeList.addAll(defaultSettings.fCats[query]);
    }
    break;
    case (FILTER_GENDER_BOTH): {
      typeList.addAll(defaultSettings.mCats[query]);
      final fTypes = defaultSettings.fCats[query];
      for (String type in fTypes) {
        if (!typeList.contains(type)) typeList.add(type);
      }
    }
    break;
  }

  return typeList;
}