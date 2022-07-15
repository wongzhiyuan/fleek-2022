import 'package:fleek/global/globalItems.dart';
import 'package:fleek/values/styles.dart';
import 'package:flutter/material.dart';

class QnAWidget extends StatelessWidget {
  final String title;
  final List<dynamic> faqList;

  QnAWidget({this.title, this.faqList});

  final Map<RegExp, String> specials = {
    new RegExp(r"(<REQUIRE_EMAIL>)"): localSettings.email,
    new RegExp(r"(<REQUIRE_HOTLINE>)") : localSettings.hotline,
  };

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: Text(this.title),
      ),
      body: ListView.builder(
        itemCount: faqList.length,
        itemBuilder: (BuildContext context, int index) {
          Map<String, String> question = new Map<String, String>.from(faqList[index]);

          String answer = question[FAQ_ANSWER];

          specials.forEach((key, value) {
            answer = answer.replaceAll(key, value);
          });

          return ExpansionTile(
            title: Text(
              question[FAQ_QUESTION],
              style: Styles.listHeader,
            ),
            children: <Widget>[
              ListTile(
                title: Text(answer),
              ),
            ],
          );
        },
      ),
    );
  }

}