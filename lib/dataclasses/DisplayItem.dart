import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:parse_server_sdk/parse_server_sdk.dart';

import 'PPost.dart';
import 'PProduct.dart';
import 'Post.dart';
import 'Product.dart';

class DisplayItem {
  bool isEmpty = false;
  bool isProduct = false;
  String id = "";
  String title = "";
  String author = "";
  String description = "";
  int timestamp = Timestamp.now().millisecondsSinceEpoch;
  ParseFile coverImage;
  List<ParseFile> images = [];
  List<String> likedBy = [];
  String type = "";
  List<String> styles = [];
  double price = 0.0;

  DisplayItem({
    this.isEmpty,
    this.isProduct,
    this.id,
    this.title,
    this.author,
    this.description,
    this.timestamp,
    this.coverImage,
    this.images,
    this.likedBy,
    this.type,
    this.styles,
    this.price,
  });

  DisplayItem fromProduct(PProduct product) {
    return DisplayItem(
      id: product.id,
      title: product.title,
      author: product.seller,
      description: product.description,
      timestamp: product.timestamp,
      coverImage: product.images[0],
      images: product.images,
      likedBy: product.likedBy,
      type: product.type,
      styles: product.styles,
      price: product.price,
      isProduct: true,
      isEmpty: false,
    );
  }

  DisplayItem fromPost(PPost post) {
    return DisplayItem(
      id: post.id,
      title: post.title,
      author: post.author,
      timestamp: post.timestamp,
      coverImage: post.image,
      images: [post.image],
      likedBy: post.likedBy,
      type: post.type,
      styles: post.styles,
      isProduct: false,
      isEmpty: false,
    );
  }
}