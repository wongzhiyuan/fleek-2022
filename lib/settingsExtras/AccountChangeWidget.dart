import 'dart:async';

import 'package:fleek/entry/SignInScreen.dart';
import 'package:fleek/global/globalFunctions.dart';
import 'package:fleek/global/globalItems.dart';
import 'package:fleek/values/colors.dart';
import 'package:fleek/values/strings.dart';
import 'package:fleek/values/styles.dart';
import 'package:flutter/material.dart';
import 'package:progress_dialog/progress_dialog.dart';

class AccountChangeWidget extends StatefulWidget {
  final String type;

  AccountChangeWidget({this.type});
  _AccountChangeState createState() => _AccountChangeState();
}

class _AccountChangeState extends State<AccountChangeWidget> {
  String type;
  final _formKey = GlobalKey<FormState>();
  final _passwordKey = GlobalKey<FormState>();
  bool _loginFailed = true;

  TextEditingController passwordController = new TextEditingController();
  TextEditingController initialController = new TextEditingController();
  TextEditingController confirmController = new TextEditingController();

  StreamSubscription emailVerifiedListener;
  bool listenerRegistered = false;
  @override
  void initState() {
    super.initState();
    type = widget.type;
  }

  @override
  void dispose() {
    if (listenerRegistered) emailVerifiedListener.cancel();
    passwordController.dispose();
    initialController.dispose();
    confirmController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bool isEmail = (type == EMAIL);
    final TextInputType inputType = isEmail ? TextInputType.emailAddress : TextInputType.visiblePassword;
    return Scaffold(
      appBar: AppBar(
        title: Text("Change Your $type"),
      ),
      body: Form(
        key: _formKey,
        child: Center(
          child: ListView(
            shrinkWrap: true,
            children: <Widget>[
              TextFormField(
                keyboardType: inputType,
                obscureText: !isEmail,
                controller: initialController,
                validator: validFormatValidator,
                decoration: InputDecoration(
                  labelText: "Enter new ${type.toLowerCase()}",
                  border: Styles.inputBorder
                ),
              ),
              TextFormField(
                keyboardType: inputType,
                obscureText: !isEmail,
                controller: confirmController,
                autovalidate: true,
                validator: matchValidator,
                decoration: InputDecoration(
                  labelText: "Confirm new ${type.toLowerCase()}",
                  border: Styles.inputBorder
                ),
              ),

              ButtonTheme(
                minWidth: double.infinity,
                child: RaisedButton(
                  onPressed: () => formSubmit(context),
                  color: CustomColors.colorPrimary,
                  child: Text(
                    Strings.buttonSubmit,
                    style: Styles.submitButton,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /*
  Future<void> showLoginDialog(BuildContext context) {
    void login(BuildContext context) async {
      void error() => showDialogWithMessage(context, "Login failed, please try again.", "Error signing you in");
      if (_passwordKey.currentState.validate()) {
        FirebaseAuth auth = FirebaseAuth.instance;
        FirebaseUser user;
        print("email: ${currentUser.email}, pass: ${passwordController.text}");
        ProgressDialog ld = styleDialog(getLoadingDialog(context), "Verifying...");

        await ld.show();
        await auth.signInWithEmailAndPassword(
            email: currentUser.email, password: passwordController.text)
            .then((AuthResult result) => user = result.user);
        passwordController.clear();
        await ld.hide();

        if (user != null) {
          currentUser = user;
          //reloadUser();
          print(currentUser.email);
          _loginFailed = false;
          Navigator.pop(context);
        }
        else {
          _loginFailed = true;
          error();
        }
      }
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

   */

  String validFormatValidator(String value) {
    if (value == null || value.length == 0) return Strings.errorEmpty;
    return (type == EMAIL) ? emailValidator(value) : passwordValidator(value);
  }

  String matchValidator(String value) {
    if (value != initialController.text.toString().trim()) return "${type}s must match.";
    else if (value == null || value.length == 0) return Strings.errorEmpty;
    return null;
  }

  void formSubmit(BuildContext context) async {
    if (_formKey.currentState.validate()) {
      //await showLoginDialog(context);
      //if (_loginFailed) return;

      ProgressDialog ld = getLoadingDialog(context);
      ld = styleDialog(ld, "Changing your ${type.toLowerCase()}");
      await ld.show();


      final String input = confirmController.text.toString().trim();
      switch (type) {
        case (EMAIL):
          currentParseUser.emailAddress = input;
          break;
        case (PASSWORD):
          currentParseUser.password = input;
          break;
      }
      await currentParseUser.save();
      await ld.hide();
      Navigator.pop(context);
      /*
      if (type == EMAIL) currentUser.updateEmail(input).whenComplete(() async {
        currentUser.sendEmailVerification().whenComplete(() => intervalRefreshAuth(5));
        await ld.hide();

        ProgressDialog ed = getLoadingDialog(context);
        ed = styleDialog(ed, "We've sent a verification e-mail to your new e-mail. Please complete verification to continue.");

        await ed.show();
        emailVerifiedListener = aEmailVerified.stream.listen((verified) async {
          await ed.hide();
          Navigator.pop(context);
        });
        listenerRegistered = true;
      });
      else if (type == PASSWORD) currentUser.updatePassword(input).whenComplete(() async {
        await ld.hide();
        Navigator.pop(context);
      });

       */
    }
  }
}