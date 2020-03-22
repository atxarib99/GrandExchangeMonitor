import 'package:GrandExchangeMonitor/NavDrawer.dart';
import 'package:GrandExchangeMonitor/PageInterface.dart';
import 'package:GrandExchangeMonitor/searchpage.dart';
import 'package:flutter/material.dart';
class Home extends StatefulWidget {

  @override
  HomePageState createState() => HomePageState();
}

class HomePageState extends State<Home> implements PageInterface {

  //holds which page we are on, defined by an enum
  //Error 404: class doesn't exist yet

  //Each page
  SearchPage searchPage;

  void refresh() {
    setState(() {
      
    });
  }

  @override
  Widget build(BuildContext context) {
    if(searchPage == null) {
      searchPage = new SearchPage(this);
    }
    return Scaffold(
      drawer: NavDrawer(),
      appBar: searchPage.getAppBar(context),
      body: searchPage.getBody(context),
      floatingActionButton: FloatingActionButton(
        onPressed: () {setState(() {
          print('we did this');
        });},
      ),
    );
  }

  @override
  AppBar getAppBar(BuildContext context) {
    // TODO: implement getAppBar
    throw UnimplementedError();
  }

  @override
  Padding getBody(BuildContext context) {
    // TODO: implement getBody
    throw UnimplementedError();
  }

  @override
  FloatingActionButton getFAB(BuildContext context) {
    // TODO: implement getFAB
    throw UnimplementedError();
  }

}