import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fleek/global/globalFunctions.dart';
import 'package:fleek/global/globalItems.dart';
import 'package:parse_server_sdk/parse_server_sdk.dart';

class Message {
  String message = "";
  ParseFile image;
  String messageDump = "";
  String sender = "";
  String receiver = "";
  int timestamp = Timestamp.now().millisecondsSinceEpoch;
  bool isRead = false;
  bool isImage = false;
  String productId = "";
  String id = "";

  void init(
    String message,
    ParseFile image,
    String messageDump,
    String sender,
    String receiver,
    int timestamp,
    bool isRead,
    bool isImage,
    String productId,
    String id,

  ) {
    this.message = message;
    this.image = image;
    this.sender = sender;
    this.receiver = receiver;
    this.timestamp = timestamp;
    this.isRead = isRead;
    this.isImage = isImage;
    this.productId = productId;
    this.id = id;
  }

  Map<String, dynamic> toMap() => {
    MESSAGE_MESSAGE : this.message,
    MESSAGE_IMAGE : this.image,
    MESSAGE_SENDER : this.sender,
    MESSAGE_RECEIVER : this.receiver,
    MESSAGE_TIMESTAMP : this.timestamp,
    MESSAGE_IS_READ : this.isRead,
    MESSAGE_IS_IMAGE : this.isImage,
    MESSAGE_PRODUCT_ID : this.productId,
    MESSAGE_ID : this.id,
  };

  Message fromMap(Map<String, dynamic> map) {
    File imageFile = new File(getTempImgPath());
    return new Message()..init(
      map[MESSAGE_MESSAGE].toString(),
      new ParseFile(imageFile).fromJson(map[MESSAGE_IMAGE]) as ParseFile,
      map[MESSAGE_MESSAGE_DUMP].toString(),
      map[MESSAGE_SENDER].toString(),
      map[MESSAGE_RECEIVER].toString(),
      int.parse(map[MESSAGE_TIMESTAMP].toString()),
      map[MESSAGE_IS_READ] as bool,
      map[MESSAGE_IS_IMAGE] as bool,
      map[MESSAGE_PRODUCT_ID].toString(),
      map[MESSAGE_ID].toString(),
    );
  }
}