import 'package:fleek/discoverExtras/DiscoverEndlessScrollWidget.dart';
import 'package:fleek/global/globalItems.dart';
import 'package:fleek/values/dimens.dart';
import 'package:fleek/values/strings.dart';
import 'package:fleek/values/styles.dart';
import 'package:flutter/material.dart';

class DiscoverSearchWidget extends StatefulWidget {
  _DiscoverSearchWidgetState createState() => _DiscoverSearchWidgetState();
}

class _DiscoverSearchWidgetState extends State<DiscoverSearchWidget> {
  final _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() {
      aSearchUpdated.add(_searchController.text.toString());
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Search"),
      ),
      body: Column(
        mainAxisAlignment: MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: <Widget>[
          Padding(
            padding: EdgeInsets.all(Dimens.paddingDiscoverSearchBar),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                labelText: Strings.labelTextSearch,
                border: Styles.inputBorder,
              ),
            ),
          ),
          Expanded(
            child: DiscoverEndlessScrollWidget(
              query: "",
              queryType: INTENT_SEE_ALL_SEARCH,
            ),
          ),
        ],
      ),
    );
  }

}