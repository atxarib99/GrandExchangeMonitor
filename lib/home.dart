import 'package:GrandExchangeMonitor/PageInterface.dart';
import 'package:GrandExchangeMonitor/searchpage.dart';
import 'package:flutter/material.dart';

class Home extends StatefulWidget {

  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<Home> implements PageInterface {

  //holds which page we are on, defined by an enum
  //Error 404: class doesn't exist yet
  
  //Each page
  SearchPage searchPage = new SearchPage();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // drawer: NavDrawer(),
      appBar: searchPage.getAppBar(),
      body: searchPage.getBody(),
      floatingActionButton: searchPage.getFAB(),
    );
  }

  @override
  AppBar getAppBar() {
    // TODO: implement getAppBar
    throw UnimplementedError();
  }

  @override
  Padding getBody() {
    // TODO: implement getBody
    throw UnimplementedError();
  }

  @override
  FloatingActionButton getFAB() {
    // TODO: implement getFAB
    throw UnimplementedError();
  }

}