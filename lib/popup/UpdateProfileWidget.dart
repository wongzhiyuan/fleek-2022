import 'dart:io';
import 'dart:typed_data';

import 'package:fleek/dataclasses/PUser.dart';
import 'package:fleek/global/globalFunctions.dart';
import 'package:fleek/global/globalItems.dart';
import 'package:fleek/values/colors.dart';
import 'package:fleek/values/dimens.dart';
import 'package:fleek/values/ints.dart';
import 'package:fleek/values/strings.dart';
import 'package:fleek/values/styles.dart';
import 'package:flutter/material.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:image_picker/image_picker.dart';
import 'package:parse_server_sdk/parse_server_sdk.dart';
import 'package:profanity_filter/profanity_filter.dart';
import 'package:progress_dialog/progress_dialog.dart';
import 'package:uuid/uuid.dart';

import '../main.dart';

class UpdateProfileWidget extends StatefulWidget {
  final String title = "Update Profile";
  final String updateProfileIntent;

  UpdateProfileWidget({this.updateProfileIntent});

  _UpdateProfileState createState() => _UpdateProfileState();
}

class _UpdateProfileState extends State<UpdateProfileWidget> {
  final _updateProfileKey = GlobalKey<FormState>();
  final usernameController = TextEditingController();
  final bioController = TextEditingController();
  String updateProfileIntent;

  File _profileImage;

  @override
  void initState() {
    super.initState();
    updateProfileIntent = widget.updateProfileIntent;
    if (intentMap.containsKey(INTENT_UPDATE_PROFILE)) updateProfileIntent = intentMap[INTENT_UPDATE_PROFILE];
  }
  @override
  void dispose() {
    usernameController.dispose();
    bioController.dispose();

    super.dispose();
  }
  @override
  Widget build(BuildContext context) {
    final imageWidth = Dimens.imageSizeBig;
    final paddingTop = EdgeInsets.only(top: Dimens.paddingFormTop);

    return Scaffold(
      body: Center(
        child: Padding(
          padding: EdgeInsets.all(Dimens.paddingUpdateProfileColumn),
          child: ListView(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            children: <Widget>[
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  Text(
                    Strings.updateProfileHeader,
                    style: Styles.listHeader,
                  ),
                ],
              ),

              Padding(
                padding: paddingTop,
                child: ConstrainedBox(
                  constraints: BoxConstraints.expand(width: imageWidth, height: imageWidth,),
                  child: InkWell(
                    onTap: selectImage,
                    child: tryImageLoad(imageWidth),
                  ),
                ),
              ),
              Padding(
                padding: paddingTop,
                child: Form(
                  key: _updateProfileKey,
                  child: ListView(
                    shrinkWrap: true,
                    children: <Widget>[
                      TextFormField(
                        initialValue: null,
                        autovalidate: true,
                        validator: usernameValidator,
                        controller: usernameController,
                        decoration: InputDecoration(
                          labelText: Strings.labelTextDisplayName,
                          hintText: Strings.hintUsername,
                          border: Styles.inputBorder,
                        ),
                      ),
                      Padding(
                        padding: paddingTop,
                        child: TextFormField(
                          validator: bioValidator,
                          controller: bioController,
                          maxLength: Ints.updateProfileMaxLengthBio,
                          maxLengthEnforced: true,
                          decoration: InputDecoration(
                            labelText: Strings.labelTextBio,
                            hintText: Strings.hintBio,
                            alignLabelWithHint: true,
                            border: Styles.inputBorder,
                          ),
                          minLines: 3,
                          maxLines: 5,
                        ),
                      ),
                      Padding(
                        padding: paddingTop,
                        child: ButtonTheme(
                          minWidth: double.infinity,
                          child: RaisedButton(
                            color: CustomColors.colorPrimary,
                            child: Text(Strings.buttonSubmit,
                            style: Styles.submitButton,),
                            onPressed: () {submitProfile(context);},
                          ),
                        ),
                      )
                    ],
                  ),
                ),
              )
            ],
          ),
        ),
      ),
    );

  }

  Future<void> selectImage() async {
    File image = await ImagePicker.pickImage(source: ImageSource.gallery,);

    setState(() {
      _profileImage = image;
    });
  }

  Widget tryImageLoad(double side) {
    if (_profileImage == null) {
      return CircleAvatar(
        child: Text(Strings.promptSelectImage, style: Styles.prompt,),
        backgroundColor: CustomColors.colorGreyedOut,
        radius: side/2,
      );
    }
    else {
      return Align(
        alignment: Alignment.center,
        child: CircleAvatar(
          radius: side/2,
          backgroundImage: Image.file(
            _profileImage,
            width: side,
            height: side,
          ).image,
          backgroundColor: Colors.transparent,
        ),
      );
    }
  }

  void submitProfile(BuildContext context) async {
    ProgressDialog ld = getLoadingDialog(context);
    ld = styleDialog(ld, "Updating Profile...");

    void uploadComplete() async {
      _updateProfileKey.currentState.reset();
      await ld.hide();
    }

    var form = _updateProfileKey.currentState;
    if (form.validate() && _profileImage != null) {
      await ld.show();
      String username = usernameController.text.toString();
      String bio = bioController.text.toString();

      List<int> imageAsList = await FlutterImageCompress.compressWithFile(
        _profileImage.absolute.path,
        quality: 50,
      );
      Uint8List imageData = Uint8List.fromList(imageAsList);
      File imageFile = File(getTempImgPath());
      imageFile.writeAsBytes(imageData);
      ParseFile parseImage = new ParseFile(imageFile);

      switch (updateProfileIntent) {
        case (INTENT_UPDATE_PROFILE_NEW_USER): {
          //new user: make new user collection
          final List<String> emptyList = [];
          final String emptyString = "";

          PUser parseUser = new PUser()..init(
            currentParseUserUid,
            username,
            parseImage,
            bio,
            emptyList,
            emptyList,
            emptyList,
            emptyList,
            emptyList,
            emptyString,
            emptyString,
            emptyList,
            emptyList,
            emptyList,
            emptyList,
            emptyList,
            emptyList,
          );

          var object = objFromMap(new ParseObject(OBJECT_USER_DATA), parseUser.toMap());
          var response = await object.save();
          if (response.success) {
            currentParseUser.set(USER_HAS_DATA, true);
            await currentParseUser.save().then((ParseResponse response) async {
              (response.success) ? aParseUserChanged.add(currentParseUser) : print(response.error);
              await ld.hide();
            });
          }
          else {
            print(response.error);
          }
        }
        break;

        case (INTENT_UPDATE_PROFILE_EXISTING_USER): {
          //existing user: update user collection
          Map<String, dynamic> parseUpdateMap = {
            USER_DISPLAY_NAME : username,
            USER_PROFILE_PICTURE_URI : parseImage,
            USER_BIO : bio,
          };

          var result = await getUserDataObject(currentParseUserUid);
          if (result.success) {
            var dataObj = objFromMap(result.object, parseUpdateMap);
            await dataObj.save().then(parseSaveCallback);
            await ld.hide();
          }
        }
        break;

        default: {
          //something went wrong
          print("no intent detected");
        }
        break;
      }
    }


  }
}

String usernameValidator (String value) {
  RegExp charactersCheck = new RegExp(
    r"(\W|[A-Z])",
    caseSensitive: true,
    multiLine: false,
  );
  if (value.isEmpty) return Strings.errorEmpty;
  else if (takenDisplayNames.containsValue(value)) return Strings.errorUsernameTaken;
  else if (charactersCheck.hasMatch(value)) return Strings.errorSpecialChar;
  else if (ProfanityFilter().checkStringForProfanity(value)) return Strings.errorProfanity;

  else return null;
}

String bioValidator (String value) {
  if (ProfanityFilter().checkStringForProfanity(value)) return Strings.errorProfanity;
  else return null;
}