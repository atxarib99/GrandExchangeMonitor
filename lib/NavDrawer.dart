import 'package:GrandExchangeMonitor/pagenum.dart';
import 'package:GrandExchangeMonitor/home.dart';
import 'package:flutter/material.dart';

class NavDrawer extends StatelessWidget {

  //enum will exist here
  final HomePageState parent;
  final String _url;

  NavDrawer(this.parent, this._url);
  
  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: <Widget>[
          DrawerHeader(
            child: Align(
              alignment: Alignment.bottomLeft,
              child: Text(
                'Grand Exchange Monitor',
                style: TextStyle(color: Colors.white, fontSize: 20),
              ),
            ),
            decoration: BoxDecoration(
                color: Colors.blue,
                image: DecorationImage(
                    fit: BoxFit.fitHeight,
                    image: NetworkImage(_url)
                )
            ), //TODO: Update this image
          ),
          ListTile(
            leading: Icon(Icons.search),
            title: Text('Search'),
            onTap: () {Navigator.of(context).pop(); parent.page = PageNum.Search; parent.refresh();},
          ),
          ListTile(
            leading: Icon(Icons.star),
            title: Text('Watchlist'),
            onTap: () {Navigator.of(context).pop(); parent.page = PageNum.Watchlist; parent.refresh();},
          ),
          ListTile(
            leading: Icon(Icons.star), //TODO: update icon
            title: Text('Margins'),
            onTap: () {Navigator.of(context).pop(); parent.page = PageNum.Margins; parent.refresh();}
          )
        ],
      ),
    );
  }
}