import 'package:GrandExchangeMonitor/marginpage.dart';
import 'package:GrandExchangeMonitor/pagenum.dart';
import 'package:GrandExchangeMonitor/searchpage.dart';
import 'package:GrandExchangeMonitor/watchlist.dart';
import 'package:flutter/material.dart';

class Home extends StatefulWidget {
  @override
  HomePageState createState() => HomePageState();
}

class HomePageState extends State<Home> {
  //holds which page we are on, defined by an enum
  PageNum page = PageNum.Search;

  void refresh() {
    setState(() {});
  }

  Widget getScreenWidget() {
    if (page == PageNum.Search) {
      return new SearchPage(this);
    }
    if (page == PageNum.Watchlist) {
      return new WatchlistPage(this);
    }
    if (page == PageNum.Margins) {
      return new MarginPage(this);
    } else {
      return Center(
        child: Text("Something has gone terribly wrong!"),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return getScreenWidget();
  }
}
