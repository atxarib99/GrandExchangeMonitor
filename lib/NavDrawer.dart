import 'package:GrandExchangeMonitor/pagenum.dart';
import 'package:GrandExchangeMonitor/home.dart';
import 'package:flutter/material.dart';

class NavDrawer extends StatelessWidget {

  //enum will exist here
  final HomePageState parent;

  NavDrawer(this.parent);

  //returns the selection to the asker
  // myenum getSelection() {
  //   return myenum.selected;
  // }
  
  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: <Widget>[
          DrawerHeader(
            child: Text(
              'Tell me where to go',
              style: TextStyle(color: Colors.white, fontSize: 25),
            ),
            decoration: BoxDecoration(
                color: Colors.green,
                image: DecorationImage(
                    fit: BoxFit.fill,
                    image: AssetImage('assets/images/downtrend.png'))), //TODO: Update this image
          ),
          ListTile(
            leading: Icon(Icons.search),
            title: Text('search'),
            onTap: () {Navigator.of(context).pop(); parent.page = PageNum.Search; parent.refresh();},
          ),
          ListTile(
            leading: Icon(Icons.watch_later),
            title: Text('Watchlist'),
            onTap: () {Navigator.of(context).pop(); parent.page = PageNum.Watchlist; parent.refresh();},
          ),
        ],
      ),
    );
  }
}