import 'dart:async';

import 'package:fleek/chat/ChatWidget.dart';
import 'package:fleek/dataclasses/Message.dart';
import 'package:fleek/dataclasses/PProduct.dart';
import 'package:fleek/dataclasses/Product.dart';
import 'package:fleek/values/colors.dart';
import 'package:fleek/values/dimens.dart';
import 'package:fleek/values/styles.dart';
import 'package:fleek/widgetClasses/CircularNumber.dart';
import 'package:fleek/widgetClasses/CircularProfileThumb.dart';
import 'package:flutter/material.dart';
import 'package:fleek/global/globalFunctions.dart';
import 'package:fleek/global/globalItems.dart';


class ChatDrawer extends StatefulWidget {
  _ChatDrawerState createState() => _ChatDrawerState();
}

class _ChatDrawerState extends State<ChatDrawer> {
  StreamSubscription buyingChatListener, sellingChatListener,
      messageDumpUnreadListener, messageDumpAllReadListener;
  List<Map<String, String>> _buyingList = [];
  List<Map<String, String>> _sellingList = [];
  String chatType = CHAT_DRAWER_BUYING;
  final imageWidth = Dimens.imageSizeThumb;

  @override
  void initState() {
    super.initState();

    setState(() {
      _buyingList.addAll(buyingChatList);
      _sellingList.addAll(sellingChatList);
    });

    buyingChatListener = aBuyingChatAdded.stream.listen((map) => setState(() {
        _buyingList.add(map);
      })
    );
    sellingChatListener = aSellingChatAdded.stream.listen((map) => setState(() {
        _sellingList.add(map);
      })
    );

    void handleStream(String uid, String indicator) {
      int modifyIndex = _buyingList.indexWhere((map) => map[CHAT_MESSAGE_DUMP] == uid);
      if (modifyIndex != -1) {
        //in buying list
        setState(() {
          _buyingList[modifyIndex][CHAT_HAS_UNREAD] = indicator;
        });
      }
      else {
        //in selling list?
        modifyIndex = _sellingList.indexWhere((map) => map[CHAT_MESSAGE_DUMP] == uid);
        if (modifyIndex != -1) {
          //in selling list
          setState(() {
            _sellingList[modifyIndex][CHAT_HAS_UNREAD] = indicator;
          });
        }
      }
    }

    for (String key in unreadMessages.keys) {
      if (unreadMessages[key].length > 0) handleStream(key, YES);
    }

    messageDumpUnreadListener = aMessageDumpUnread.stream.listen((uid) => handleStream(uid, YES));
    messageDumpAllReadListener = aMessageDumpAllRead.stream.listen((uid) => handleStream(uid, NO));
  }

  @override
  void dispose() {
    buyingChatListener.cancel();
    sellingChatListener.cancel();
    messageDumpUnreadListener.cancel();
    messageDumpAllReadListener.cancel();

    _buyingList.clear();
    _sellingList.clear();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bool isBuying = chatType == CHAT_DRAWER_BUYING;

    List<Map<String, String>> displayList = [];
    final bool _displayNotEmpty = isBuying ? _buyingList.isNotEmpty : _sellingList.isNotEmpty;

    displayList.addAll(
      isBuying
      ? _buyingList
      : _sellingList
    );

    return new Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: Text("Chats"),
        actions: <Widget>[
          Padding(
            padding: EdgeInsets.all(10),
            child: DropdownButton(
              dropdownColor: CustomColors.colorTheme,
              iconEnabledColor: CustomColors.colorPrimary,
              underline: SizedBox(),
              value: chatType,
              onChanged: (value) => setState(() => chatType = value),
              items: [CHAT_DRAWER_BUYING, CHAT_DRAWER_SELLING].map((value) => DropdownMenuItem<String>(
                value: value,
                child: Text(
                  value,
                  style: TextStyle(
                    color: CustomColors.colorPrimary,
                  ),
                ),
              )).toList(),
            ),
          ),
        ],
      ),
      body: _displayNotEmpty
      ? ListView.builder(
        itemCount: displayList.length,
        itemBuilder: (BuildContext context, int index) {
          final map = displayList[index];
          final userUid = map[CHAT_USER_UID];
          final product = parseShopCollection[map[CHAT_PRODUCT_ID]];

          final chatUser = usersCollection[userUid];
          final bool hasUnread = map[CHAT_HAS_UNREAD] == YES;
          List<Message> unreadMessageList = hasUnread
          ? unreadMessages[map[CHAT_MESSAGE_DUMP]]
          : [];

          final Message latestMessage = unreadMessageList.last;

          return new ListTile(
            onTap: () => launchChatWidget(context, userUid, product),
            leading: CircularProfileThumb(
              image: chatUser.profilePictureUri,
            ),
            title: Text(chatUser.displayName, style: Styles.listHeader,),
            subtitle: Text(
              hasUnread ? latestMessage.message : "no unread messages",
              overflow: TextOverflow.ellipsis,
            ),
            trailing: hasUnread
            ? CircularInfo(info: unreadMessageList.length.toString(),)
            : null,
          );
        }
      )
      : ListTile(
        leading: Icon(Icons.cancel),
        title: Text("You currently have no chats.", style: Styles.indicator,),
      ),
    );
  }

  void launchChatWidget(BuildContext context, String chatUid, PProduct product) {
    Navigator.push(context, MaterialPageRoute(
      builder: (context) => ChatWidget(
        chatUid: chatUid,
        product: product,
      )
    ));
  }
}