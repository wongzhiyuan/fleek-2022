import 'package:fleek/global/globalItems.dart';

class Review {
  double rating = 0;
  String desc = "";
  String author = "";
  String receiver = "";

  Review({this.rating, this.desc, this.author, this.receiver});

  Map<String, dynamic> toMap() => {
    REVIEW_RATING : this.rating,
    REVIEW_CONTENT : this.desc,
    REVIEW_AUTHOR : this.author,
    REVIEW_RECEIVER : this.receiver,
  };

  Review fromMap(Map<String, dynamic> map) => new Review(
    rating: double.parse(map[REVIEW_RATING].toString()),
    desc: map[REVIEW_CONTENT].toString(),
    author: map[REVIEW_AUTHOR].toString(),
    receiver: map[REVIEW_RECEIVER].toString(),
  );
}