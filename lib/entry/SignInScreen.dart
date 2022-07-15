import 'package:fleek/global/globalFunctions.dart';
import 'package:fleek/global/globalItems.dart';
import 'package:fleek/popup/UpdateProfileWidget.dart';
import 'package:fleek/values/colors.dart';
import 'package:fleek/values/dimens.dart';
import 'package:fleek/values/ints.dart';
import 'package:fleek/values/strings.dart';
import 'package:fleek/values/styles.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:parse_server_sdk/parse_server_sdk.dart';
import 'package:progress_dialog/progress_dialog.dart';

final _backgroundImage = DecorationImage(
  image: Image.network("https://66.media.tumblr.com/0b585f53f013eccca9a6ef383f2774be/tumblr_ntjdjr74G71r7txbmo1_400.jpg").image,
  colorFilter: CustomColors.grayscaleFilter,
  fit: BoxFit.cover,
);

class SignInScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    globalDialog = styleDialog(globalDialog, "Signing you in...");

    return new Scaffold(
      body: Container(
        decoration: BoxDecoration(
          image: _backgroundImage,
        ),
        child: Container(
          alignment: Alignment.center,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: <Widget>[
              //logo and welcome message
              Text(
                "#Hashtag",
                style: Styles.signInBanner,
                textAlign: TextAlign.center,
              ),
              new EmailForm(),

            ],
          ),
        ),
      ),
    );
  }
}

Future<void> googleAuth(GoogleSignIn _googleSignIn) async {
  final GoogleSignInAccount googleUser = await _googleSignIn.signIn();
  final GoogleSignInAuthentication googleAuth = await googleUser.authentication;

  final ParseResponse response = await ParseUser.loginWith('google', googleAuthData(googleUser, googleAuth));
  (response.success) ? await parseRefreshUser() : print(response.error);
}

Widget _paddingUp(Widget child) {
  return Padding(
    padding: EdgeInsets.only(top: Dimens.paddingSignInForm),
    child: child,
  );
}

class EmailForm extends StatefulWidget {
  @override
  EmailFormState createState() {
    return EmailFormState();
  }
}

InputDecoration _getInputDecor({String labelText, String hintText}) {
  return InputDecoration(
    filled: true,
    fillColor: CustomColors.translucent(0.7),
    labelText: labelText,
    enabledBorder: Styles.signInInputBorder,
    border: Styles.signInInputBorder,
  );
}

class EmailFormState extends State<EmailForm> {
  final GoogleSignIn _googleSignIn  = GoogleSignIn();

  final _formKey = GlobalKey<FormState>();
  final usernameController = new TextEditingController();
  final emailController = new TextEditingController();
  final passwordController = new TextEditingController();

  @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  final buttonShape = Styles.roundedButtonShape;

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      child: Padding(
        padding: EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: <Widget>[
            _paddingUp(
              TextFormField(
                keyboardType: TextInputType.text,
                decoration: _getInputDecor(
                  labelText: Strings.labelTextUsername,
                ),
                validator: usernameValidator,
                controller: usernameController,
              ),
            ),
            _paddingUp(
              TextFormField(
                keyboardType: TextInputType.emailAddress,
                decoration: _getInputDecor(
                  labelText: Strings.labelTextEmail,
                ),
                validator: emailValidator,
                controller: emailController,
              ),
            ),
            _paddingUp(
              TextFormField(
                keyboardType: TextInputType.visiblePassword,
                obscureText: true,
                decoration: _getInputDecor(
                  labelText: Strings.labelTextPassword,
                ),
                validator: passwordValidator,
                controller: passwordController,
              ),
            ),
            _paddingUp(
              ButtonTheme(
                minWidth: double.infinity,
                child: RaisedButton(
                  color: CustomColors.colorPrimary,
                  shape: buttonShape,
                  onPressed: () async {
                    if (_formKey.currentState.validate()) {
                      var parseUser = new ParseUser(
                        usernameController.text,
                        passwordController.text,
                        emailController.text,
                      );

                      await globalDialog.show();
                      String errorMessage = "";

                      var response = await parseUser.login();

                      if (response.success) await parseRefreshUser();
                      else {
                        print(response.error);
                        switch (response.error.code) {
                          case (125): errorMessage = "The email address you've entered is invalid.";
                          break;
                          case (207): errorMessage = "The email address or password you've entered is incorrect.";
                          break;
                          default: errorMessage = response.error.message;
                          break;
                        }
                      }

                      /*
                      final emailCredential = EmailAuthProvider.getCredential(
                          email: emailController.text,
                          password: passwordController.text
                      );

                      FirebaseUser user;

                      await FirebaseAuth.instance.signInWithCredential(emailCredential)
                          .then((AuthResult result) => user = result.user)
                          .catchError((Object errorObject) {
                        PlatformException error = errorObject as PlatformException;
                        print(error.code.toString() == 'ERROR_USER_NOT_FOUND');
                        switch (error.code.toString()) {
                          case ('ERROR_WRONG_PASSWORD'): {
                            errorMessage = "You've entered the wrong password for this account.";
                          }
                          break;
                          case ('ERROR_USER_NOT_FOUND'): {
                            errorMessage = "There is no account linked to this email.";
                          }
                          break;
                        }
                      });

                       */

                      if (currentParseUser != null){
                        Navigator.pop(context);
                      }
                      else showDialogWithMessage(context, errorMessage, "Error signing you in");
                    }
                  },
                  child: Text(Strings.buttonSignIn),
                ),
              ),
            ),
            _paddingUp(
              ButtonTheme(
                minWidth: double.infinity,
                child: RaisedButton.icon(
                  color: CustomColors.colorPrimary,
                  shape: buttonShape,
                  onPressed: _handleGoogleSignIn,
                  icon: SvgPicture.asset(
                    'assets/logos/google-icon.svg',
                    width: Dimens.signInGoogleSide,
                    height: Dimens.signInGoogleSide,
                  ),
                  label: Text(Strings.buttonSignInGoogle),
                ),
              ),
            ),
            _paddingUp(
              ButtonTheme(
                minWidth: double.infinity,
                child: RaisedButton(
                  color: CustomColors.colorPrimary,
                  shape: buttonShape,
                  child: Text(Strings.buttonRegister),
                  onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (context) => EmailRegisterWidget())),
                ),
              ),

            ),
          ],
        ),
      ),
    );
  }

  void _handleGoogleSignIn() async {
    await googleAuth(_googleSignIn,);
    await globalDialog.show();
  }
}

class EmailRegisterWidget extends StatefulWidget {
  _EmailRegisterState createState() => _EmailRegisterState();
}

class _EmailRegisterState extends State<EmailRegisterWidget> {
  final _formKey = GlobalKey<FormState>();
  final usernameController = new TextEditingController();
  final emailController = new TextEditingController();
  final passwordController = new TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(body: Container(
      decoration: BoxDecoration(
        image: _backgroundImage,
      ),
      alignment: Alignment.center,
      child: Form(
        key: _formKey,
        child: Padding(
          padding: EdgeInsets.all(20),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: <Widget>[
              Text(
                "Make an account. It's free!",
                textAlign: TextAlign.center,
                style: Styles.signInBanner,
              ),
              _paddingUp(
                TextFormField(
                  keyboardType: TextInputType.text,
                  decoration: _getInputDecor(
                    labelText: Strings.labelTextUsername,
                  ),
                  validator: usernameValidator,
                  controller: usernameController,
                ),
              ),
              _paddingUp(
                TextFormField(
                  keyboardType: TextInputType.emailAddress,
                  decoration: _getInputDecor(
                    labelText: Strings.labelTextEmail,
                  ),
                  validator: emailValidator,
                  controller: emailController,
                ),
              ),
              _paddingUp(
                TextFormField(
                  keyboardType: TextInputType.visiblePassword,
                  obscureText: true,
                  decoration: _getInputDecor(
                    labelText: Strings.labelTextPassword,
                  ),
                  validator: passwordValidator,
                  controller: passwordController,
                ),
              ),
              _paddingUp(
                ButtonTheme(
                  minWidth: double.infinity,
                  child: RaisedButton(
                    color: CustomColors.colorPrimary,
                    shape: Styles.roundedButtonShape,
                    onPressed: () async {
                      if (_formKey.currentState.validate()) {
                        ProgressDialog ld = styleDialog(getLoadingDialog(context), "Registering...");
                        await ld.show();

                        var response = await (new ParseUser(
                          usernameController.text,
                          passwordController.text,
                          emailController.text,
                        )..set(USER_HAS_DATA, false))
                        .signUp();

                        (response.success) ? await parseRefreshUser() : print(response.error);

                        /*
                        final FirebaseUser user = (await FirebaseAuth.instance.createUserWithEmailAndPassword(
                            email: emailController.text,
                            password: passwordController.text
                        )).user;

                         */

                        await ld.hide();

                        if (currentParseUser != null) {
                          /*
                          ld = styleDialog(ld, "Sending verification email...");
                          await ld.show();
                          user.sendEmailVerification().whenComplete(() async {await ld.hide();});
                           */
                          Navigator.pop(context);
                          Navigator.pop(context);
                        }
                        else showDialogWithMessage(context, "There has been an error registering you. Please try again.", "Error registering");
                      }
                    },
                    child: Text(Strings.buttonSubmit),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    ),);
  }

}

String emailValidator(String value) {
  RegExp emailCheck = new RegExp(
    r"(\S+@\S+[.]\S+)",
    caseSensitive: false,
    multiLine: false,
  );

  if (value.isEmpty) {
    return Strings.errorEmpty;
  }
  else if (!emailCheck.hasMatch(value) ) {
    return Strings.errorInvalidEmail;
  }

  return null;
}

String passwordValidator(String value) {
  if (value.isEmpty) {
    return Strings.errorEmpty;
  }
  else if (value.length < Ints.authPasswordMinChar) {
    return Strings.errorMinChar;
  }

  return null;
}
