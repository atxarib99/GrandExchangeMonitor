import 'package:GrandExchangeMonitor/AnimatedFloatingActionButton.dart';
import 'package:GrandExchangeMonitor/home.dart';
import 'package:GrandExchangeMonitor/marginlistitem.dart';
import 'package:flutter/material.dart';

import 'NavDrawer.dart';
import 'communicator.dart';

class MarginPage extends StatefulWidget {
  final HomePageState parent;

  MarginPage(this.parent);

  @override
  _MarginPageState createState() => _MarginPageState(parent);
}

class _MarginPageState extends State<MarginPage> {
  final HomePageState parent;

  //holds the communicator to the server
  Communicator communicator = new Communicator();

  FloatingActionButton fab;

  _MarginPageState(this.parent) {
    fab = new FloatingActionButton(
      onPressed: FABOnPressed,
      tooltip: 'New',
      child: Icon(Icons.add),
    );
  }

  void FABOnPressed() {
    //TODO: Implement
  }

  AppBar getAppBar(BuildContext context) {
    return AppBar(title: Text('Margins'));
  }

  Padding getBody(BuildContext context) {
    return Padding(
        padding: EdgeInsets.all(6.0),
        child: Center(child: MarginListItem() //stateless info widget,
            ));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: getBody(context),
      floatingActionButton: fab,
      appBar: getAppBar(context),
      drawer: NavDrawer(parent, communicator.getRandomImage()),
    );
  }
}
