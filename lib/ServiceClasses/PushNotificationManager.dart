import 'dart:async';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:fleek/global/globalItems.dart';
import 'package:fleek/global/globalFunctions.dart';
import 'package:flutter/cupertino.dart';
import 'package:parse_server_sdk/parse_server_sdk.dart';

class PushNotificationsManager {

  PushNotificationsManager._();

  factory PushNotificationsManager() => _instance;

  static final PushNotificationsManager _instance = PushNotificationsManager._();

  final FirebaseMessaging _firebaseMessaging = FirebaseMessaging();
  bool _initialized = false;

  Future<void> init(BuildContext context) async {
    if (!_initialized) {
      // For iOS request permission first.
      _firebaseMessaging.requestNotificationPermissions();
      _firebaseMessaging.configure(
        onMessage: (Map<String, dynamic> message) async {
          print("on Message: $message");
        },
        onLaunch: (Map<String, dynamic> message) async {
          print("on launch: $message");
          navigateToChat(context, message['data']);
        },
        onResume: (Map<String, dynamic> message) async {
          print("on resume: $message");
          navigateToChat(context, message['data']);
        },
        onBackgroundMessage: backgroundMessageHandler,
      );

      // For testing purposes print the Firebase Messaging token
      String token = await _firebaseMessaging.getToken();
      print("FirebaseMessaging token: $token");

      final query = QueryBuilder<ParseObject>(ParseObject(OBJECT_USER_CHAT_INFO))
      ..whereEqualTo(CHAT_USER_UID, currentParseUserUid);
      var response = await query.query();
      print(response.results);
      if (response.error.type == PARSE_ERROR_OBJECT_NOT_FOUND) {
        print("making new chat user info");
        ParseObject object = ParseObject(OBJECT_USER_CHAT_INFO)
          ..set(CHAT_USER_UID, currentParseUserUid)
          ..set(CHAT_USER_TOKEN, token)
          ..set(CHAT_IS_CHAT_ON, NO)
          ..set(CHAT_IS_NOTIFS_ENABLED, YES)
          ..set(CHAT_BUYING, {})
          ..set(CHAT_SELLING, {});

        await object.create();
      }
      else print("user data info exists: ${response.success}");

      _initialized = true;
    }
  }
}