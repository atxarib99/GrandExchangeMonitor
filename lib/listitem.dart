
import 'package:GrandExchangeMonitor/Item.dart';
import 'package:GrandExchangeMonitor/communicator.dart';
import 'package:flutter/material.dart';

class ListItem extends StatefulWidget {
  final String id;
  ListItem(this.id);

  @override
  _ListItemState createState() => _ListItemState(id);
}

class _ListItemState extends State<ListItem> {

  //the item to be shown
  Item _item = Item.fromDefault();

  //Communicator for server comms
  Communicator communicator = new Communicator();

  //constructor that requires a provided string
  _ListItemState(String id) {
    createItemFromID(id);
  }

  String getAppropriateSubstring(String str) {
    if(str.length < 30) {
      return str;
    } else {
      return str.substring(0, 30) + '...';
    }
  }

  @override
  Widget build(BuildContext context) {
    if(_item.defaultCreation) {
      return Container();
    }
    //the structure for this item as a listview item.
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: <Widget>[
        Row(children: <Widget>[
          Hero(
            tag: 'watchlistedItem' + _item.imageURL,
            child:
              FadeInImage.assetNetwork(placeholder: 'assets/images/placeholder.png', image: _item.imageURL),
          ),
          Column(crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text('${_item.name}',
                style: Theme.of(context).textTheme.bodyText2,
              ),
              Text('\t\t' + getAppropriateSubstring('${_item.description}'),
                style: Theme.of(context).textTheme.bodyText1,
              )
            ],),
        ],),
        Column(children: <Widget>[
          Text('${_item.currentPrice}'),
          Text('${_item.currentTrend}')
        ],)
    ],);
  }

  void createItemFromID(String id) {
    communicator.getItemByIdNow(id).then((value) {
      setState(() {
        _item = value;
      });
    });
  }
  
}