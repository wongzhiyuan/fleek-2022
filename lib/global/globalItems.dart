import 'dart:async';
import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fleek/dataclasses/DisplayItem.dart';
import 'package:fleek/dataclasses/Filter.dart';
import 'package:fleek/dataclasses/Hashtag.dart';
import 'package:fleek/dataclasses/LocalSettings.dart';
import 'package:fleek/dataclasses/Message.dart';
import 'package:fleek/dataclasses/PPost.dart';
import 'package:fleek/dataclasses/PProduct.dart';
import 'package:fleek/dataclasses/PUser.dart';
import 'package:fleek/dataclasses/Post.dart';
import 'package:fleek/dataclasses/Product.dart';
import 'package:fleek/dataclasses/ProductDefaultSettings.dart';
import 'package:fleek/dataclasses/User.dart';
import 'package:fleek/global/globalFunctions.dart';
import 'package:parse_server_sdk/parse_server_sdk.dart';
import 'package:progress_dialog/progress_dialog.dart';

//Temporary Directory
Directory tempDir;
String tempImgPath;

//Parse Server Config
const localhost = '10.0.2.2';
const appId = 'dvWC1ei2DPQERzDcfw1IZ94u7tp5ombhAjbwJFCd';
const clientKey = '5MjvprHK6gyltvPXfIAIug0qto0AxBjMOJVt1R7Z';
const serverURL = 'https://parseapi.back4app.com/';
const liveQueryURL = 'wss://hashtag.back4app.io/';
bool isParseInit = false;
LiveQuery liveQuery;

//Parse General Info (FAQ, Contact, Community Guidelines etc.)
const String OBJECT_INFO = 'Info';
const String INFO_NAME = 'name';
const String INFO_FILE = 'file';
const String INFO_FAQ = 'FAQ';
const String INFO_CONTACT = 'CONTACT';
const String INFO_CG = 'CG';

//Parse Hashtags
Map<String, Hashtag> hashtagsDB = {};
Subscription<ParseObject> hashtagsListener;
const String OBJECT_HASHTAG = 'H';
const String HASHTAG_NAME = 't';
const String HASHTAG_COUNT = 'n';

//Parse Exceptions
const String PARSE_ERROR_OBJECT_NOT_FOUND = 'ObjectNotFound';

//Parse Object Switches
const String SET_SET = 'SET';
const String SET_ADD = 'ADD';
const String SET_ADD_UNIQUE = 'ADD_UNIQUE';
const String SET_REMOVE = 'REMOVE';

//Parse Cloud Functions Parameters
const String NEW_MESSAGE_DUMP_SELLING = 'selling';
const String NEW_MESSAGE_DUMP_BUYING = 'buying';

//Global Loading Dialog (Use and Abuse!)
ProgressDialog globalDialog;

//Local Settings
LocalSettings localSettings = new LocalSettings();

//Provider IDs
const String PROVIDER_EMAIL = 'password';
const String PROVIDER_GOOGLE = 'google.com';

//Universal String Indicators
const String YES = "Y";
const String NO = "N";
const String UP = "U";
const String DOWN = "D";
const String LEFT = "L";
const String RIGHT = "R";
const String EMAIL = "E-mail";
const String PASSWORD = "Password";

const NONE = 'none';
const TYPE = 'type';
const STYLE = 'style';
const TYPE_STYLE = 'ts';
const HASHTAG = 'hashtag';

const SHOP = 'SHOP';
const SOCIAL = 'SOCIAL';
const USERS = 'USERS';

//Special numbers
//message timestamps
const int TIMESTAMP_REVIEW = 1212;

//Intent Map and Keys
Map<String, dynamic> intentMap = Map();
const String INTENT_UPDATE_PROFILE = "uP";
const String INTENT_UPDATE_PROFILE_NEW_USER = "new";
const String INTENT_UPDATE_PROFILE_EXISTING_USER = "update";

const String INTENT_SEE_ALL = "sA";
const String INTENT_SEE_ALL_TYPES = "cat";
const String INTENT_SEE_ALL_STYLES = "stl";
const String INTENT_SEE_ALL_SEARCH = "sch";
const String INTENT_SEE_ALL_HASHTAGS = 'hsh';

const String INTENT_ENDLESS_SCROLL = "eS";
const String INTENT_ENDLESS_SCROLL_CATS = "CAT";
const String INTENT_ENDLESS_SCROLL_QUERY = "eSq";
const String INTENT_ENDLESS_SCROLL_TYPE = "eSt";

const String INTENT_SWIPE = "sw";
//Sort Constants
const String SORT_RECOMMENDED = "rec";
const String SORT_TIME = "time";
const String SORT_PRICE_LOW_HIGH = "pLH";
const String SORT_PRICE_HIGH_LOW = "pHL";

//Set Up Basic Filters for use
const String FILTER_ERROR_FINDING_TYPE = "error finding type.";

const String FILTER_GENDER = "g";
const String FILTER_GENDER_MALE = "M";
const String FILTER_GENDER_FEMALE = "F";
const String FILTER_GENDER_BOTH = "Unisex";

const String FILTER_CONDITION = "c";
const String FILTER_CONDITION_USED = "Used";
const String FILTER_CONDITION_NEW = "New";

const String FILTER_SIZE = "m";
const String FILTER_SIZE_XS = "XS";
const String FILTER_SIZE_S = "S";
const String FILTER_SIZE_M = "M";
const String FILTER_SIZE_L = "L";
const String FILTER_SIZE_XL = "XL";

const String FILTER_TYPE = "t";

//Switch case variables
//Determine "See All" Destination
const String SEE_ALL_CATEGORIES = "cat";
const String SEE_ALL_STYLES = "stl";

//Stream Controllers
//control booleans
bool areAllSnapshotListenersRegistered = false;

//start up controllers
StreamController<String> aInitialDownloaded = new StreamController.broadcast();

//auth controller
StreamController<bool> aEmailVerified = new StreamController.broadcast();

//shop controllers
StreamController<bool> aInitialShopDownloadComplete = new StreamController.broadcast();
StreamController<String> aShopAddId = new StreamController.broadcast();
StreamController<String> aShopModifyId = new StreamController.broadcast();
StreamController<String> aShopDeleteId = new StreamController.broadcast();

//social controllers
StreamController<String> aSocialAddId = new StreamController.broadcast();
StreamController<String> aSocialModifyId = new StreamController.broadcast();
StreamController<String> aSocialDeleteId = new StreamController.broadcast();

//users controllers
StreamController<int> aUserCollectionModified = new StreamController.broadcast();

StreamController<String> aUserAddId = new StreamController.broadcast();
StreamController<String> aUserModifyId = new StreamController.broadcast();
StreamController<String> aUserDeleteId = new StreamController.broadcast();

StreamController<ParseUser> aParseUserChanged = new StreamController.broadcast();

//chat controllers
StreamController<Map<String, String>> aBuyingChatAdded = new StreamController.broadcast();
StreamController<Map<String, String>> aSellingChatAdded = new StreamController.broadcast();
StreamController<String> aMessageDumpUnread = new StreamController.broadcast();
StreamController<String> aMessageDumpAllRead = new StreamController.broadcast();

List<Subscription> messageDumpListeners = [];

Map<String, List<Message>> unreadMessages = {};

//default settings controller
StreamController<bool> aSettingsDownloaded = new StreamController.broadcast();

//hashtag controllers
StreamController<Hashtag> aHashtagChanged = new StreamController.broadcast();
//search controller
StreamController<String> aSearchUpdated = new StreamController.broadcast();

//Firestore Shop-Related Objects
ProductDefaultSettings defaultSettings = ProductDefaultSettings();
/*
CollectionReference shopRef = db.collection(SHOP_COLLECTION);
StreamSubscription<QuerySnapshot> shopCollectionListener;
Map<String, Product> shopCollection = Map();
*/
//Shop booleans
bool initialDownloadDone = false;

//Shop Comparators
Comparator<PProduct> defaultComparator = (a, b) => 0;
Comparator<PProduct> timeComparator = (b, a) {
  int aSeconds = a.timestamp;
  int bSeconds = b.timestamp;

  return aSeconds.compareTo(bSeconds);
};

Comparator<PProduct> priceComparator = (a, b) {
  double aPrice = a.price;
  double bPrice = b.price;

  return aPrice.compareTo(bPrice);
};

Comparator<PProduct> priceComparatorReversed = (b, a) {
  double aPrice = a.price;
  double bPrice = b.price;

  return aPrice.compareTo(bPrice);
};

//Community comparators
Comparator<DisplayItem> communityTimeComparator = (b, a) {
  int aSeconds = a.timestamp;
  int bSeconds = b.timestamp;

  return aSeconds.compareTo(bSeconds);
};

//Hashtag comparators
Comparator<Hashtag> hashtagCountComparator = (b, a) => a.count.compareTo(b.count);

//Recommended Map Switchers
const RECOMMENDED_PRIORITY = "priority";
const RECOMMENDED_SECONDARY = "secondary";

//Parse Shop-Related
const String OBJECT_SHOP = 'P';
Subscription<ParseObject> shopListener;
Map<String, PProduct> parseShopCollection = {};

const String OBJECT_PRODUCT_DEFAULT_SETTINGS = 'PDS';

//Parse Social-Related
const String OBJECT_SOCIAL = 'S';
Subscription<ParseObject> socialListener;
Map<String, PPost> parseSocialCollection = {};

//Parse User-Related
const String OBJECT_USER_DATA = 'UD';
Subscription<ParseObject> usersListener;
ParseUser currentParseUser;
PUser currentParseUserCollection = new PUser();
Map<String, PUser> parseUsersCollection = {};
String currentParseUserUid = "";
Map<String, ParseUser> parseUserMap = {};
Map<String, ParseFile> parseProfilePictures = {};

//Parse Message-Related
const String OBJECT_MESSAGE_DUMPS = 'M';

//Parse Review-Related
const String OBJECT_REVIEW = 'R';

//Parse User Chat Info
const String OBJECT_USER_CHAT_INFO = 'C';

//Firestore User-Related Objects
StreamSubscription<QuerySnapshot> userCollectionListener;
Map<String, User> usersCollection = Map();
User currentUserCollection = User();
Map<String, String> takenDisplayNames = Map();

//Parse Chat Objects
//Chat Lists
List<Map<String, String>> buyingChatList = [];
List<Map<String, String>> sellingChatList = [];

//ShopCollection Indicators
const String SHOP_COLLECTION = "p";
const String SHOP_ITEM_ID = "sid";
const String SHOP_TITLE = "t";
const String SHOP_BUYER = "b";
const String SHOP_SELLER = "s";
const String SHOP_PRICE = "M";
const String SHOP_DESCRIPTION = "d";
const String SHOP_COVER_IMAGE_URI = "i";
const String SHOP_IMAGE_URI_LIST = "u";
const String SHOP_IMAGE_UUID_LIST = "U";
const String SHOP_CAT = "Y";
const String SHOP_TYPE = "y";
const String SHOP_HASHTAGS_LIST = 'H';
const String SHOP_STYLES_LIST = "S";
const String SHOP_LIKED_BY_LIST = "L";
const String SHOP_IS_RESERVED = "r";
const String SHOP_IS_SOLD = "x";
const String SHOP_TIMESTAMP = "T";
const String SHOP_GENDER = "g";
const String SHOP_ITEM_CONDITION = "q";
const String SHOP_SIZE = "m";

//UserCollection Indicators
const String USER_COLLECTION = "u";
const String USER_HAS_DATA = "D";
const String USER_USER_UID = "uid";
const String USER_DISPLAY_NAMES = "n";
const String USER_DISPLAY_NAME = "u";
const String USER_PROFILE_PICTURE_URI = "i";
const String USER_BIO = "z";
const String USER_SELLING = "S";
const String USER_POSTED = "p";
const String USER_LIKED_POSTS = "L";
const String USER_LIKED_PRODUCTS = "l";
const String USER_DISLIKED_PRODUCTS = "d";
const String USER_MOST_RECENT_TYPE = "r";
const String USER_MOST_RECENT_STYLE = "y";
const String USER_BOUGHT = "b";
const String USER_SOLD = "s";
const String USER_FOLLOWERS = "F";
const String USER_FOLLOWING = "f";
const String USER_BUYING_CHATS = "cb";
const String USER_SELLING_CHATS = "cs";

//SocialCollection Indicators
const String SOCIAL_COLLECTION = "s";
const String SOCIAL_POST_ID = "pid";
const String SOCIAL_USER_UID = "u";
const String SOCIAL_TITLE = "t";
const String SOCIAL_TIMESTAMP = "T";
const String SOCIAL_IMAGE_URI = "i";
const String SOCIAL_IMAGE_UUID = "I";
const String SOCIAL_DESCRIPTION = "d";
const String SOCIAL_LIKED_BY = "l";
const String SOCIAL_TYPE = "a";
const String SOCIAL_HASHTAGS_LIST = 'H';
const String SOCIAL_STYLES_LIST = "b";


//Product Default Settings Indicators
const String DEFAULT_STYLES_MAP = "s";
const String DEFAULT_TYPES_MAP = "t";
const String DEFAULT_M_CATS_MAP = "mT";
const String DEFAULT_F_CATS_MAP = "fT";
const String DEFAULT_SIZES_LIST = "m";
const String DEFAULT_PRODUCT_CONDITION_LIST = "c";

//Message Indicators
const String MESSAGE_MESSAGE = "m";
const String MESSAGE_IMAGE = 'I';
const String MESSAGE_MESSAGE_DUMP = 'd';
const String MESSAGE_SENDER = "s";
const String MESSAGE_RECEIVER = "r";
const String MESSAGE_TIMESTAMP = "t";
const String MESSAGE_IS_READ = "x";
const String MESSAGE_IS_IMAGE = "p";
const String MESSAGE_PRODUCT_ID = 'P';
const String MESSAGE_ID = "i";

//Chat indicators
const String CHAT_USER_TOKEN = "t";
const String CHAT_IS_CHAT_ON = "o";
const String CHAT_IS_NOTIFS_ENABLED = "n";
const String CHAT_SELLING = "s";
const String CHAT_BUYING = "b";
const String CHAT_USER_UID = "u";
const String CHAT_MESSAGE_DUMP = "d";
const String CHAT_MESSAGE_LIST = "L";
const String CHAT_PRODUCT_ID = "p";
const String CHAT_HAS_UNREAD = "r";

//Chat Drawer Indicators
const String CHAT_DRAWER_BUYING = "Buying";
const String CHAT_DRAWER_SELLING = "Selling";

//Review Keys
const String REVIEW_RATING = "r";
const String REVIEW_CONTENT = "d";
const String REVIEW_AUTHOR = 'a';
const String REVIEW_RECEIVER = 'b';

//FAQ Keys
const String FAQ_QUESTION = "q";
const String FAQ_ANSWER = "a";

//Contact Keys
const String CONTACT_EMAIL = 'e';
const String CONTACT_HOTLINE = 'p';

//Product Default Settings
List<String> defaultSizes = ["XS", "S", "M", "L", "XL"];
List<String> defaultProductConditions = ["Used", "New"];
Map<String, String> defaultStyles = {
  "Avant Garde" : "https://cdn.shopify.com/s/files/1/0025/8723/0260/articles/TB2I76dXxDBK1JjSZFhXXXFFFXa__45326099_1280x1280_0b70fd86-5968-4841-8f61-3cbf9cefca6c_1000x.jpg?v=1548729439",
  "Casual" : "https://i.pinimg.com/474x/e3/13/da/e313da56c591b96302e038b0b8b40c71.jpg",
  "European" : "https://sc02.alicdn.com/kf/HTB1Vt7oaITxK1Rjy0Fgq6yovpXa1.jpg_350x350.jpg",
  "Gothic" : "https://cdn11.bigcommerce.com/s-1js1zluvaj/images/stencil/600x600/products/4608/25085/Male-Women-Streetwear-Hip-Hop-Punk-Gothic-Style-Cloak-Windbreaker-Jacket-Couple-Clothing-Oversize-Men-Black__88325.1562833192.jpg?c=2",
  "Hypebeast" : "https://image-cdn.hypb.st/https%3A%2F%2Fhypebeast.com%2Fimage%2F2018%2F07%2Fnyfw-ss19-street-style-23000.jpg?fit=max&cbr=1&q=90&w=750&h=500",
  "Korean" : "https://cf.shopee.sg/file/025318f243ee66ccb43b18b73552dc86",
  "Luxury" : "https://ae01.alicdn.com/kf/HTB1QVjgX.vrK1RjSszfq6xJNVXaz/New-Arrival-Winter-Luxury-Show-Style-Women-2-Piece-Set-Party-Travel-Pretty-Suit-Outfit-Casual.jpg_q50.jpg",
  "Minimalist" : "https://blog.stitchfix.com/wp-content/uploads/06_06_W_SUM17_06W5_EML_DD_One-Size-Does-Not-Fit-All_v2_0180.jpg",
  "Tech Wear" : "https://vitruvianmagazine.com/wp-content/uploads/2018/05/Techwear-pic-4.jpg",
  "Vintage" : "https://i.pinimg.com/originals/5d/15/a9/5d15a9a1c2bbba858b14bdd415195a1f.jpg",
};

Map<String, List<String>> defaultMCats = {
  "Footwear " : ["Sneakers","Highcut","Boots","Casual Leather","Formal ","Sandals","Slip Ons",],
  "Outerwear" : ["Heavy Coats","Light Jackets","Denim","Leather","Bomber","Vest",],
  "Tops" : ["Sweater","Sweatshirt","Short Sleeve","Long Sleeve","Polo","Buttoned Shirt","Jersey","Tank Top",],
  "Bottoms" : ["Casual ","Jeans","Cropped Pants","Overalls","Shorts","Sweatpants",],
  "Accessories" : ["Caps","Belts","Glasses","Bags","Watches","Wallets",],
};

Map<String, List<String>> defaultFCats = {
  "Footwear " : ["Sneakers","Highcut","Boots","Casual Leather","Formal ","Sandals","Slip Ons",],
  "Outerwear" : ["Heavy Coats","Light Jackets","Denim","Leather","Bomber","Vest",],
  "Tops" : ["Sweater","Sweatshirt","Short Sleeve","Long Sleeve","Polo","Buttoned Shirt","Jersey","Tank Top",],
  "Bottoms" : ["Casual ","Jeans","Cropped Pants","Leggings","Overalls","Shorts","Sweatpants","Skirts",],
  "Accessories" : ["Caps","Belts","Glasses","Bags","Watches","Wallets",],
};

Map<String, String> defaultTypes = {
  "Sneakers" : "https://media.endclothing.com/media/f_auto,w_600,h_600/prodmedia/media/catalog/product/1/4/14-02-2019_nike_airmax97lxw_beigecarbonpeach_white_ar7621-201_gh_1.jpg",
  "Highcut" : "https://encrypted-tbn0.gstatic.com/images?q=tbn%3AANd9GcTXrpL-vi1HVW0UUTCq1sXsqrwkqsFWRxFNx5dyBv59lMvuEm5n&usqp=CAU",
  "Boots" : "https://encrypted-tbn0.gstatic.com/images?q=tbn%3AANd9GcT_8ECqJB0JCZd5v9hiptstdG3siG_qmJejgGdRzkv65buFAe8F&usqp=CAU",
  "Casual Leather" : "https://encrypted-tbn0.gstatic.com/images?q=tbn%3AANd9GcT8AeP_RvkN7-ULzo4BkRAlDYWU3TbkccBDi6skQ01QYnyy9dS7&usqp=CAU",
  "Formal " : "https://encrypted-tbn0.gstatic.com/images?q=tbn%3AANd9GcR1VCRRhtl_d4ekZ4YPDEQr7h0MMP_B22meiMHUhDpB9WS7udrD&usqp=CAU",
  "Sandals" : "https://encrypted-tbn0.gstatic.com/images?q=tbn%3AANd9GcQq68QgZE-wcJCS6SUzj-49uboo-lXGnHlL0LOybKB_zFZTuIJE&usqp=CAU",
  "Slip Ons" : "https://encrypted-tbn0.gstatic.com/images?q=tbn%3AANd9GcSoC2VnFjEi8bdml4goGQ4eGGG5ZaQAmbpqYmeD1q_fyhW_GxQK&usqp=CAU",
  "Heavy Coats" : "https://johnlewis.scene7.com/is/image/JohnLewis/002241515?\$rsp-pdp-port-1440\$",
  "Light Jackets" : "https://encrypted-tbn0.gstatic.com/images?q=tbn%3AANd9GcRubjA_cewA-jWrN3_oFNuYnnsLktsneBZ_K4juZ0Zo_tkP-gA-&usqp=CAU",
  "Denim" : "https://media.endclothing.com/media/catalog/product/1/5/15-03-2019_soulland_sheltondenimjacket_lightblue_00-03-002_cw_1.jpg",
  "Leather" : "https://encrypted-tbn0.gstatic.com/images?q=tbn%3AANd9GcRjv35Biw4YxR1IcoGAQBZk9nJ3WJJnIM_lDppErD16sihrAADk&usqp=CAU",
  "Bomber" : "https://encrypted-tbn0.gstatic.com/images?q=tbn%3AANd9GcQib6jbn-BTHeztnVlLeZDsWGgdxyuSRYgiGQkfwFlrdyRBC06L&usqp=CAU",
  "Vest" : "https://encrypted-tbn0.gstatic.com/images?q=tbn%3AANd9GcTthh0mGipfMJWQ_r0jnFp8P1giNThvEB390YlOA3ZOSEsk67iL&usqp=CAU",
  "Sweater" : "https://encrypted-tbn0.gstatic.com/images?q=tbn%3AANd9GcQ1Fw2Ztg36LJatGZr43JlyWzpczpSZzjBxOZ7UBcgHA1DvclMu&usqp=CAU",
  "Sweatshirt" : "https://encrypted-tbn0.gstatic.com/images?q=tbn%3AANd9GcQaCxYUVeb8IghQYFqOSavgsF6thM7C7E14Blu7nyavuqj6i_yM&usqp=CAU",
  "Short Sleeve" : "https://encrypted-tbn0.gstatic.com/images?q=tbn%3AANd9GcRHYWUgjJ0lU0wMPZbeLkgATrzWMDeM47U25S_GQbj4kzz_RJOr&usqp=CAU",
  "Long Sleeve" : "https://encrypted-tbn0.gstatic.com/images?q=tbn%3AANd9GcQf3BrzSQk6FmysHuwWz3ukqnpnBVzk4rDI9l9ffIr1HCJk-PkZ&usqp=CAU",
  "Polo" : "https://encrypted-tbn0.gstatic.com/images?q=tbn%3AANd9GcRLxFmNKS8sh9aRGmS4nTPJ3Pa_d9P5gPK8yor9Foaga2h_YFQq&usqp=CAU",
  "Buttoned Shirt" : "https://cdn-images.farfetch-contents.com/12/58/26/99/12582699_12130283_300.jpg",
  "Jersey" : "https://encrypted-tbn0.gstatic.com/images?q=tbn%3AANd9GcSVJIDJw-UWKhS44bGnMs7QenOQSOfXLWk7ZgbqkinyuOOnMZNF&usqp=CAU",
  "Tank Top" : "https://encrypted-tbn0.gstatic.com/images?q=tbn%3AANd9GcSq8qvf6p3VUMZu1VLbkptKQqAvGW2x2HjZ7Xlsk6RoIJQtVGvU&usqp=CAU",
  "Casual " : "https://cdn.luxe.digital/media/2019/09/12084947/casual-dress-code-men-style-polo-ralph-lauren-chinos-luxe-digital.jpg",
  "Jeans" : "https://media.gq-magazine.co.uk/photos/5eb40b3a1578fa0ec3478b4f/master/w_1000,c_limit/20200507-jeans-10.jpg",
  "Cropped Pants" : "https://encrypted-tbn0.gstatic.com/images?q=tbn%3AANd9GcSgNqQbz9Yh95ZuBwmBXjmmBrlRpDGOKqn72R-NcnYBSCWD1arH&usqp=CAU",
  "Leggings" : "https://encrypted-tbn0.gstatic.com/images?q=tbn%3AANd9GcQVU4umOYlmWjDoiDYLCp2F51bZg3lXScNOOLUoTMHpefFDUOcB&usqp=CAU",
  "Overalls" : "https://d15udtvdbbfasl.cloudfront.net/catalog/product/large_image/65_141263.jpg",
  "Shorts" : "https://dj7u9rvtp3yka.cloudfront.net/products/PIM-1539576769246-de5dd3b7-51a0-4893-85c7-7da895f5d5b0_v1-small.jpg",
  "Sweatpants" : "https://lp2.hm.com/hmgoepprod?set=quality[79],source[/82/65/826585c9bb71b64814d9551e113a52c6589e659c.jpg],origin[dam],category[ladies_trousers_joggers],type[DESCRIPTIVESTILLLIFE],res[s],hmver[1]&call=url[file:/product/main]",
  "Skirts" : "https://encrypted-tbn0.gstatic.com/images?q=tbn%3AANd9GcS1G5tT_u86T8JeB1jkk2XeIOdnLBRKytwWBFej3PM5bydJGQss&usqp=CAU",
  "Caps" : "https://img1.theiconic.com.au/OAyZjkeED-gHluS8yN1qS94TUVA=/634x811/filters:quality(95):fill(ffffff)/http%3A%2F%2Fstatic.theiconic.com.au%2Fp%2Fpolo-ralph-lauren-7378-036884-1.jpg",
  "Belts" : "https://encrypted-tbn0.gstatic.com/images?q=tbn%3AANd9GcRRHvLCuk5yAkA4qFtPJE0gFZyRZEFpF_5JObKWReaR8We5iLSa&usqp=CAU",
  "Glasses" : "https://encrypted-tbn0.gstatic.com/images?q=tbn%3AANd9GcSlW1fSrVHTFlp0nwmJpSZXSLP6cZ-CZdCWKrW_68UXbJclXe3U&usqp=CAU",
  "Bags" : "https://ih1.redbubble.net/image.458518372.2009/tb,1000x1000,small-pad,750x1000,f8f8f8.u2.jpg",
  "Watches" : "https://d1rkccsb0jf1bk.cloudfront.net/products/100024083/main/large/YA1264077_001.jpg",
  "Wallets" : "https://image.harrods.com/gucci-logo-bifold-wallet_15036040_25203571_2048.jpg",
};

List<String> defaultStylesList = new List<String>.from(defaultStyles.keys);
List<String> defaultMCatsList = new List<String>.from(defaultMCats.keys);
List<String> defaultFCatsList = new List<String>.from(defaultFCats.keys);
List<String> defaultCatsList = defaultMCatsList;
List<String> defaultTypesList = new List<String>.from(defaultTypes.keys);

List<String> defaultGenders = [FILTER_GENDER_MALE, FILTER_GENDER_FEMALE, FILTER_GENDER_BOTH];

List<String> initialSixStyles = [
  "Korean",
  "Gothic",
  "Hypebeast",
  "Minimalist",
  "Vintage",
  "Casual"
];

//sort and filter methods
String currentSortMethod = SORT_RECOMMENDED;
Map<String, Filter> currentFilters = Map();




