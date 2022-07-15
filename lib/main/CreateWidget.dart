import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:carousel_slider/carousel_slider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fleek/dataclasses/Hashtag.dart';
import 'package:fleek/dataclasses/PPost.dart';
import 'package:fleek/dataclasses/PProduct.dart';
import 'package:fleek/dataclasses/Post.dart';
import 'package:fleek/dataclasses/Product.dart';
import 'package:fleek/global/globalFunctions.dart';
import 'package:fleek/global/globalItems.dart';
import 'package:fleek/values/Keys.dart';
import 'package:fleek/values/animInfo.dart';
import 'package:fleek/values/colors.dart';
import 'package:fleek/values/dimens.dart';
import 'package:fleek/values/ints.dart';
import 'package:fleek/values/shadows.dart';
import 'package:fleek/values/strings.dart';
import 'package:fleek/values/styles.dart';
import 'package:fleek/widgetClasses/AutoGreyDropdownFormField.dart';
import 'package:fleek/widgetClasses/AutoGreyTextFormField.dart';
import 'package:fleek/widgetClasses/FlexibleSpaceTabBar.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_chips_input/flutter_chips_input.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:image_picker/image_picker.dart';
import 'package:multi_image_picker/multi_image_picker.dart';
import 'package:multiselect_formfield/multiselect_formfield.dart';
import 'package:parse_server_sdk/parse_server_sdk.dart';
import 'package:path_provider/path_provider.dart';
import 'package:progress_dialog/progress_dialog.dart';
import 'package:uuid/uuid.dart';

class CreateWidget extends StatefulWidget {
  final String title = "Create";

  _CreateWidgetState createState() => _CreateWidgetState();
}

class _CreateWidgetState extends State<CreateWidget> {
  final cornerRadius = BorderRadius.circular(20.0);

  final paddingCreateRow = Dimens.paddingCreateRow;
  final paddingFormTop = EdgeInsets.only(top: Dimens.paddingFormTop);
  final paddingFormTopBelowCounter = EdgeInsets.only(top: Dimens.paddingFormTopBelowCounter);

  List<Asset> _productImages = List<Asset>();
  File _postImage;

  String gender;

  Map<String, List<String>> startingDropdownItems = Map();
  Map<String, List<String>> postDropdownItems = Map();

  Map<String, String> dropdownSelections = Map();
  Map<String, String> postDropdownSelections = Map();
  List<Hashtag> _productHashtagList = [];
  List<Hashtag> _postHashtagList = [];
  List<String> _stylesSelection = [];
  List<String> _postStylesSelection = [];

  final _productFormKey = GlobalKey<FormState>();
  final _postFormKey = GlobalKey<FormState>();
  TextEditingController productTitleController, productPriceController, productDescriptionController;
  TextEditingController postTitleController;
  final productScrollController = new ScrollController();
  final postScrollController = new ScrollController();

  bool productTitleFocus = false;

  final double viewportFraction = Ints.carouselViewportFraction;
  @override
  void initState() {
    super.initState();

    productTitleController = new TextEditingController();
    productPriceController = new TextEditingController();
    productDescriptionController = new TextEditingController();
    postTitleController = new TextEditingController();
    startingDropdownItems = {
      SHOP_SIZE : defaultSettings.sizes,
      SHOP_CAT : defaultSettings.mCatsList,
      SHOP_TYPE : defaultSettings.typesList,
      SHOP_STYLES_LIST : defaultSettings.stylesList,
      SHOP_ITEM_CONDITION : defaultSettings.productConditions,
      SHOP_GENDER : defaultGenders,
    };

    postDropdownItems = {
      SHOP_GENDER : defaultGenders,
      SHOP_CAT : defaultSettings.mCatsList,
      SOCIAL_TYPE : defaultSettings.typesList,
      SOCIAL_STYLES_LIST : defaultSettings.stylesList,
    };
  }
  @override
  void dispose() {
    productTitleController.dispose();
    productPriceController.dispose();
    productDescriptionController.dispose();
    postTitleController.dispose();

    productScrollController.dispose();
    postScrollController.dispose();
    super.dispose();
  }
  @override
  Widget build(BuildContext context) {
    final screenWidth = getScreenWidth(context);

    return DefaultTabController(
        length: 2,
        child: Scaffold(
          appBar: AppBar(
            backgroundColor: CustomColors.colorPrimary,
            flexibleSpace: FlexibleSpaceTabBar(
              tabs: <Widget>[
                Text(Strings.tabLabelCreateProduct),
                Text(Strings.tabLabelCreatePost),
              ],
            ),
          ),

          body: TabBarView(
            children: <Widget>[
              productWidget(screenWidth),
              postWidget(screenWidth),
            ],
          ),
        )
    );
  }

  Widget productWidget(double screenWidth) {
    int imagesLength = _productImages.length;
    double sideDouble = (screenWidth * viewportFraction);
    int imageSide = sideDouble.toInt();

    void scrollToMax() => productScrollController.position.animateTo(
      productScrollController.position.maxScrollExtent,
      duration: const Duration(milliseconds: AnimInfo.createProductMillis),
      curve: AnimInfo.createProductCurve,
    );

    void delayedScroll() => Timer(Duration(milliseconds: AnimInfo.createProductDelayMillis), scrollToMax);


    Widget priceSizeCondition() {
      return new Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          CreateTitle(
            title: Strings.labelTextPrice,
          ),
          //Price field
          AutoGreyTextFormField(
            padding: paddingFormTop,
            controller: productPriceController,
            validator: notEmptyValidator,
            keyboardType: TextInputType.number,
          ),

          //Size
          AutoGreyDropdownFormField(
            validator: notEmptyValidator,
            padding: paddingFormTop,
            labelText: Strings.labelTextDropdownSize,
            onChanged: (String value) {
              setState(() {
                dropdownSelections[SHOP_SIZE] = value;
              });

              delayedScroll();
            },
            items: startingDropdownItems[SHOP_SIZE],
          ),

          //Item Condition
          AutoGreyDropdownFormField(
            validator: notEmptyValidator,
            padding: paddingFormTop,
            labelText: Strings.labelTextDropdownCondition,
            onChanged: (String value) {
              setState(() {
                dropdownSelections[SHOP_ITEM_CONDITION] = value;
              });

              delayedScroll();
            },
            items: startingDropdownItems[SHOP_ITEM_CONDITION],
          ),
        ],
      );
    }

    Widget descriptionStylesSubmit() {
      return new Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          //Description field
          CreateTitle(
            title: Strings.labelTextDescription,
          ),

          AutoGreyTextFormField(
            padding: paddingFormTop,
            controller: productDescriptionController,
            validator: notEmptyValidator,
            keyboardType: TextInputType.text,
            maxLengthEnforced: true,
            maxLength: Ints.createProductMaxLengthDescription,
            hintText: Strings.hintDescription,
            minLines: 10,
            maxLines: 15,
          ),

          //Hashtags Selection
          chipsInput(Keys.createProductHashtagKey, true),

          //styles dropdown
          Padding(
            padding: paddingFormTop,
            child: MultiSelectFormField(
              titleText: Strings.labelTextDropdownStyles,
              hintText: Strings.hintDropdownStyles,
              border: Styles.inputBorder,
              dataSource: startingDropdownItems[SHOP_STYLES_LIST].map((String value) {
                return {
                  "display" : value,
                  "value" : value,
                };
              }).toList(),
              textField: "display",
              valueField: "value",
              okButtonLabel: "SUBMIT",
              cancelButtonLabel: "CANCEL",
              initialValue: _stylesSelection,
              onSaved: (value) {
                if (value != null) _stylesSelection = new List<String>.from(value);
                print(_stylesSelection);
              },
            ),
          ),

          //Submit button
          Padding(
            padding: paddingFormTopBelowCounter,
            child: ButtonTheme(
              minWidth: double.infinity,
              child: RaisedButton(
                color: CustomColors.colorPrimary,
                child: Text(
                  Strings.buttonSubmit,
                  style: Styles.submitButton,
                ),
                onPressed: () => productFormSubmit(context),
              ),
            ),
          ),
        ],
      );
    }

    final shadowAdjust = (Shadows.main.spreadRadius + Shadows.main.blurRadius) * 2;
    return new ListView(
      controller: productScrollController,
      shrinkWrap: true,
      children: <Widget>[
        //image carousel
        Padding(
          padding: EdgeInsets.only(top: paddingCreateRow),
          child: CarouselSlider.builder(
            itemCount: Ints.createProductMaxImages,
            itemBuilder: (BuildContext context, int index) {
              InkWell tapHandler(Widget child) {
                final adjusted = sideDouble + shadowAdjust;
                return new InkWell(
                  onTap: loadProductImages,
                  child: Container(
                    width: adjusted,
                    height: adjusted,
                    padding: EdgeInsets.all(shadowAdjust),
                    child: Container(
                      decoration: BoxDecoration(
                        boxShadow: [Shadows.main],
                        borderRadius: cornerRadius,
                        color: CustomColors.colorPrimaryDark,
                      ),
                      child: ClipRRect(
                        borderRadius: cornerRadius,
                        child: child,
                      ),
                    ),
                  ),
                );
              }

              return tapHandler(
                (index < imagesLength)
                    ? AssetThumb(
                  asset: _productImages[index],
                  width: imageSide,
                  height: imageSide,
                )
                    : Container(
                  width: sideDouble,
                  height: sideDouble,
                  color: CustomColors.colorPrimary,
                  child: Icon(
                    Icons.add_circle,
                    color: CustomColors.createGrey,
                    size: Dimens.createAddIconSide,
                  ),
                ),
              );
            },
            options: CarouselOptions(
              height: sideDouble + shadowAdjust,
              viewportFraction: Ints.carouselViewportFraction,
              initialPage: 0,
              enableInfiniteScroll: false,
              reverse: false,
              autoPlay: false,
              enlargeCenterPage: true,
              scrollDirection: Axis.horizontal,
            ),
          ),
        ),

        //rest of form
        Container(
          padding: EdgeInsets.all(paddingCreateRow),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              //clear all images button
              Align(
                alignment: Alignment.topCenter,
                child: RaisedButton.icon(
                  disabledColor: CustomColors.createGrey,
                  color: CustomColors.colorPrimary,
                  shape: Styles.roundedButtonShape,
                  icon: Icon(Icons.delete,),
                  label: Text("Clear all images"),
                  onPressed: (_productImages.length > 0) ? () => setState(() {
                    _productImages.clear();
                  }) : null,
                ),
              ),

              //main form
              Form(
                key: _productFormKey,
                child: ListView(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  children: <Widget>[
                    //Title
                    CreateTitle(
                      title: Strings.labelTextTitle,
                    ),
                    AutoGreyTextFormField(
                      hintText: Strings.hintTitle,
                      padding: paddingFormTop,
                      controller: productTitleController,
                      validator: notEmptyValidator,
                      keyboardType: TextInputType.text,
                      maxLengthEnforced: true,
                      maxLength: Ints.createMaxLengthTitle,
                    ),

                    //Gender picker
                    AutoGreyDropdownFormField(
                      padding: paddingFormTopBelowCounter,
                      labelText: Strings.labelTextDropdownGender,
                      onChanged: (value) {
                        setState(() {
                          gender = value;
                          dropdownSelections[SHOP_GENDER] = value;
                          startingDropdownItems[SHOP_CAT] = (value == FILTER_GENDER_FEMALE)
                              ? defaultSettings.fCatsList
                              : defaultSettings.mCatsList;
                        });

                        delayedScroll();
                      },
                      items: startingDropdownItems[SHOP_GENDER],
                    ),

                    //cat picker
                    if (dropdownSelections.containsKey(SHOP_GENDER)) AutoGreyDropdownFormField(
                      padding: paddingFormTop,
                      labelText: Strings.labelTextDropdownCat,
                      onChanged: (value) {
                        if (Keys.createProductTypeKey.currentState != null) Keys.createProductTypeKey.currentState.reset();

                        setState(() {
                          List<String> typeList = getTypeList(gender, value);
                          dropdownSelections.remove(SHOP_TYPE);
                          startingDropdownItems[SHOP_TYPE] = typeList;
                          dropdownSelections[SHOP_CAT] = value;
                        });

                        delayedScroll();
                      },
                      items: startingDropdownItems[SHOP_CAT],
                    ),

                    if (dropdownSelections.containsKey(SHOP_CAT)) AutoGreyDropdownFormField(
                      padding: paddingFormTop,
                      labelText: Strings.labelTextDropdownType,
                      onChanged: (value) {
                        setState(() {
                          print(value);
                          dropdownSelections[SHOP_TYPE] = value;
                        });

                        delayedScroll();
                      },
                      items: startingDropdownItems[SHOP_TYPE],
                      isType: true,
                    ),

                    if (dropdownSelections.containsKey(SHOP_TYPE)) priceSizeCondition(),
                    if (dropdownSelections.containsKey(SHOP_SIZE) &&
                        dropdownSelections.containsKey(SHOP_ITEM_CONDITION) &&
                        productPriceController.text.isNotEmpty
                    ) descriptionStylesSubmit(),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget postWidget(double screenWidth) {
    double imageWidth = screenWidth;

    void scrollToMax() => postScrollController.position.animateTo(
      postScrollController.position.maxScrollExtent,
      duration: const Duration(milliseconds: AnimInfo.createProductMillis),
      curve: AnimInfo.createProductCurve,
    );

    void delayedScroll() => Timer(Duration(milliseconds: AnimInfo.createProductDelayMillis), scrollToMax);

    return ConstrainedBox(
      constraints: BoxConstraints.expand(),
      child: ListView(
        controller: postScrollController,
        shrinkWrap: true,
        children: <Widget>[
          //image selector
          tryImageLoading(_postImage, imageWidth),

          //form
          Form(
            key: _postFormKey,
            child: Padding(
              padding: EdgeInsets.all(paddingCreateRow),
              child: ListView(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                children: <Widget>[
                  CreateTitle(
                    title: Strings.labelTextTitle,
                    noPadding: true,
                  ),
                  AutoGreyTextFormField(
                    validator: notEmptyValidator,
                    padding: paddingFormTop,
                    controller: postTitleController,
                    maxLength: Ints.createMaxLengthTitle,
                    maxLengthEnforced: true,
                    keyboardType: TextInputType.text,
                    hintText: Strings.hintTitle,
                  ),

                  //Gender picker
                  AutoGreyDropdownFormField(
                    padding: paddingFormTopBelowCounter,
                    labelText: Strings.labelTextDropdownGender,
                    onChanged: (value) {
                      setState(() {
                        postDropdownSelections[SHOP_GENDER] = value;
                        postDropdownItems[SHOP_CAT] = (value == FILTER_GENDER_FEMALE)
                            ? defaultSettings.fCatsList
                            : defaultSettings.mCatsList;
                      });

                      delayedScroll();
                    },
                    items: postDropdownItems[SHOP_GENDER],
                  ),

                  //cat picker
                  if (postDropdownSelections.containsKey(SHOP_GENDER)) AutoGreyDropdownFormField(
                    padding: paddingFormTop,
                    labelText: Strings.labelTextDropdownCat,
                    onChanged: (value) {
                      if (Keys.createPostTypeKey.currentState != null) Keys.createPostTypeKey.currentState.reset();

                      setState(() {
                        List<String> typeList = getTypeList(postDropdownSelections[SHOP_GENDER], value);
                        postDropdownSelections.remove(SOCIAL_TYPE);
                        postDropdownItems[SOCIAL_TYPE] = typeList;
                        postDropdownSelections[SHOP_CAT] = value;
                      });

                      delayedScroll();
                    },
                    items: postDropdownItems[SHOP_CAT],
                  ),

                  if (postDropdownSelections.containsKey(SHOP_CAT)) AutoGreyDropdownFormField(
                    padding: paddingFormTop,
                    labelText: Strings.labelTextDropdownType,
                    onChanged: (value) {
                      setState(() {
                        print(value);
                        postDropdownSelections[SOCIAL_TYPE] = value;
                      });

                      delayedScroll();
                    },
                    items: postDropdownItems[SOCIAL_TYPE],
                    isType: true,
                    isPost: true,
                  ),

                  if (postDropdownSelections.containsKey(SOCIAL_TYPE)) chipsInput(
                    Keys.createPostHashtagKey,
                    false,
                  ),

                  if (postDropdownSelections.containsKey(SOCIAL_TYPE)) Padding(
                    padding: paddingFormTop,
                    child: MultiSelectFormField(
                      titleText: Strings.labelTextDropdownStyles,
                      hintText: Strings.hintDropdownStyles,
                      border: Styles.inputBorder,
                      dataSource: startingDropdownItems[SHOP_STYLES_LIST].map((String value) {
                        return {
                          "display" : value,
                          "value" : value,
                        };
                      }).toList(),
                      textField: "display",
                      valueField: "value",
                      okButtonLabel: "SUBMIT",
                      cancelButtonLabel: "CANCEL",
                      initialValue: _postStylesSelection,
                      onSaved: (value) {
                        if (value != null) _postStylesSelection = new List<String>.from(value);
                        print(_postStylesSelection);
                      },
                    ),
                  ),

                  //Submit button
                  if (postDropdownSelections.containsKey(SOCIAL_TYPE)) Padding(
                    padding: paddingFormTopBelowCounter,
                    child: ButtonTheme(
                      minWidth: double.infinity,
                      child: RaisedButton(
                        color: CustomColors.colorPrimary,
                        child: Text(
                          Strings.buttonSubmit,
                          style: Styles.submitButton,
                        ),
                        onPressed: () {postFormSubmit(context);},
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> loadProductImages() async {
    setState(() {
      _productImages = List<Asset>();
    });

    List<Asset> resultList;

    try {
      resultList = await MultiImagePicker.pickImages(
        maxImages: Ints.createProductMaxImages,
        enableCamera: true,
      );
    } on Exception catch (e) {
      print(e);
    }

    if (!mounted) return;

    setState(() {
      _productImages = resultList == null ? [] : resultList;
    });
  }

  Future<void> loadPostImages() async {
    File image = File((await ImagePicker().getImage(
      source: ImageSource.gallery,
    )).path);

    setState(() {
      _postImage = image;
    });
  }

  Widget tryImageLoading(File image, double side) {
    if (image == null) {
      return emptyImageContainer(side, SOCIAL_POST_ID);
    }
    else {
      return Image.file(
        image,
        width: side,
        height: side,
        fit: BoxFit.cover,
      );
    }
  }

  Widget emptyImageContainer(double side, String widgetType) {
    final viewportSide = side * viewportFraction;
    return Container(
      color: Colors.transparent,
      width: side,
      height: side,
      alignment: Alignment.center,
      child: InkWell(
        onTap: () {
          switch (widgetType) {
            case (SHOP_ITEM_ID): loadProductImages();
            break;
            case (SOCIAL_POST_ID): loadPostImages();
            break;
            default: print("fail");
            break;
          }
        },
        child: Container(
          decoration: BoxDecoration(
            borderRadius: cornerRadius,
            color: CustomColors.colorPrimary,
            boxShadow: [Shadows.main],
          ),
          width: viewportSide,
          height: viewportSide,
          alignment: Alignment.center,
          child: Icon(
            Icons.add_circle,
            color: CustomColors.createGrey,
            size: Dimens.createAddIconSide,
          ),
        ),
      ),
    );
  }

  String notEmptyValidator(String value) {
    if (value == null || value.length == 0) return Strings.errorEmpty;
    else return null;
  }

  void productFormSubmit(BuildContext context) async {
    ProgressDialog ld = getLoadingDialog(context);
    ld = styleDialog(ld, "Uploading your listing...");

    var form = _productFormKey.currentState;
    if (form.validate() && _productImages.length > 0) {
      if (_productImages[0].name != "error") {
        await ld.show();
        List<ParseFile> images = List();
        for (Asset asset in _productImages) {
          ByteData imageByteData = await asset.getByteData(quality: 50);
          Uint8List imageData = imageByteData.buffer.asUint8List();

          File imageFile = File(getTempImgPath());
          imageFile.writeAsBytes(imageData);
          images.add(new ParseFile(imageFile));
        }

        List<String> emptyList = [];

        PProduct parseProduct = PProduct()..init(
          "",
          productTitleController.text.toString().trim(),
          "",
          currentParseUserUid,
          double.parse(productPriceController.text.trim()),
          productDescriptionController.text.toString().trim(),
          images,
          dropdownSelections[SHOP_CAT],
          dropdownSelections[SHOP_TYPE],
          handleHashtagList(_productHashtagList),
          _stylesSelection,
          emptyList,
          false,
          false,
          Timestamp.now().millisecondsSinceEpoch,
          dropdownSelections[SHOP_GENDER],
          dropdownSelections[SHOP_ITEM_CONDITION],
          dropdownSelections[SHOP_SIZE],
        );

        ParseObject object = objFromMap(new ParseObject(OBJECT_SHOP), parseProduct.toMap());
        print(object.toString());
        await object.save().then(parseSaveCallback);
        await updateParseUserData(currentParseUserUid, {
          USER_SELLING : object.objectId,
        }, setType: SET_ADD_UNIQUE);

        setState(() {
          dropdownSelections.clear();
          _productImages.clear();
        });

        productTitleController.clear();
        productPriceController.clear();
        productDescriptionController.clear();
        _productFormKey.currentState.reassemble();

        await ld.hide();
      }
    }
  }

  void postFormSubmit(BuildContext context) async {
    ProgressDialog ld = ProgressDialog(
      context,
      type: ProgressDialogType.Normal,
      isDismissible: false,
    );
    ld = styleDialog(ld, "Uploading your post...");

    var form = _postFormKey.currentState;
    if (form.validate() && _postImage != null) {
      await ld.show();

      List<int> imageAsList = await FlutterImageCompress.compressWithFile(
        _postImage.absolute.path,
        quality: 50,
      );
      Uint8List imageData = Uint8List.fromList(imageAsList);
      File imageFile = File(tempImgPath);
      imageFile.writeAsBytes(imageData);

      List<String> emptyList = [];
      PPost parsePost = PPost()..init(
        "",
        currentParseUserUid,
        postTitleController.text.toString().trim(),
        Timestamp.now().millisecondsSinceEpoch,
        new ParseFile(imageFile),
        emptyList,
        postDropdownSelections[SOCIAL_TYPE],
        handleHashtagList(_postHashtagList),
        _postStylesSelection,
      );

      ParseObject object = objFromMap(new ParseObject(OBJECT_SOCIAL), parsePost.toMap());
      print(object.toString());
      await object.save().then(parseSaveCallback);

      currentParseUser = userFromMap(currentParseUser, {
        USER_POSTED : object.objectId,
      }, setType: SET_ADD_UNIQUE);
      await currentParseUser.save().then(parseSaveCallback);

      setState(() {
        postTitleController.clear();
        _postImage = null;
        postDropdownSelections.clear();
        _postStylesSelection.clear();
        _postFormKey.currentState.reset();
      });

      await ld.hide();
    }
  }

  Widget chipsInput(GlobalKey<ChipsInputState> key, bool isProduct) {
    return new Padding(
      padding: paddingFormTop,
      child: ChipsInput<Hashtag>(
        autocorrect: false,
        key: key,
        onChanged: (List<Hashtag> list) => isProduct
        ? _productHashtagList = list
        : _postHashtagList = list,
        maxChips: Ints.createProductMaxHashtags,
        decoration: InputDecoration(
          border: Styles.createInputBorder,
          labelText: Strings.labelTextHashtags,
          hintText: Strings.hintHashtags,
          alignLabelWithHint: true,
        ),
        chipBuilder: (context, state, hashtag) {
          return Chip(
            label: Text("#${hashtag.name}"),
            onDeleted: () => state.deleteChip(hashtag),
            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
          );
        },
        findSuggestions: (String input) async {
          input = input.toLowerCase();
          if (input.contains(' ')) {
            key.currentState.selectSuggestion(
                new Hashtag(name: input.trim(),)
            );
            return const <Hashtag>[];
          }
          List<Hashtag> returnList = [new Hashtag(name: input),];
          final suggestionList = hashtagSearch(input)
            ..sort(hashtagCountComparator);
          return suggestionList.isEmpty ? returnList : suggestionList;
        },
        suggestionBuilder: (context, state, hashtag) {
          return ListTile(
            title: Text('#' + hashtag.name),
            trailing: Text("${hashtag.count} use${hashtag.count != 1 ? 's' : ''}"),
            onTap: () => state.selectSuggestion(hashtag),
          );
        },
      ),
    );
  }
}

class CreateTitle extends StatelessWidget {
  final String title;
  final bool noPadding;
  CreateTitle({this.title, this.noPadding});

  @override
  Widget build(BuildContext context) {
    bool putPadding = (noPadding == null) ? true : !noPadding;
    return new Padding(
      padding: EdgeInsets.only(
        top: (putPadding) ? Dimens.paddingFormTop : 0.0,
        left: 3.0,
      ),
      child: Text(
        title,
        style: Styles.createFormHeader,
      ),
    );
  }

}