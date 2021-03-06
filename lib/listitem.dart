import 'package:GrandExchangeMonitor/Item.dart';
import 'package:GrandExchangeMonitor/communicator.dart';
import 'package:flutter/material.dart';
import 'package:charts_flutter/flutter.dart' as charts;
import 'SimpleTimeSeriesChart.dart';

class ListItem extends StatefulWidget {
  final String id;

  _ListItemState state;

  ListItem(this.id) {
    state = _ListItemState(id);
  }

  Item getItem() => state.getItem();
  List<charts.Series<SimpleDataPoint, num>> getChart() => state.getChart();
  bool isLoading() => state.isLoading();

  @override
  _ListItemState createState() => state;
}

class _ListItemState extends State<ListItem> {
  //the item to be shown
  Item _item = Item.fromDefault();

  //the accompanying seriesList
  List<charts.Series<SimpleDataPoint, num>> _seriesList;

  //Communicator for server comms
  Communicator communicator = new Communicator();

  //lets us know if we are still loading data
  int loading = 2;

  //constructor that requires a provided string
  _ListItemState(String id) {
    createItemFromID(id);
    communicator.getItemChartNow(id).then((value) {
      _seriesList = value;
      loading -= 1;
    });
  }

  String getAppropriateSubstring(String str) {
    if (str.length < 30) {
      return str;
    } else {
      return str.substring(0, 30) + '...';
    }
  }

  //return this objects item
  Item getItem() => _item;

  List<charts.Series<SimpleDataPoint, num>> getChart() => _seriesList;

  bool isLoading() {
    if (loading > 0) {
      return true;
    }

    return false;
  }

  @override
  Widget build(BuildContext context) {
    if (_item == null || _item.defaultCreation) {
      // return Row(
      //   mainAxisAlignment: MainAxisAlignment.spaceBetween,
      //   children: [
      //     // ConstrainedBox(
      //     //   constraints: new BoxConstraints(
      //     //     minHeight: 120,
      //     //     maxHeight: 120,
      //     //     minWidth: 120,
      //     //     maxWidth: 120,
      //     //   ),
      //     //   child: CircularProgressIndicator(
      //     //     valueColor:
      //     //         AlwaysStoppedAnimation<Color>(Theme.of(context).primaryColor),
      //     //   ),
      //     // ),
      //     LinearProgressIndicator(
      //       valueColor:
      //           AlwaysStoppedAnimation<Color>(Theme.of(context).primaryColor),
      //     )
      //   ],
      // );
      // return LinearProgressIndicator(
      //   valueColor:
      //       AlwaysStoppedAnimation<Color>(Theme.of(context).primaryColor),
      // );

      return Padding(
          padding: EdgeInsets.all(16),
          child: LinearProgressIndicator(
            valueColor:
                AlwaysStoppedAnimation<Color>(Theme.of(context).primaryColor),
          ));
    }

    //the structure for this item as a listview item.
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: <Widget>[
        Row(
          children: <Widget>[
            Hero(
              tag: 'watchlistedItem' + _item.imageURL,
              child: FadeInImage.assetNetwork(
                  placeholder: 'assets/images/placeholder.png',
                  image: _item.imageURL),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  '${_item.name}',
                  style: Theme.of(context).textTheme.bodyText2,
                ),
                Text(
                  '\t\t' + getAppropriateSubstring('${_item.description}'),
                  style: Theme.of(context).textTheme.bodyText1,
                )
              ],
            ),
          ],
        ),
        Column(
          children: <Widget>[
            Text('${_item.currentPrice}'),
            Text('${_item.currentTrend}')
          ],
        )
      ],
    );
  }

  void createItemFromID(String id) {
    communicator.getItemByIdNow(id).then((value) {
      setState(() {
        _item = value;
        loading -= 1;
      });
    });
  }
}
