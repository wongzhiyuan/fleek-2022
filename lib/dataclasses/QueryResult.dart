import 'package:parse_server_sdk/parse_server_sdk.dart';

class QueryResult {
  ParseObject object;
  bool success;

  QueryResult({
    this.object,
    this.success,
  });
}