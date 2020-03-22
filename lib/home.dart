import 'package:GrandExchangeMonitor/NavDrawer.dart';
import 'package:GrandExchangeMonitor/PageInterface.dart';
import 'package:GrandExchangeMonitor/pagenum.dart';
import 'package:GrandExchangeMonitor/searchpage.dart';
import 'package:GrandExchangeMonitor/watchlist.dart';
import 'package:flutter/material.dart';
class Home extends StatefulWidget {

  @override
  HomePageState createState() => HomePageState();
}

class HomePageState extends State<Home> implements PageInterface {

  //holds which page we are on, defined by an enum
  PageNum page = PageNum.Search;

  //Each page
  SearchPage searchPage;
  WatchlistPage watchlistPage;

  void refresh() {
    setState(() {
      
    });
  }

  @override
  Widget build(BuildContext context) {
    if(searchPage == null) {
      searchPage = new SearchPage(this);
    }
    if(watchlistPage == null) {
      watchlistPage = new WatchlistPage();
    }
    return Scaffold(
      drawer: NavDrawer(this),
      appBar: getAppBar(context),
      body: getBody(context),
      floatingActionButton: getFAB(context),
    );
  }

  @override
  AppBar getAppBar(BuildContext context) {
    switch(page) {   
      case PageNum.Search:
        return searchPage.getAppBar(context);
        break;
      case PageNum.Watchlist:
        return watchlistPage.getAppBar(context);
        break;
    }

    return null;
  }

  @override
  Padding getBody(BuildContext context) {
    switch(page) {   
      case PageNum.Search:
        return searchPage.getBody(context);
        break;
      case PageNum.Watchlist:
        return watchlistPage.getBody(context);
        break;
    }

    return null;
  }

  @override
  FloatingActionButton getFAB(BuildContext context) {
    switch(page) {   
      case PageNum.Search:
        return searchPage.getFAB(context);
        break;
      case PageNum.Watchlist:
        return watchlistPage.getFAB(context);
        break;
    }
    
    return null;
  }

}