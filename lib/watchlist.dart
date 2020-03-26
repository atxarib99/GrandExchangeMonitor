import 'package:GrandExchangeMonitor/PageInterface.dart';
import 'package:GrandExchangeMonitor/home.dart';
import 'package:GrandExchangeMonitor/listitem.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class WatchlistPage implements PageInterface {

  final HomePageState parent;

  WatchlistPage(this.parent) {
    _buildWatchlist();
  }

  List<Widget> watchlistItems = new List<Widget>();

  void _buildWatchlist() async {
    watchlistItems = new List<Widget>();
    SharedPreferences prefs = await SharedPreferences.getInstance();
    List<String> watchList = (prefs.getStringList('watchlist'));
    if(watchList == null) {
      watchList = new List<String>();
      watchlistItems.add(ListItem('13190'));
    }
    watchList.forEach((element) {
      watchlistItems.add(ListItem(element));
    });
    parent.refresh();
  }

  @override
  AppBar getAppBar(BuildContext context) {
    return AppBar(
      title: Text('Watchlist'),
    );
  }
  
  @override
  Padding getBody(BuildContext context) {
    if(watchlistItems == null) {
      _buildWatchlist();
      return Padding(padding: EdgeInsets.all(6.0));
    }
    return Padding(
      padding: EdgeInsets.all(6.0),
      child: ListView(children: watchlistItems,),
    );
  }
  
  @override
  FloatingActionButton getFAB(BuildContext context) {
    return null;
  }
}