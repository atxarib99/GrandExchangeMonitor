import 'package:GrandExchangeMonitor/NavDrawer.dart';
import 'package:GrandExchangeMonitor/communicator.dart';
import 'package:GrandExchangeMonitor/home.dart';
import 'package:GrandExchangeMonitor/itempage.dart';
import 'package:GrandExchangeMonitor/listitem.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class WatchlistPage extends StatefulWidget {
  
  final HomePageState parent;
  
  WatchlistPage(this.parent);

  _WatchlistPageState createState() => _WatchlistPageState(parent);

}

class _WatchlistPageState extends State<WatchlistPage> {

  final HomePageState parent;

  Communicator communicator = new Communicator();

  _WatchlistPageState(this.parent) {
    _buildWatchlist();
  }

  List<ListItem> watchlistItems = new List<ListItem>();

  void _buildWatchlist() async {
    watchlistItems = new List<ListItem>();
    SharedPreferences prefs = await SharedPreferences.getInstance();
    List<String> watchList = (prefs.getStringList('watchlist'));
    if(watchList == null) {
      watchList = new List<String>();
      watchlistItems.add(ListItem('13190'));
    }
    watchList.forEach((element) {
      watchlistItems.add(ListItem(element));
    });
    setState(() {});
  }

  AppBar getAppBar(BuildContext context) {
    return AppBar(
      title: Text('Watchlist'),
    );
  }
  
  Padding getBody(BuildContext context) {
    if(watchlistItems == null) {
      _buildWatchlist();
      return Padding(padding: EdgeInsets.all(6.0));
    }
    return Padding(
      padding: EdgeInsets.all(6.0),
      child: 
        ListView.builder(
            itemBuilder: (BuildContext context, int index) {
              return GestureDetector(
                child: watchlistItems[index],
                onTap: () => 
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => ItemPage(watchlistItems[index].id))
                      ),
              );
            },
            itemCount: watchlistItems.length));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: getAppBar(context),
      body: getBody(context),
      drawer: NavDrawer(parent, communicator.getRandomImage()),
    );
  }
}