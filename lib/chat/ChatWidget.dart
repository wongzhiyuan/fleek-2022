import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:bubble/bubble.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:crossplat_objectid/crossplat_objectid.dart';
import 'package:fleek/dataclasses/Message.dart';
import 'package:fleek/dataclasses/PProduct.dart';
import 'package:fleek/dataclasses/Product.dart';
import 'package:fleek/dataclasses/Review.dart';
import 'package:fleek/global/globalFunctions.dart';
import 'package:fleek/global/globalItems.dart';
import 'package:fleek/values/colors.dart';
import 'package:fleek/values/dimens.dart';
import 'package:fleek/values/ints.dart';
import 'package:fleek/values/strings.dart';
import 'package:fleek/values/styles.dart';
import 'package:fleek/widgetClasses/DefaultImageFile.dart';
import 'package:fleek/widgetClasses/DefaultImageNetwork.dart';
import 'package:flutter/material.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
import 'package:image_picker/image_picker.dart';
import 'package:parse_server_sdk/parse_server_sdk.dart';
import 'package:progress_dialog/progress_dialog.dart';
import 'package:uuid/uuid.dart';
import 'package:http/http.dart' as http;

class ChatWidget extends StatefulWidget {
  final title = "ChatWidget";
  final chatUid;
  final product;

  final messageDumpUuid;

  ChatWidget({this.product, this.chatUid, this.messageDumpUuid});

  _ChatState createState() => _ChatState();
}

class _ChatState extends State<ChatWidget> {
  PProduct product = new PProduct();
  String chatUid = "";
  bool isSeller = false;
  String dir;
  String messageDumpUuid;
  
  StreamSubscription productStatusListener;
  StreamSubscription newMessageListener;
  StreamSubscription messageReadListener;

  Subscription parseMessageSub;

  List<Message> _messageList = [];
  List<String> _messageIdList = [];
  List<Message> _oldList;
  
  final writeController = new TextEditingController();
  final reviewController = new TextEditingController();
  
  final paddingBubble = Dimens.paddingChatBubble;
  
  @override
  void initState() {
    super.initState();

    setChatOn();

    product = widget.product;
    
    productStatusListener = aShopModifyId.stream.listen((id) {
      if (id == product.id) setState(() {
        product = parseShopCollection[id];
      });
    });
    
    chatUid = widget.chatUid;
    messageDumpUuid = widget.messageDumpUuid;
    isSeller = product.seller == currentParseUserUid;
    dir = isSeller ? CHAT_SELLING : CHAT_BUYING;

    if (chatUid != null) {
      final query = QueryBuilder<ParseObject>(ParseObject(OBJECT_USER_CHAT_INFO))
      ..whereEqualTo(CHAT_USER_UID, currentParseUserUid);
      query.query().then((ParseResponse response) {
        if (response.success) {
          var object = response.results.first as ParseObject;
          messageDumpUuid = object.get(dir)[chatUid][CHAT_MESSAGE_DUMP];
          registerMessageListener();
        }
        else print(response.error);
      });
    }
    else if (messageDumpUuid != null) {
      final query = QueryBuilder<ParseObject>(ParseObject(OBJECT_MESSAGE_DUMPS))
        ..whereEqualTo(CHAT_MESSAGE_DUMP, messageDumpUuid);
      query.query().then((ParseResponse response) {
        if (response.success) {
          var object = response.results.first as ParseObject;
          product = parseShopCollection[object.get(CHAT_PRODUCT_ID)];
          registerMessageListener();
        }
        else print(response.error);
      });
    }

    /*
    if (chatUid != null) {
      realtimeDB.child(CHAT_USER_UID)
          .child(currentUserUid)
          .child(dir)
          .child(chatUid)
          .child(CHAT_MESSAGE_DUMP)
          .once()
          .then((snapshot) {
        if (snapshot.value != null) {
          messageDumpUuid = snapshot.value.toString();
          registerMessageListener();
        }
      });
    }
    else if (messageDumpUuid != null) {
      realtimeDB.child(CHAT_MESSAGE_DUMP)
          .child(messageDumpUuid)
          .child(CHAT_PRODUCT_ID)
          .once()
          .then((snapshot) {
            if (snapshot.value != null) {
              final String productId = snapshot.value.toString();
              shopRef.document(productId).get().then((document) {
                if (document.exists) {
                  var map = new Map<String, dynamic>.from(document.data);
                  product = Product().fromMap(map);
                }
              });
            }
      });
    }
    */
  }

  @override
  void dispose() {
    setChatOff();

    writeController.dispose();
    reviewController.dispose();

    productStatusListener.cancel();
    newMessageListener.cancel();
    messageReadListener.cancel();
    super.dispose();
  }
  @override
  Widget build(BuildContext context) {
    final imageWidth = Dimens.imageSizeSmall;
    final paddingContent = Dimens.paddingChatProductInfoContent;

    return WillPopScope(
      onWillPop: () async {
        setChatOff();
        return true;
      },

      child: Scaffold(
        appBar: AppBar(
          centerTitle: true,
          title: Text(takenDisplayNames[chatUid]),
        ),
        body: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          children: <Widget>[
            //product info holder
            Container(
              width: getScreenWidth(context),
              height: Dimens.heightChatProductInfo,
              padding: EdgeInsets.all(Dimens.paddingChatProductInfoAround),
              child: Row(
                children: <Widget>[
                  Container(
                    width: imageWidth,
                    height: imageWidth,
                    child: DefaultImageNetwork(
                      image: product.images[0].url,
                      width: imageWidth,
                      height: imageWidth,
                      fit: BoxFit.cover,
                    ),
                    decoration: BoxDecoration(
                      border: Border.all(color: CustomColors.colorPrimaryDark),
                    ),
                  ),
                  Container(
                    width: getScreenWidth(context) - imageWidth - 2 * Dimens.paddingChatProductInfoAround,
                    padding: EdgeInsets.only(left: paddingContent),
                    child: ConstrainedBox(
                      constraints: BoxConstraints.expand(),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.start,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          Text(
                            product.title,
                            style: Styles.listHeader,
                          ),
                          Padding(
                            padding: EdgeInsets.only(top: paddingContent),
                            child: Text("\$${product.price}"),
                          ),
                          buttonRow(),
                        ],
                      ),
                    ),
                  ),

                ],
              ),
            ),

            //message display
            Expanded(
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: _messageList.length,
                itemBuilder: (BuildContext context, int index) {
                  var currentMessage = _messageList[index];
                  bool isSender = currentMessage.sender == currentParseUserUid;
                  bool isRead = currentMessage.isRead;
                  bool isImage = currentMessage.isImage;

                  if (isImage) {
                    return Align(
                      alignment: isSender ? Alignment.centerRight : Alignment.centerLeft,
                      child: Padding(
                        padding: EdgeInsets.only(left: paddingBubble, right: paddingBubble, top: paddingBubble),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(8.0),
                          child: DefaultImageNetwork(
                            image: currentMessage.image.url,
                            width: Dimens.imageSizeChat,
                            fit: BoxFit.contain,
                          ),
                        ),
                      ),

                    );
                  }
                  else if (currentMessage.timestamp == TIMESTAMP_REVIEW) {
                    return InkWell(
                      onTap: () => leaveReview(context),
                      child: Bubble(
                        margin: BubbleEdges.all(paddingBubble),
                        padding: BubbleEdges.all(paddingBubble),
                        alignment: Alignment.center,
                        color: CustomColors.messageSpecial,
                        child: Text(
                          currentMessage.message,
                          textAlign: TextAlign.center,
                          style: Styles.chatMessage,
                        ),
                      ),
                    );
                  }
                  else {
                    return Bubble(
                      margin: BubbleEdges.fromLTRB(paddingBubble, paddingBubble, paddingBubble, 0),
                      padding: BubbleEdges.all(paddingBubble),
                      alignment: isSender ? Alignment.centerRight : Alignment.centerLeft,
                      color: isSender ? CustomColors.messageSent : CustomColors.messageReceived,
                      nip: isSender ? BubbleNip.rightTop : BubbleNip.leftTop,
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        mainAxisAlignment: isSender ? MainAxisAlignment.end : MainAxisAlignment.start,
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: <Widget>[
                          Text(
                            currentMessage.message,
                            textAlign: isSender ? TextAlign.right : TextAlign.left,
                            style: Styles.chatMessage,
                          ),
                          Padding(
                              padding: EdgeInsets.only(left: paddingBubble),
                              child: Align(
                                alignment: Alignment.bottomRight,
                                child: Text(
                                  readTimestamp(currentMessage.timestamp),
                                  style: Styles.timestamp,
                                ),
                              )
                          ),
                          Padding(
                            padding: EdgeInsets.only(left: paddingBubble),
                            child: isRead && isSender ? Icon(Icons.done_all) : null,
                          )
                        ],
                      ),
                    );
                  }

                },
              ),
            ),

            //chat text entry container
            Container(
              child: Align(
                alignment: FractionalOffset.bottomCenter,
                child: Container(
                  child: Row(
                    children: <Widget>[
                      IconButton(
                        icon: Icon(Icons.photo),
                        onPressed: () => sendImage(context),
                      ),
                      Expanded(
                        child: Container(
                          padding: EdgeInsets.all(Dimens.paddingChatInput),
                          child: TextField(
                            controller: writeController,
                            maxLines: null,
                            decoration: InputDecoration(
                              border: Styles.chatInputBorder,
                              hintText: "type a message...",
                            ),
                          ),
                        ),
                      ),
                      IconButton(
                        icon: Icon(Icons.send),
                        onPressed: () => sendMessage(false),
                      ),
                    ],
                  ),
                ),
              ),
            )
          ],
        ),
      ),
    );
  }

  Widget buttonRow() {
    if (!isSeller) return Container();

    bool isReserved = product.isReserved;
    bool isSold = product.isSold;

    return Expanded(
      child: Row(
        mainAxisAlignment: MainAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: <Widget>[
          IconButton(
            onPressed: () => markAsSold(context),
            tooltip: "Mark as Sold",
            icon: Icon(Icons.monetization_on),
            color: isSold ? CustomColors.colorPrimaryDark : CustomColors.colorGreyedOut,
          ),
          IconButton(
            onPressed: () => markAsReserved(context),
            tooltip: "Mark as Reserved",
            icon: Icon(Icons.room_service),
            color: isSold ? CustomColors.colorPrimaryDark : CustomColors.colorGreyedOut,
          ),
        ],
      ),
    );
  }

  void markAsSold(BuildContext context) async {
    //crafting special review message
    Message reviewMessage = Message()..init(
      "Leave a review about this user",
      null,
      messageDumpUuid,
      currentParseUserUid,
      chatUid,
      TIMESTAMP_REVIEW,
      false,
      false,
      product.id,
      "",
    );
    
    ProgressDialog ld = getLoadingDialog(context);
    ld = styleDialog(ld, "Marking as sold...");
    await ld.show();

    final bool isSold = !product.isSold;

    if (isSold) {
      updateMessageDump(reviewMessage);
    }
    else {
      await deleteParseReview(currentParseUserUid, chatUid);
      await deleteParseReview(chatUid, currentParseUserUid);
    }

    String setType = isSold
      ? SET_ADD_UNIQUE
      : SET_REMOVE;

    await updateParseShopItem(product.id, {
      SHOP_BUYER : isSold ? chatUid : "",
      SHOP_IS_SOLD : isSold,
    });

    Future<void> changeUserList(String key, String userUid) async {
      var result = await getUserDataObject(userUid);
      var obj = (result.success) ? objFromMap(result.object, {
        key : product.id
      }, setType: setType) : null;

      if (obj != null) await obj.save().then(parseSaveCallback);
    }

    await changeUserList(isSeller ? USER_SOLD : USER_BOUGHT, currentParseUserUid);
    await changeUserList(isSeller ? USER_BOUGHT : USER_SOLD, chatUid);
    await ld.hide();
  }

  void markAsReserved(BuildContext context) async {
    ProgressDialog ld = getLoadingDialog(context);
    ld = styleDialog(ld, "Marking as reserved...");
    await ld.show();
    await updateParseShopItem(product.id, {
      SHOP_IS_RESERVED : !product.isReserved,
    });
    await ld.hide();
  }
  
  void leaveReview(BuildContext context) async {
    ProgressDialog ld = getLoadingDialog(context);
    ld = styleDialog(ld, "loading...");
    
    await ld.show();
    
    final String receiver = chatUid;
    final String author = currentParseUserUid;

    Map<String, Review> reviewMap = await getParseReviews(receiver);

    String dialogTitle = "Unable to leave review";
    Widget dialogChild = Text("You have already left a review for this user.");

    double ratingInput = 2.5;

    bool reviewWritten = reviewMap.containsKey(author);
    if (!reviewWritten) {
      dialogTitle = "Leave a review!";
      dialogChild = Column(
        mainAxisAlignment: MainAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          RatingBar(
            allowHalfRating: true,
            initialRating: ratingInput,
            maxRating: 5.0,
            minRating: 0.5,
            direction: Axis.horizontal,
            onRatingUpdate: (rating) => ratingInput = rating,
            itemBuilder: (context, _) => Icon(
              Icons.star,
              color: Colors.amber,
            ),
            itemSize: 40,
          ),
          Padding(
            padding: EdgeInsets.only(top: paddingBubble),
            child: TextField(
              controller: reviewController,
              maxLength: Ints.reviewMaxLength,
              maxLengthEnforced: true,
              maxLines: null,
              minLines: null,
              decoration: InputDecoration(
                labelText: Strings.labelTextReviewInput,
                hintText: Strings.hintReviewInput,
                alignLabelWithHint: true,
                border: Styles.inputBorder,
              ),
            ),
          ),
        ],
      );
    }

    await ld.hide();

    await showDialog<void>(
      context: context,
      barrierDismissible: true,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(dialogTitle),
          content: Container(
            width: getScreenWidth(context) * 3/4,
            height: getScreenHeight(context) * 1/2,
            child: SingleChildScrollView(
              child: dialogChild,
            ),
          ),
          actions: reviewWritten
          ? <Widget>[
            FlatButton(
              child: Text("OK"),
              onPressed: () => Navigator.pop(context),
            ),
          ]
          : <Widget>[
            FlatButton(
              child: Text("Cancel"),
              onPressed: () => Navigator.pop(context),
            ),
            FlatButton(
              child: Text("Submit"),
              onPressed: () async {
                ProgressDialog rd = styleDialog(ld, "uploading review...");
                await rd.show();

                final review = new Review(
                  author: author,
                  receiver: receiver,
                  rating: ratingInput,
                  desc: reviewController.text.toString().trim(),
                );

                await writeParseReview(review);
                await rd.hide();
                Navigator.pop(context);
              },
            ),
          ],
        );
      },
    );
    
  }

  void sendImage(BuildContext context) async {
    ProgressDialog ld = getLoadingDialog(context);
    styleDialog(ld, "sending image...");
    File image = File((
      await ImagePicker().getImage(source: ImageSource.gallery)
    ).path);

    if (image != null) {
      await ld.show();
      File imageFile = new File(getTempImgPath());
      List<int> imageList = await FlutterImageCompress.compressWithFile(image.absolute.path, quality: 50);
      Uint8List imageData = Uint8List.fromList(imageList);
      imageFile.writeAsBytes(imageData);

      sendMessage(true, image: new ParseFile(imageFile));
      await ld.hide();
    }
  }

  void sendMessage(bool isImage, {ParseFile image}) async {
    if (writeController.text.isEmpty) return;
    if (isImage) writeController.clear();

    if (messageDumpUuid == null) {
      messageDumpUuid = new ObjectId().toHexString();
      final senderDir = (isSeller) ? USER_SELLING_CHATS : USER_BUYING_CHATS;
      final receiverDir = (isSeller) ? USER_BUYING_CHATS : USER_SELLING_CHATS;

      await updateParseUserData(currentParseUserUid, {
        senderDir : messageDumpUuid,
      }, setType: SET_ADD_UNIQUE);
      await updateParseUserData(chatUid, {
        receiverDir : messageDumpUuid,
      }, setType: SET_ADD_UNIQUE);
    }

    Message newMessage = Message()..init(
      writeController.text,
      image,
      messageDumpUuid,
      currentParseUserUid,
      chatUid,
      Timestamp
          .now()
          .millisecondsSinceEpoch,
      false,
      false,
      product.id,
      ""
    );
    if (!isImage) writeController.clear();
    updateMessageDump(newMessage);
  }

  void updateMessageDump(Message message) async {
    var obj = new ParseObject(OBJECT_MESSAGE_DUMPS);
    message.id = obj.objectId;
    obj = objFromMap(obj, message.toMap());
    await obj.save().then((ParseResponse response) => print(
      (response.success) ? "message updated with id ${obj.objectId} and text ${message.message}" : response.error
    ));
  }

  void registerMessageListener() async {
    final newMessageQuery = QueryBuilder<ParseObject>(ParseObject(OBJECT_MESSAGE_DUMPS))
    ..whereEqualTo(MESSAGE_MESSAGE_DUMP, messageDumpUuid);



    //first time retrieval
    var response = await newMessageQuery.query();
    if (response.success && response.results != null) response.results.forEach((value) => _messageList.add(
      getParseMessage(value)
    ));
    else print(response.error);

    parseMessageSub = await liveQuery.client.subscribe(newMessageQuery)
    ..on(LiveQueryEvent.create, (value) async {
      var obj = value as ParseObject;
      final message = getParseMessage(value);

      setState(() => _messageList.add(message));

      if (!message.isRead && message.receiver == currentParseUserUid) {
        obj.set(MESSAGE_IS_READ, true);
        await obj.save().then(parseSaveCallback);
      }
    })
    ..on(LiveQueryEvent.update, (value) {
      final message = getParseMessage(value);
      int _modIndex = _messageList.indexWhere((msg) => msg.id == message.id);
      if (_modIndex != -1) setState(() => _messageList[_modIndex] = message);
    })
    ..on(LiveQueryEvent.delete, (value) {
      final message = getParseMessage(value);
      setState(() => _messageList.removeWhere((msg) => msg.id == message.id));
    });
  }

  setChatOn() async {
    /*
    realtimeDB.child(CHAT_USER_UID)
        .child(currentParseUserUid)
        .child(CHAT_IS_CHAT_ON)
        .set(YES);

     */
  }

  setChatOff() async {
    /*
    realtimeDB.child(CHAT_USER_UID)
        .child(currentParseUserUid)
        .child(CHAT_IS_CHAT_ON)
        .set(NO);

     */
  }
}