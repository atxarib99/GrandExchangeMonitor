import 'package:flutter/material.dart';

class NavDrawer extends StatelessWidget {

  //enum will exist here
  //error 404: enum doesn't exist yet

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
            onTap: () => {Navigator.of(context).pop()},
          ),
          ListTile(
            leading: Icon(Icons.sync),
            title: Text('Random'),
            onTap: () => {Navigator.of(context).pop()},
          ),
        ],
      ),
    );
  }
}