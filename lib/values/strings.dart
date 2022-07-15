import 'package:fleek/values/ints.dart';

abstract class Strings {
  static const String discoverBanner = "Discover fashion without a hole in your pocket.";
  static const String discoverHashtagsHeader = "Trending Hashtags";
  static const String discoverCategoriesHeader = "Top Categories";
  static const String discoverStylesHeader = "Shop By Style";
  static const String discoverForYouHeader = "Handpicked For You";
  static const String discoverLatestHeader = "Latest Drops";

  static const String discoverEndlessFilterTypeHeader = "Pick Specific Types";

  static const String labelTextUsername = "Username";
  static const String labelTextEmail = "Email";
  static const String labelTextPassword = "Password";

  static const String labelTextDisplayName = "Display Name";
  static const String labelTextBio = "Bio (Optional)";

  static const String hintUsername = "";
  static const String hintBio = "What would you like buyers/sellers to know about you? (max ${Ints.updateProfileMaxLengthBio} characters)";

  static const String labelTextTitle = "Title";
  static const String labelTextPrice = "Price";
  static const String labelTextDescription = "Description";
  static const String labelTextDropdownSize = "Size";
  static const String labelTextDropdownCat = "Category";
  static const String labelTextDropdownType = "Sub Category";
  static const String labelTextHashtags = "Hashtags";
  static const String labelTextDropdownStyles = "Styles";
  static const String labelTextDropdownCondition = "Item Condition";
  static const String labelTextDropdownGender = "Gender";

  static const String hintTitle = "max ${Ints.createMaxLengthTitle} characters";
  static const String hintDescription = "Describe what you are selling to your buyers. Tell them the details you think they will be interested in. (max ${Ints.createProductMaxLengthDescription} characters)";
  static const String hintHashtags = "Enter a maximum of ${Ints.createProductMaxHashtags} (optional)";
  static const String hintDropdownStyles = "Choose 1 or more (optional)";

  static const String labelTextSearch = "search for a product...";

  static const String labelTextReviewInput = "Additional comments (optional)";
  static const String hintReviewInput = "Describe your experience with this user!";

  static const String errorEmpty = "Required";
  static const String errorInvalidEmail = "Please enter a valid email.";
  static const String errorMinChar = "Password must be at least ${Ints.authPasswordMinChar} characters.";
  static const String errorUsernameTaken = "Username taken. Please try another.";
  static const String errorSpecialChar = "Please avoid spaces, uppercase letters and special characters.";
  static const String errorProfanity = "Please refrain from including profanities.";

  static const String buttonSubmit = "Submit";
  static const String buttonSignIn = "Sign In";
  static const String buttonSignInGoogle = "Sign In with Google";
  static const String buttonRegister = "Register";
  static const String buttonSeeAll = "See All >";
  static const String buttonUpdateProfile = "EDIT PROFILE";
  static const String buttonFollow = "FOLLOW";
  static const String buttonFollowed = "UNFOLLOW";
  static const String buttonSort = "SORT";
  static const String buttonFilter = "FILTER";

  static const String tabLabelCreateProduct = "Listing";
  static const String tabLabelCreatePost = "Post";

  static const String createProductImagesHeader = "Selected Images";
  static const String createPostImageHeader = "Selected Image";

  static const String promptSelectImage = "Select an image";

  static const String tabLabelLikedProducts = "Listings";
  static const String tabLabelLikedPosts = "Posts";

  static const String updateProfileHeader = "Update your profile";

  static const String tabLabelProfileSelling = "Selling";
  static const String tabLabelProfilePosted = "Posts";

  static const String counterLabelFollowers = "followers";
  static const String counterLabelFollowing = "following";

  static const String sortRecommended = "RECOMMENDED";
  static const String sortTime = "LATEST";
  static const String sortPriceHighLow = "PRICE: HIGH TO LOW";
  static const String sortPriceLowHigh = "PRICE: LOW TO HIGH";

  static const String filterGender = "BY GENDER";
  static const String filterGenderMale = "MALE PRODUCTS";
  static const String filterGenderFemale = "FEMALE PRODUCTS";
  static const String filterSize = "BY SIZE";
  static const String filterCondition = "BY ITEM CONDITION";

  static const String settingsSignOut = "Sign Out";
  static const String settingsAbout = "About Us";
  static const String settingsSupport = "Support";
  static const String settingsSupportFAQ = "FAQ";
  static const String settingsSupportContact = "Contact Us";
  static const String settingsGeneral = "General";
  static const String settingsGeneralNotifs = "Notifications";
  static const String settingsGeneralNotifsMessages = "Messages";
  static const String settingsGeneralAccount = "Account";
  static const String settingsGeneralAccountEmail = "Change Email";
  static const String settingsGeneralAccountPassword = "Change Password";
  static const String settingsGeneralAccountDelete = "Delete Account";
  static const String settingsListings = "Marketplace";
  static const String settingsListingsHow = "How to Sell";
  static const String settingsListingsPurchases = "Past Purchases";
  static const String settingsListingsGuidelines = "Community Guidelines";
}