import 'package:fleek/discoverExtras/DiscoverEndlessScrollWidget.dart';
import 'package:fleek/values/colors.dart';
import 'package:flutter/material.dart';

class DiscoverBrowseWidget extends StatelessWidget {
  final String query;
  final String queryType;
  final String gender;

  DiscoverBrowseWidget({this.query, this.queryType, this.gender});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: CustomColors.colorPrimary,
        iconTheme: IconThemeData(
          color: CustomColors.colorPrimaryDark,
        ),
        elevation: 0,
      ),
      body: new DiscoverEndlessScrollWidget(
        query: query,
        queryType: queryType,
        gender: gender,
      ),
    );
  }

}