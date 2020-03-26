import 'dart:convert';
import 'dart:math';

import 'package:GrandExchangeMonitor/Item.dart';
import 'package:GrandExchangeMonitor/NavDrawer.dart';
import 'package:GrandExchangeMonitor/PageInterface.dart';
import 'package:GrandExchangeMonitor/pagenum.dart';
import 'package:GrandExchangeMonitor/searchpage.dart';
import 'package:GrandExchangeMonitor/watchlist.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart';
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

  //holds url for random image
  String _url = 'http://services.runescape.com/m=itemdb_oldschool/1582802986184_obj_big.gif?id=13190';
  
  //url data to prevent repetitive code
  final String _BASE_URL = "http://services.runescape.com/m=itemdb_oldschool";
  final String _BASIC_APPEND = "/api/catalogue/detail.json?item=";
  
  //load id to name map
  Future<String> loadAsset() async {
    //for some reason if you just do assets: assets/ this function does not work.
    return await rootBundle.loadString('assets/dict/IDtoItemName.csv');
  }

  //searches for an item based on id
  Future<Response> searchItem(String search) {
    //construct url to search from
    String finalURL = _BASE_URL + _BASIC_APPEND + search;
    // return the future object that should hold a response from server
    return get(
      finalURL,
      // Send authorization headers to the backend.
      headers: {"Access-Control-Allow-Origin": "*"},
    );
  }

  
  void getRandomItemImage() async {
    Random rand = new Random();
    int randomNum = rand.nextInt(3011); 
    //loads the item to id map
    loadAsset().then((value) {
      //split by lines
      List<String> lines = value.split("\n");
      //call the search by id method, then for the response
      searchItem(lines[randomNum].split(",")[0]).then((res) {
        //convert to a map from the JSON response
        Map<String, dynamic> body = json.decode(res.body);
        //set the item to the item generated from the JSON
        Item item = Item.fromJSON(body);
        _url = item.imageURL;
      });
    });
  }

  void refresh() {
    setState(() {
      
    });
  }

  void resetOthers() {
    if(page != PageNum.Search) {
      searchPage = null;
    }
    if(page != PageNum.Watchlist) {
      watchlistPage = null;
    }
  }

  @override
  Widget build(BuildContext context) {
    if(searchPage == null && page == PageNum.Search) {
      searchPage = new SearchPage(this);
    }
    if(watchlistPage == null) {
      watchlistPage = new WatchlistPage(this);
    }
    getRandomItemImage();
    return Scaffold(
      drawer: NavDrawer(this, _url),
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