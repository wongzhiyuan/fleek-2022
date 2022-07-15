import 'dart:convert';

import 'package:fleek/global/globalItems.dart';
import 'package:parse_server_sdk/parse_server_sdk.dart';

class Hashtag {
  String name = "";
  int count = 0;
  String objectId = "";
  Hashtag({this.objectId, this.name, this.count = 0});

  Map<String, dynamic> toMap() => {
    HASHTAG_NAME : this.name,
    HASHTAG_COUNT : this.count,
  };

  Hashtag fromObject(ParseObject object) {
    Map<String, dynamic> map = jsonDecode(object.toString());

    return new Hashtag(
      objectId: object.objectId,
      name: map[HASHTAG_NAME].toString(),
      count: int.parse(map[HASHTAG_COUNT].toString()),
    );
  }
}