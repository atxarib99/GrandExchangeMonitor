import 'dart:convert';

import 'package:GrandExchangeMonitor/Item.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart';

class ListItem extends StatefulWidget {
  final String id;
  ListItem(this.id);

  @override
  _ListItemState createState() => _ListItemState(id);
}

class _ListItemState extends State<ListItem> {

  //the item to be shown
  Item _item = Item.fromDefault();

  //constructor that requires a provided string
  _ListItemState(String id) {
    createItemFromID(id);
  }

  String getAppropriateSubstring(String str) {
    if(str.length < 30) {
      return str;
    } else {
      return str.substring(0, 30) + '...';
    }
  }

  @override
  Widget build(BuildContext context) {
    if(_item.defaultCreation) {
      return Container();
    }
    //the structure for this item as a listview item.
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: <Widget>[
        Row(children: <Widget>[
          FadeInImage.assetNetwork(placeholder: 'assets/images/placeholder.png', image: _item.imageURL),
          Column(crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text('${_item.name}',
                style: Theme.of(context).textTheme.bodyText2,
              ),
              Text('\t\t' + getAppropriateSubstring('${_item.description}'),
                style: Theme.of(context).textTheme.bodyText1,
              )
            ],),
        ],),
        Column(children: <Widget>[
          Text('${_item.currentPrice}'),
          Text('${_item.currentTrend}')
        ],)
    ],);
  }

    //searches for an item based on id
  Future<Response> searchItem(String search) {
    String baseURL = "http://services.runescape.com/m=itemdb_oldschool";
    String basicAppend = "/api/catalogue/detail.json?item=";
    //construct url to search from
    String finalURL = baseURL + basicAppend + search;
    // return the future object that should hold a response from server
    return get(
      finalURL,
      // Send authorization headers to the backend.
      headers: {"Access-Control-Allow-Origin": "*"},
    );
  }
  
  void createItemFromID(String id) {
    //call the search by id method, then for the response
    searchItem(id).then((res) {
      //convert to a map from the JSON response
      Map<String, dynamic> body = json.decode(res.body);
      //set the item to the item generated from the JSON
      setState(() {
        _item = Item.fromJSON(body);
      });
    });
  }
  
}