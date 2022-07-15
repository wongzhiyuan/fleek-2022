import 'package:fleek/dataclasses/PProduct.dart';
import 'package:fleek/dataclasses/Product.dart';
import 'package:fleek/global/globalItems.dart';
import 'package:fleek/values/dimens.dart';
import 'package:fleek/widgetClasses/DefaultImageFile.dart';
import 'package:fleek/widgetClasses/DefaultImageNetwork.dart';
import 'package:flutter/material.dart';

class PurchasesWidget extends StatefulWidget {
  final String title = "You've Bought These";
  _PurchasesState createState() => _PurchasesState();
}

class _PurchasesState extends State<PurchasesWidget> {
  List<PProduct> displayList = [];

  @override
  void initState() {
    super.initState();
    refreshDisplayList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
      ),
      body: ListView.builder(
        itemCount: displayList.length,
        itemBuilder: (BuildContext context, int index) {
          PProduct product = displayList[index];

          if (product.title.isEmpty) return ListTile(
            title: Text("You haven't bought anything yet, or your item's sellers haven't marked them as sold."),
          );

          final imageWidth = Dimens.imageSizeSmall;
          return ListTile(
            leading: DefaultImageNetwork(
              image: product.images[0].url,
              width: imageWidth,
              height: imageWidth,
              fit: BoxFit.cover,
            ),
            title: Text(product.title),
            subtitle: Text("sold by @${takenDisplayNames[product.seller]}"),
            trailing: Text("\$${product.price}"),
          );
        }
      ),
    );
  }

  void refreshDisplayList() {
    displayList.clear();
    for (String id in currentUserCollection.bought) {
      displayList.add(parseShopCollection[id]);
    }

    displayList.sort((PProduct a, PProduct b) {
      return a.title.compareTo(b.title);
    });

    if (displayList.isEmpty) displayList.add(new PProduct());
  }

}