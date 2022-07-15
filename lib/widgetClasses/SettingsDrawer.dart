import 'dart:async';
import 'dart:convert';

import 'package:fleek/entry/SignInScreen.dart';
import 'package:fleek/global/globalFunctions.dart';
import 'package:fleek/global/globalItems.dart';
import 'package:fleek/settingsExtras/AccountChangeWidget.dart';
import 'package:fleek/settingsExtras/QnAWidget.dart';
import 'package:fleek/settingsExtras/PurchasesWidget.dart';
import 'package:fleek/values/dimens.dart';
import 'package:fleek/values/strings.dart';
import 'package:fleek/values/styles.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart' as UrlLauncher;
import 'package:progress_dialog/progress_dialog.dart';

class SettingsDrawer extends StatefulWidget {
  _SettingsDrawerState createState() => _SettingsDrawerState();
}

class _SettingsDrawerState extends State<SettingsDrawer> {
  StreamSubscription<bool> emailVerifiedListener;

  final _passwordKey = GlobalKey<FormState>();
  TextEditingController passwordController = new TextEditingController();
  bool _loginFailed = true;

  @override
  void dispose() {
      emailVerifiedListener?.cancel();
      passwordController.dispose();
    super.dispose();
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Settings'),
        centerTitle: true,
      ),
      body: Column(
        children: <Widget>[
          Expanded(
            child: ListView(
              children: <Widget>[
                //Support
                ExpansionTile(
                  title: styledText(Strings.settingsSupport),
                  children: <Widget>[
                    //FAQ
                    ListTile(
                      onTap: () => loadQnA(context, INFO_FAQ),
                      leading: Icon(Icons.help_outline),
                      title: styledText(Strings.settingsSupportFAQ),
                    ),

                    //Contact
                    ExpansionTile(
                      leading: Icon(Icons.contact_mail),
                      title: styledText(Strings.settingsSupportContact),
                      children: <Widget>[
                        //support email
                        ListTile(
                          onTap: () => UrlLauncher.launch("mailto:${localSettings.email}"),
                          leading: Icon(Icons.email),
                          title: styledText(localSettings.email),
                        ),

                        //support hotline
                        ListTile(
                          onTap: () => UrlLauncher.launch("tel:${localSettings.hotline}"),
                          leading: Icon(Icons.local_phone),
                          title: styledText(localSettings.hotline),
                        ),
                      ],
                    )
                  ],
                ),

                //General
                ExpansionTile(
                  title: styledText(Strings.settingsGeneral),
                  children: <Widget>[
                    //notifs
                    ExpansionTile(
                      leading: Icon(Icons.notifications_active),
                      title: styledText(Strings.settingsGeneralNotifs),
                      children: <Widget>[
                        //message notifs
                        ListTile(
                          leading: Icon(Icons.message),
                          title: styledText(Strings.settingsGeneralNotifsMessages),
                          trailing: SizedBox(
                            width: Dimens.switchSizeSmall*1.2,
                            height: Dimens.switchSizeSmall,
                            child: Switch(
                              onChanged: notifsMessageSwitch,
                              value: localSettings.messageNotifsOn,
                            ),
                          ),

                        ),
                      ],
                    ),

                    //account settings (email only)
                    if (localSettings.providerID == "password") ExpansionTile(
                      leading: Icon(Icons.account_circle),
                      title: styledText(Strings.settingsGeneralAccount),
                      children: <Widget>[
                        verifiedTile(),
                        ListTile(
                          onTap: () => loadAccountChange(context, EMAIL),
                          leading: Icon(Icons.alternate_email),
                          title: styledText(Strings.settingsGeneralAccountEmail),
                        ),
                        ListTile(
                          onTap: () => loadAccountChange(context, PASSWORD),
                          leading: Icon(Icons.settings_ethernet),
                          title: styledText(Strings.settingsGeneralAccountPassword),
                        ),
                      ],
                    ),


                    //delete account
                    ListTile(
                      onTap: () => loadDeleteAccount(context),
                      leading: Icon(Icons.delete),
                      title: styledText(Strings.settingsGeneralAccountDelete),
                    ),
                  ],
                ),

                //listing related
                ExpansionTile(
                  title: styledText(Strings.settingsListings),
                  children: <Widget>[
                    //Past Purchases
                    ListTile(
                      onTap: () => loadPurchases(context),
                      leading: Icon(Icons.shopping_cart),
                      title: styledText(Strings.settingsListingsPurchases),
                    ),

                    //Selling Tutorial
                    ListTile(
                      onTap: () => loadHow(context),
                      leading: Icon(Icons.help_outline),
                      title: styledText(Strings.settingsListingsHow),
                    ),

                    //Community Guidelines
                    ListTile(
                      onTap: () => loadQnA(context, INFO_CG),
                      leading: Icon(Icons.help_outline),
                      title: styledText(Strings.settingsListingsGuidelines),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Container(
            child: Align(
              alignment: FractionalOffset.bottomCenter,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.center,
                mainAxisAlignment: MainAxisAlignment.end,
                children: <Widget>[
                  //about
                  ListTile(
                    onTap: () => loadAbout(context),
                    leading: Icon(Icons.info),
                    title: styledText(Strings.settingsAbout),
                  ),
                  //sign out
                  ListTile(
                    onTap: () => signOut(context),
                    title: styledText(Strings.settingsSignOut),
                  ),
                ],
              ),
            ),
          )
        ],
      ),
    );
  }

  Text styledText(String text) {
    return Text(
      text,
    );
  }

  ListTile verifiedTile() {
    void verifyEmail() async {
      /*
      print("attempting to verify email");
      intervalRefreshAuth(5);

      currentUser.sendEmailVerification().whenComplete(() {
        emailVerifiedListener = aEmailVerified.stream.listen((isVerified) {
          if (isVerified) setState(() {
            localSettings.verificationSent = false;
            localSettings.emailVerified = true;
          });
        });

        setState(() {
          localSettings.verificationSent = true;
        });
      });

       */
    }

    if (localSettings.verificationSent) {
      return ListTile(
        leading: Icon(Icons.file_upload),
        title: styledText("A verification email has been sent. Please check your inbox."),
      );
    }

    bool isVerified = currentParseUser.emailVerified;
    isVerified ??= false;
    final Icon icon = isVerified
    ? Icon(Icons.check)
    : Icon(Icons.clear);
    final String text = isVerified
    ? "Email is verified."
    : "Click here to verify your email.";

    return ListTile(
      onTap: isVerified ? null : verifyEmail,
      leading: icon,
      title: styledText(text),
      subtitle: styledText("current e-mail: ${currentParseUser.emailAddress}"),
    );
  }
  void loadQnA(BuildContext context, String name) async {
    String title = (name == INFO_FAQ) ? 'FAQ' : 'Community Guidelines';
    final ld = styleDialog(getLoadingDialog(context), "Loading $title...");
    await ld.show();

    final downloadUrl = await getInfoUrl(name);
    if (downloadUrl.isEmpty) return;
    String response = (await http.get(downloadUrl)).body;
    List<dynamic> faqList = jsonDecode(response);
    await ld.hide();
    Navigator.push(context, MaterialPageRoute(
      builder: (context) => QnAWidget(
        title: title,
        faqList: faqList,
      ),
    ));
  }

  void notifsMessageSwitch(bool isOn) async {
    /*
    realtimeDB.child(CHAT_USER_UID)
        .child(currentUserUid)
        .child(CHAT_IS_NOTIFS_ENABLED)
        .set(isOn ? YES : NO)
        .whenComplete(() {
          setState(() {
            localSettings.messageNotifsOn = isOn;
          });
    });

     */
  }

  void loadAccountChange(BuildContext context, String type) {
    Navigator.push(context, MaterialPageRoute(
      builder: (context) => AccountChangeWidget(type: type,),
    ));
  }

  void loadPurchases(BuildContext context) {
    Navigator.push(context, MaterialPageRoute(
      builder: (context) => PurchasesWidget(),
    ));
  }

  void loadHow(BuildContext context) {

  }

  void loadAbout(BuildContext context) async {

  }

  void loadDeleteAccount(BuildContext context) {
    showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: new Text("Are you sure?"),
            content: new Text("Deleting your account is irreversible!"),
            actions: <Widget>[
              new FlatButton(
                onPressed: () => defaultDialogFunction(context),
                child: new Text("Cancel"),
              ),
              new FlatButton(
                onPressed: () async {
                  Navigator.pop(context);
                  await showLoginDialog(context);
                  if (!_loginFailed) deleteAccount(context);
                },
                child: new Text("OK"),
              ),
            ],
          );
        }
    );
  }

  void deleteAccount(BuildContext context) async {

  }
  /*
  void deleteAccount(BuildContext context) async {
    print("delete invoked");
    globalDialog = styleDialog(globalDialog, "Deleting user data...");
    await globalDialog.show();

    List<WriteBatch> batches = [db.batch()];
    int batchIndex = 0;

    //delete user documents
    batches[batchIndex].delete(userCollectionRef.document(currentUserUid));
    int batchCounter = 1;

    void addToBatch(DocumentReference docRef, String type, Map<String, dynamic> updateData) {
      if (batchCounter > 498) {
        batches.add(db.batch());
        batchCounter = 0;
        batchIndex += 1;
      }
      
      switch (type) {
        case ('d'): {
          batches[batchIndex].delete(docRef);
        }
        break;
        case ('u'): {
          batches[batchIndex].updateData(docRef, updateData);
        }
        break;
      }
      batchCounter += 1;
    }

    //delete reviews from others' json files
    currentUserCollection.bought.forEach((id) {
      deleteUserFromReview(currentUserUid, shopCollection[id].seller);
    });
    currentUserCollection.sold.forEach((id) {
      deleteUserFromReview(currentUserUid, shopCollection[id].buyer);
    });

    void ioExceptionHandler(Object errorObject) {
      PlatformException error = errorObject as PlatformException;
      print(error.code);
    }

    //delete reviews and profile photo from storage
    await storage.child("reviews/$currentUserUid.json").delete().catchError(ioExceptionHandler);
    await storage.child("images/profile/$currentUserUid.jpg").delete().catchError(ioExceptionHandler);

    //delete shop collection posts and storage images
    currentUserCollection.selling.forEach((id) {
      Product product = shopCollection[id];
      //deleting images from storage
      product.imageUUIDs.forEach((image) async {
        await storage.child("images/$currentUserUid/shop/$image.jpg").delete().catchError(ioExceptionHandler);
      });

      //deleting id from all user collections who liked it
      product.likedBy.forEach((uid) {
        addToBatch(userCollectionRef.document(uid), 'u', {
          USER_LIKED_PRODUCTS : FieldValue.arrayRemove([id]),
        });
      });

      //delete from buyer collection if bought
      if (product.isSold) addToBatch(userCollectionRef.document(product.buyer), 'u', {
        USER_BOUGHT : FieldValue.arrayRemove([id]),
      });
      
      //deleting shop item
      addToBatch(shopRef.document(id), 'd', null);

    });
    
    //delete social collection posts and storage images
    currentUserCollection.posted.forEach((id) {
      Post post = socialCollection[id];
      //deleting image from storage
      storage.child("images/$currentUserUid/social/${post.imageUUID}.jpg").delete().catchError(ioExceptionHandler);
      //deleting id from all user collections who liked it
      post.likedBy.forEach((uid) {
        addToBatch(userCollectionRef.document(uid), 'u', {
          USER_LIKED_POSTS : FieldValue.arrayRemove([id]),
        });
      });

      //deleting social item
      addToBatch(socialRef.document(id), 'd', null);
    });

    //delete uid from liked products and posts
    currentUserCollection.likedProducts.forEach((id) {
      addToBatch(shopRef.document(id), 'u', {
        SHOP_LIKED_BY_LIST : FieldValue.arrayRemove([currentUserUid]),
      });
    });

    currentUserCollection.likedPosts.forEach((id) {
      addToBatch(socialRef.document(id), 'u', {
        SOCIAL_LIKED_BY : FieldValue.arrayRemove([currentUserUid]),
      });
    });
    
    //delete chats

    //delete message dumps
    DatabaseReference userNode = realtimeDB.child(CHAT_USER_UID).child(currentUserUid);

    void deleteMessageDump(DataSnapshot data) {
      if (data.value != null) {
        Map<String, dynamic> dataMap = new Map<String, dynamic>.from(data.value);
        dataMap.keys.forEach((uid) async {
          Map<String, String> childMap = new Map<String, String>.from(dataMap[uid]);
          String messageDumpUid = childMap[CHAT_MESSAGE_DUMP];
          String productId = childMap[CHAT_PRODUCT_ID];
          realtimeDB.child(CHAT_MESSAGE_DUMP).child(messageDumpUid).remove();

          //delete node for user
          realtimeDB.child(CHAT_USER_UID).child(uid).child(
            shopCollection[productId].buyer == uid
                ? CHAT_BUYING
                : CHAT_SELLING
          ).child(currentUserUid).remove();
        });
      }
    }
    userNode.child(CHAT_BUYING).once().then(deleteMessageDump);
    userNode.child(CHAT_SELLING).once().then(deleteMessageDump);

    //delete all chat images sent
    storage.child('chat/$currentUserUid').delete().catchError(ioExceptionHandler);
    //delete user node from realtimeDB
    await userNode.remove();

    print("final combined batch size: ${batchIndex*499 + batchCounter}");
    batches.forEach((batch) async {
      await batch.commit();
      print("batch ${batches.indexOf(batch) + 1} uploaded.");
    });

    await currentUser.delete();
    await globalDialog.hide();
    Navigator.pop(context);
  }
  */

  void signOut(BuildContext context) async {
    ProgressDialog ld = getLoadingDialog(context);
    ld = styleDialog(ld, "Signing you out...");
    await ld.show();
    await currentParseUser.logout(deleteLocalUserData: true);
    aParseUserChanged.add(currentParseUser);
    await ld.hide();
    Navigator.pop(context);
  }

  Future<void> showLoginDialog(BuildContext context) {
    void login(BuildContext context) async {
      void error() => showDialogWithMessage(context, "Login failed, please try again.", "Error signing you in");
      if (_passwordKey.currentState.validate()) {
        ProgressDialog ld = styleDialog(getLoadingDialog(context), "Verifying...");

        await ld.show();
        await currentParseUser.login();
        passwordController.clear();
        await ld.hide();

        if (currentParseUser != null) {
          await parseRefreshUser();
          _loginFailed = false;
          Navigator.pop(context);
        }
        else {
          _loginFailed = true;
          error();
        }
      }
    }

    if (localSettings.providerID == PROVIDER_GOOGLE) {
      return googleAuth(GoogleSignIn(),);
    }

    return showDialog<void>(
        context: context,
        barrierDismissible: true,
        builder: (BuildContext context) {
          return AlertDialog(
            title: Text("Please enter your current password to continue: "),
            content: Form(
              key: _passwordKey,
              child: TextFormField(
                keyboardType: TextInputType.visiblePassword,
                obscureText: true,
                controller: passwordController,
                validator: passwordValidator,
                decoration: InputDecoration(
                  hintText: Strings.labelTextPassword,
                  border: Styles.inputBorder,
                ),
              ),
            ),

            actions: <Widget>[
              new FlatButton(
                onPressed: () {
                  Navigator.pop(context);
                },
                child: Text("Cancel"),
              ),
              new FlatButton(
                onPressed: () => login(context),
                child: Text(Strings.buttonSubmit),
              ),
            ],
          );
        }
    );
  }
}