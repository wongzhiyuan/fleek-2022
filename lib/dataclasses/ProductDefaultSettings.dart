import 'package:fleek/global/globalItems.dart';

class ProductDefaultSettings {
  bool isDownloaded = false;
  Map<String, String> styles = Map();
  List<String> stylesList = List();
  Map<String, String> types = Map();
  List<String> typesList = List();
  Map<String, List<String>> mCats = Map();
  List<String> mCatsList = List();
  Map<String, List<String>> fCats = Map();
  List<String> fCatsList = List();
  List<String> sizes = List();
  List<String> productConditions = List();

  ProductDefaultSettings();

  void init(
    Map<String, String> styles,
    Map<String, String> types,
    Map<String, List<String>> mCats,
      Map<String, List<String>> fCats,
    List<String> sizes,
    List<String> productConditions,
  ) {
    this.isDownloaded = true;
    this.styles = styles;
    this.stylesList = new List<String>.from(styles.keys);
    this.types = types;
    this.typesList = new List<String>.from(types.keys);
    this.mCats = mCats;
    this.mCatsList = new List<String>.from(mCats.keys);
    this.fCats = fCats;
    this.fCatsList = new List<String>.from(fCats.keys);
    this.sizes = sizes;
    this.productConditions = productConditions;
  }

  ProductDefaultSettings fromMap(Map<String, dynamic> map) {
    ProductDefaultSettings productDefaultSettings = ProductDefaultSettings();

    Map<String, List<String>> translateCatMap(String key) {
      Map<String, List<String>> catMap = {};
      Map<String, dynamic> toTranslate = new Map<String, dynamic>.from(
          map[key]);
      for (String key in toTranslate.keys) {
        catMap[key] = new List<String>.from(toTranslate[key]);
      }

      return catMap;
    }
    productDefaultSettings.init(
      new Map<String, String>.from(map[DEFAULT_STYLES_MAP]),
      new Map<String, String>.from(map[DEFAULT_TYPES_MAP]),
      translateCatMap(DEFAULT_M_CATS_MAP),
      translateCatMap(DEFAULT_F_CATS_MAP),
      new List<String>.from(map[DEFAULT_SIZES_LIST]),
      new List<String>.from(map[DEFAULT_PRODUCT_CONDITION_LIST]),
    );
    return productDefaultSettings;
  }

  Map<String, dynamic> toMap() {
    return {
      DEFAULT_TYPES_MAP: this.types,
      DEFAULT_STYLES_MAP: this.styles,
      DEFAULT_M_CATS_MAP: this.mCats,
      DEFAULT_F_CATS_MAP: this.fCats,
      DEFAULT_SIZES_LIST: this.sizes,
      DEFAULT_PRODUCT_CONDITION_LIST: this.productConditions
    };
  }
}