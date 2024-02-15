import 'dart:collection';
import 'dart:convert';
import 'package:convert/convert.dart' as converter;

import 'package:flutter/widgets.dart';
import 'package:http/http.dart' as http;
import 'package:karanda/common/api.dart';
import 'package:karanda/trade_market/market_item_model.dart';
import 'package:karanda/trade_market/trade_market_provider.dart';

class TradeMarketNotifier with ChangeNotifier {
  final provider = TradeMarketProvider();
  SplayTreeMap<String, MarketItemModel> itemInfo = SplayTreeMap();
  List<MarketItemModel> categories = [];
  List<MarketItemModel> items = [];

  TradeMarketNotifier() {
    getData();
  }

  Future<void> getData() async {
    List<String> data = await http
        .get(Uri.parse(Api.data))
        .then((value) => utf8.decode(converter.hex.decode(value.body)))
        .then((value) => value.split('\n'));
    String ver = data.first;
    String splitPattern = ver.characters.last;
    ver = ver.replaceAll(splitPattern, '');
    data.removeAt(0);
    SplayTreeMap<String, MarketItemModel> itemDataMap = SplayTreeMap();
    for(String line in data){
      MarketItemModel item = MarketItemModel.fromStringData(line, splitPattern);
      itemDataMap[item.code] = item;
    }
    itemInfo = itemDataMap;
    notifyListeners();
  }

  void testApi() {
    getData();
  }
}
