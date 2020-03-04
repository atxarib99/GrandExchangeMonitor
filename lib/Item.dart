import 'dart:core';

class Item {
  //image url
  final String imageURL;

  //Basic information
  final int id;
  final String type;
  final String name;
  final String description;
  final String currentTrend;
  final int currentPrice;
  final String todayTrend;
  final int todayChange;
  final bool members;
  
  //trend information
  final String thirtyDayTrend;
  final String thirtyDayChange;

  final String ninetyDayTrend;
  final String ninetyDayChange;
  
  final String oneEightyDayTrend;
  final String oneEightyDayChange;

  Item(this.id, this.type, this.name, this.description, this.currentTrend, this.currentPrice, this.todayTrend, this.todayChange, this.members, this.thirtyDayTrend, this.thirtyDayChange, this.ninetyDayTrend, this.ninetyDayChange, this.oneEightyDayTrend, this.oneEightyDayChange, this.imageURL);
  
  Item.fromJSON(Map<String,dynamic> json)
    : id = json['item']['id'],
      imageURL = json['item']['icon_large'],
      type = json['item']['type'],
      name = json['item']['name'],
      description = json['item']['description'],
      currentTrend = json['item']['current']['trend'],
      currentPrice = parseRuneType(json['item']['current']['price'].toString()),
      todayTrend = json['item']['today']['trend'],
      todayChange = parseRuneType(json['item']['today']['change'].toString()),
      members = (json['item']['members']).toLowerCase() == 'true',
      thirtyDayTrend = json['item']['day30']['trend'],
      thirtyDayChange = json['item']['day30']['change'],
      ninetyDayTrend = json['item']['day90']['trend'],
      ninetyDayChange = json['item']['day90']['trend'],
      oneEightyDayTrend = json['item']['day180']['trend'],
      oneEightyDayChange = json['item']['day180']['trend'];
  
  Item.fromDefault()
    : id = 13190,
      imageURL = "http://services.runescape.com/m=itemdb_oldschool/1582802986184_obj_big.gif?id=13190",
      type = "Default",
      name = "Old School Bond",
      description = "This bond can be redeemed for membership.",
      currentTrend = "Neutral",
      currentPrice = 4700000,
      todayTrend = "Positive",
      todayChange = 22700,
      members = false,
      thirtyDayTrend = "negative",
      thirtyDayChange = "-3.0%",
      ninetyDayTrend = "negative",
      ninetyDayChange = "-15.0%",
      oneEightyDayTrend = "positive",
      oneEightyDayChange = "+8.0%";

  static int parseRuneType(String runeType) {
    if(runeType == null || runeType == 'null') {
      return 0;
    }
    String parsed = runeType.replaceAll(',', '');
    if(parsed.contains("k")) {
      parsed = parsed.substring(0, parsed.length - 1);
      return (double.parse(parsed) * 1000).round();
    }
    if(parsed.contains("m")) {
      parsed = parsed.substring(0, parsed.length - 1);
      return (double.parse(parsed) * 1000000).round();
    }
    if(parsed.contains("b")) {
      parsed = parsed.substring(0, parsed.length - 1);
      return (double.parse(parsed) * 1000000000).round();
    }
    return int.parse(parsed);
  }
}