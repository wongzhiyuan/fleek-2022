import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:fleek/ServiceClasses/PushNotificationManager.dart';
import 'package:fleek/entry/SignInScreen.dart';
import 'package:fleek/global/globalFunctions.dart';
import 'package:fleek/global/globalItems.dart';
import 'package:fleek/popup/UpdateProfileWidget.dart';
import 'package:fleek/values/FontSettings.dart';
import 'package:fleek/values/colors.dart';
import 'package:fleek/values/animInfo.dart';
import 'package:fleek/values/dimens.dart';
import 'package:fleek/values/styles.dart';
import 'package:fleek/widgetClasses/ChatDrawer.dart';
import 'package:fleek/widgetClasses/FloatingNavBar.dart';
import 'package:parse_server_sdk/parse_server_sdk.dart';
import 'main/DiscoverWidget.dart';
import 'main/CommunityWidget.dart';
import 'main/CreateWidget.dart';
import 'main/LikedWidget.dart';
import 'main/ProfileWidget.dart';
import 'package:flutter/material.dart';

void main(){
  runApp(MaterialApp(
    home: MainApp(),
  ));
}

class MainApp extends StatelessWidget {
  // This widget is the root of your application.

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => WidgetsBinding.instance.focusManager.primaryFocus?.unfocus(),
      child: MaterialApp(
        title: 'Fleek',
        theme: ThemeData(
          // This is the theme of your application.
          primarySwatch: createMaterialColor(CustomColors.colorTheme),
          // This makes the visual density adapt to the platform that you run
          // the app on. For desktop platforms, the controls will be smaller and
          // closer together (more dense) than on mobile platforms.
          visualDensity: VisualDensity.adaptivePlatformDensity,
          fontFamily: FontSettings.bodyFamily,
        ),
        home: MainPage(title: 'Fleek'),
      ),
    );
  }
}

class MainPage extends StatefulWidget {
  MainPage({Key key, this.title}) : super(key: key);

  // This widget is the home page of your application. It is stateful, meaning
  // that it has a State object (defined below) that contains fields that affect
  // how it looks.

  // This class is the configuration for the state. It holds the values (in this
  // case the title) provided by the parent (in this case the App widget) and
  // used by the build method of the State. Fields in a Widget subclass are
  // always marked "final".

  final String title;

  @override
  _MainPageState createState() => _MainPageState();
}

class _MainPageState extends State<MainPage> with TickerProviderStateMixin {
  int _currentIndex = 0;
  int _prevIndex = 0;

  List<String> initialDownloadCheck = [];
  List<AnimationController> _animControllers = [];

  final List<String> _navBarChildrenTitles = [
    DiscoverWidget().title,
    CommunityWidget().title,
    CreateWidget().title,
    LikedWidget().title,
    ProfileWidget().title,
  ];

  StreamSubscription<String> _initialDownloadListener;
  StreamSubscription<ParseUser> _parseAuthListener;
  StreamSubscription<bool> emailVerifiedListener;

  ParseUser _currentUser;

  bool _userDocExists = false;
  bool _emailVerified = false;
  bool listenersRegistered = false;
  bool _initFinished = false;

  @override
  void initState() {
    super.initState();

    parseInit();


    defaultSettings.init(
        defaultStyles,
        defaultTypes,
        defaultMCats,
        defaultFCats,
        defaultSizes,
        defaultProductConditions
    );

    _initialDownloadListener = aInitialDownloaded.stream.listen((str) {
      if (!initialDownloadCheck.contains(str)) setState(() {
        print("adding $str");
        initialDownloadCheck.add(str);
      });
    });

    emailVerifiedListener = aEmailVerified.stream.listen((verified) {
      if (verified) setState(() {
        _emailVerified = true;
        localSettings.emailVerified = true;
      });
    });
    _checkCurrentUser();
  }

  @override
  void dispose() {
    if (listenersRegistered) {
      cancelAllSnapshotListeners();
      listenersRegistered = false;
    }

    _initialDownloadListener.cancel();
    _parseAuthListener.cancel();
    emailVerifiedListener.cancel();

    _animControllers.forEach((controller) => controller.dispose());
    super.dispose();
  }
  
  @override
  Widget build(BuildContext context) {
    //start up global dialog
    globalDialog = getLoadingDialog(context);

    if (_initFinished) {
      final List<Widget> children = [
        new DiscoverWidget(),
        new CommunityWidget(),
        new CreateWidget(),
        new LikedWidget(),
        new ProfileWidget(userUid: currentParseUserUid,),
      ];

      const int millis = AnimInfo.mainSlideMillis;
      children.forEach((child) {
        _animControllers.add(new AnimationController(
          vsync: this,
          duration: const Duration(milliseconds: millis),
        ));
      });

      List<Widget> _navBarChildren = [];
      for (int i = 0; i < children.length; i++) {
        _navBarChildren.add(
          slideWidget(children[i], i)
        );
      }

      if (_currentUser == null) {
        return SignInScreen();
      }

      globalDialog.hide();

      if (_userDocExists) {
        if (!_emailVerified) return loadingWidget("Awaiting email verification...");
        if (!initialDownloadCheck.contains(SHOP) ||
            !initialDownloadCheck.contains(SOCIAL) ||
            !initialDownloadCheck.contains(USERS) ||
            !initialDownloadCheck.contains(HASHTAG)) return loadingWidget("Downloading data...");
        final _showIndices = [];

        return new Scaffold(
          appBar: (_showIndices.contains(_currentIndex)) ? AppBar(
            // Here we take the value from the MyHomePage object that was created by
            // the App.build method, and use it to set our appbar title.
            centerTitle: true,
            leading: IconButton(
              icon: const Icon(Icons.chat),
              onPressed: () => Navigator.push(context, MaterialPageRoute(
                builder: (context) => new ChatDrawer(),
              )),
              tooltip: MaterialLocalizations.of(context).openAppDrawerTooltip,
            ),

            actions: <Widget>[
              Builder(
                builder: (BuildContext context) {
                  return IconButton(
                    icon: const Icon(Icons.settings),
                    onPressed: () {
                      Scaffold.of(context).openEndDrawer();
                    },
                    tooltip: MaterialLocalizations.of(context).openAppDrawerTooltip,
                  );
                },
              ),
            ],
            title: Text(_navBarChildrenTitles[_currentIndex]),
          ) : null,
          body: SafeArea(child: _navBarChildren[_currentIndex],),
          bottomNavigationBar: FloatingNavBar(
            onTap: onNavBarTapped,
            items: <BottomNavigationBarItem>[
              navBarItem(Icons.explore),
              navBarItem(Icons.supervised_user_circle),
              navBarItem(Icons.camera),
              navBarItem(Icons.thumb_up),
              navBarItem(Icons.assignment_ind),
            ],
          ),
          extendBody: true,
        );
      }
      else {
        return UpdateProfileWidget(updateProfileIntent: INTENT_UPDATE_PROFILE_NEW_USER,);
      }
    }
    else {
      return loadingWidget("Loading...");
    }
  }

  Widget slideWidget(Widget child, int controllerIndex) {
    double dir = (_currentIndex < _prevIndex) ? pi : 0;
    Offset beginOffset = Offset.fromDirection(dir);
    if (_prevIndex == _currentIndex) beginOffset = Offset.zero;
    return SlideTransition(
      child: child,
      position: Tween<Offset>(
        begin: beginOffset,
        end: Offset.zero,
      ).animate(_animControllers[controllerIndex]),
    );
  }

  Icon navBarIcon(IconData data) {
    return Icon(
      data,
      color: CustomColors.colorPrimaryDark,
    );
  }

  BottomNavigationBarItem navBarItem(IconData data) {
    return new BottomNavigationBarItem(
      icon: navBarIcon(data),
      title: Text(""),
    );
  }

  void _checkCurrentUser() async {
    bool userDocExists = false;

    _parseAuthListener = aParseUserChanged.stream.listen((ParseUser user) async {
      if (user != null) {
        userDocExists = user.get(USER_HAS_DATA);
        userDocExists ??= false;
        print("user docs exist: $userDocExists");
        print(currentParseUser.authData);
        localSettings.providerID = (currentParseUser.authData != null)
        ? (currentParseUser.authData.containsKey('google')) ? PROVIDER_GOOGLE : PROVIDER_EMAIL
        : PROVIDER_EMAIL;

        //TODO: mailgun and email verification
        localSettings.emailVerified = true;
        /*
        localSettings.emailVerified = (localSettings.providerID == PROVIDER_GOOGLE) ||
            (user.emailVerified);

         */
        PushNotificationsManager().init(context);

        await getContactInfo();

        if (!listenersRegistered) {
          registerAllSnapshotListeners();
          listenersRegistered = true;
        }
      }
      else {
        if (areAllSnapshotListenersRegistered) {
          cancelAllSnapshotListeners();
          listenersRegistered = false;
        }

        clearAllData();
      }

      setState(() {
        _currentUser = user;
        _userDocExists = userDocExists;
        _emailVerified = localSettings.emailVerified;
        _initFinished = true;
      });
    });
  }

  void onNavBarTapped(int index) {
    if (_currentIndex == index) return;

    setState(() {
      _prevIndex = _currentIndex;
      _currentIndex = index;
    });
    AnimationController controller = _animControllers[_currentIndex];
    controller.reset();
    controller.forward();

  }

  Widget loadingWidget(String loadingText) {
    return Scaffold(
      body: Container(
        color: CustomColors.colorPrimary,
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: <Widget>[
              SizedBox(
                width: Dimens.imageSizeSmall,
                height: Dimens.imageSizeSmall,
                child: CircularProgressIndicator(),
              ),
              Padding(
                padding: EdgeInsets.all(10),
                child: Text(
                  loadingText,
                  style: Styles.listHeader,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

