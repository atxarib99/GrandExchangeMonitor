import 'package:GrandExchangeMonitor/PageInterface.dart';
import 'package:GrandExchangeMonitor/home.dart';
import 'package:flutter/material.dart';

class WatchlistPage implements PageInterface {

  @override
  AppBar getAppBar(BuildContext context) {
    return AppBar(title: Text('Watchlist'),);
  }
  
  @override
  Padding getBody(BuildContext context) {
    return Padding(
      padding: EdgeInsets.all(6.0),
      child: ListView(children: <Widget>[
        ListTile(
          leading: Icon(Icons.search),
          title: Text('search'),
        ),
        ListTile(
          leading: Icon(Icons.sync),
          title: Text('Random'),
        ),
      ],),
    );
  }
  
  @override
  FloatingActionButton getFAB(BuildContext context) {
    return null;
  }
}