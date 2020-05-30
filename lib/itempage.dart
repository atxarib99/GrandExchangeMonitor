import 'dart:convert';
import 'dart:async' show Future;
import 'dart:math';
import 'package:GrandExchangeMonitor/PageInterface.dart';
import 'package:GrandExchangeMonitor/SimpleTimeSeriesChart.dart';
import 'package:GrandExchangeMonitor/home.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter_typeahead/flutter_typeahead.dart';
import 'package:http/http.dart';
import 'package:flutter/material.dart';
import 'package:charts_flutter/flutter.dart' as charts;
import 'package:shared_preferences/shared_preferences.dart';
import 'Item.dart';

class ItemPage extends StatefulWidget {
  final String id;
  ItemPage(this.id);

  @override
  _ItemPageState createState() => _ItemPageState(id);
}

class _ItemPageState extends State<ItemPage> {

  //url data to prevent repetitive code
  final String _BASE_URL = "http://services.runescape.com/m=itemdb_oldschool";
  final String _BASIC_APPEND = "/api/catalogue/detail.json?item=";
  final String _GRAPH_APPEND = "/api/graph/";

  //holds the chart config of how many element to show
  ChartSelection cs = ChartSelection.thirty;

  Item _item = Item.fromDefault();
  //the series list. Essentially the data
  List<charts.Series<SimpleDataPoint, num>> seriesList = _createDefaultGraph();

  String _id;
  _ItemPageState(this._id) {
    getItemById(_id);
  }

  // creates the default graph
  static List<charts.Series<SimpleDataPoint, num>> _createDefaultGraph() {
    //random generator
    final random = new Random();
    //holds 4 random values
    final data = [
      new SimpleDataPoint(0, random.nextInt(100)),
      new SimpleDataPoint(1, random.nextInt(100)),
      new SimpleDataPoint(2, random.nextInt(100)),
      new SimpleDataPoint(3, random.nextInt(100)),
    ];

    //create random value series
    return [
      new charts.Series<SimpleDataPoint, int>(
        id: 'Sales',
        colorFn: (_, __) => charts.MaterialPalette.blue.shadeDefault,
        domainFn: (SimpleDataPoint sales, _) => sales.domain,
        measureFn: (SimpleDataPoint sales, _) => sales.amount,
        data: data,
      )
    ];
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
  //get the graph for an item by id
  Future<Response> searchItemGraph(String search) {
    //construct url
    String finalURL = _BASE_URL + _GRAPH_APPEND + search + ".json";
    //return the Response from the server
    return get(
      finalURL,
      // Send authorization headers to the backend.
      headers: {"Access-Control-Allow-Origin": "*"},
    );
  }

  //get an item by id
  void getItemById(String id) {
    //call the search by id method, then for the response
    searchItem(id).then((res) {
      //convert to a map from the JSON response
      Map<String, dynamic> body = json.decode(res.body);
      //set the item to the item generated from the JSON
      setState(() {
      _item = Item.fromJSON(body);
      });
    });
    //search for the graph based on the item we just got
    searchItemGraph(id).then((res) {
      //get the JSON map
      Map<String, dynamic> body = json.decode(res.body)['daily'];
      //the list that will hold all the datapoints
      List<SimpleDataPoint> data = [];
      //holds if this is the first itme
      bool first = true;
      //holds the starting epoch
      int startingDay = 0;
      //starting minimum value is larger than Int.maxvalue for java
      int min = 3000000000000;
      //max is 0, negative values is impossibe
      int max = 0;
      //for each value from the JSON response
      body.keys.forEach((element) {
        //if its the first
        if(first) {
          //set the starting day
          startingDay = (int.parse(element)/86400000).round();
          first = false;
        }
        // create a new data point for the current point
        data.add(new SimpleDataPoint((int.parse(element)/86400000).round() - startingDay, body[element]));
        //check if its the minimum value
        if(body[element] < min) {
          min = body[element];
        }
        //check if its the maximum value
        if(body[element] > max) {
          max = body[element];
        }
      });
      //Truncated data to day
      List<SimpleDataPoint> truncData = [];
      //depending on how the chart should be viewed, truncate the data accordingly
      if(cs == ChartSelection.thirty) {
        //holds if we are managing the first item
        bool first = true;
        //holds the starting day value
        int startingDay = 0;
        //for 30 elements
        for(int i = 0; i < 30; i++) {
          //if we are managing the first element
          if(first) {
            //set the starting dat
            startingDay = data[data.length - (i + 1)].domain;
            //done handling the first element
            first = false;
          }
          //add a new instance of this item to the truncated list
          truncData.add(new SimpleDataPoint(data[data.length - (i + 1)].domain - startingDay + 30, data[data.length - (i + 1)].amount));
        }
      }
      //logic follows as above, except for 60 elements
      else if (cs == ChartSelection.sixty) {
        bool first = true;
        int startingDay = 0;
        for(int i = 0; i < 60; i++) {
          if(first) {
            startingDay = data[data.length - (i + 1)].domain;
            first = false;
          }
          truncData.add(new SimpleDataPoint(data[data.length - (i + 1)].domain - startingDay + 60, data[data.length - (i + 1)].amount));
        }
      }
      //logic follows as above except for 90 elements
      else if(cs == ChartSelection.ninety) {
        bool first = true;
        int startingDay = 0;
        for(int i = 0; i < 90; i++) {
          if(first) {
            startingDay = data[data.length - (i + 1)].domain;
            first = false;
          }
          truncData.add(new SimpleDataPoint(data[data.length - (i + 1)].domain - startingDay + 90, data[data.length - (i + 1)].amount));
        }
      }
      //force UI update
      //create ticks based on data
      // ticks = buildMeasureAxisTicks(min, max);
      //set the series to be the series of the series we created, set the domain and range

      setState(() {
        seriesList = [
          new charts.Series<SimpleDataPoint, num>(
            id: 'Prices',
            colorFn: (_, __) => charts.MaterialPalette.blue.shadeDefault,
            domainFn: (SimpleDataPoint prices, _) => prices.domain,
            measureFn: (SimpleDataPoint prices, _) => prices.amount,
            data: truncData,
          )
        ];
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: getAppBar(context),
      body: getBody(context),
    );
  }

    AppBar getAppBar(BuildContext context) {
    return AppBar(
      // Here we take the value from the MyHomePage object that was created by
      // the App.build method, and use it to set our appbar title.
      title: Text('${_item.name}'),
    );
  }

  Padding getBody(BuildContext context) {
    return Padding(
      //add a padding so things aren't riding the wall
      padding: EdgeInsets.all(6.0),
      child:
      //center everything
        Center(
          child: Column(
            children: <Widget>[
              //holds the image and image desc
              Row(children: <Widget>[
                //image
                Hero(
                  tag: 'watchlistedItem' + _item.imageURL,
                  child: Image.network(_item.imageURL, height: 125, width: 125,),
                ),
                //image desc
                Expanded(            
                  child: Text(
                    '${_item.description}',
                    style: Theme.of(context).textTheme.headline6,
                    overflow: TextOverflow.ellipsis,
                    maxLines: 3
                  ),
                ),
              ],),
              //holds the current price, and trend
              Row( mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: <Widget>[
                Column(children: <Widget>[
                  //item price
                  Text(
                    ' ${_item.currentPrice}',
                    style: Theme.of(context).textTheme.headline5.copyWith(fontWeight: FontWeight.bold),
                  ),
                  //item trend
                  Text(
                    ' current'
                  )
                ],),
                Column(children: <Widget>[
                  Text(
                    '${_item.thirtyDayChange}',
                    style: Theme.of(context).textTheme.headline5,
                  ),
                  //item trend
                  Text(
                    '30 day'
                  )
                ],),
                Column(children: <Widget>[
                  Text(
                    '${_item.ninetyDayChange}',
                    style: Theme.of(context).textTheme.headline5,
                  ),
                  //item trend
                  Text(
                    '90 day'
                  )
                ],),
                Column(children: <Widget>[
                  Text(
                    '${_item.oneEightyDayChange}',
                    style: Theme.of(context).textTheme.headline5,
                  ),
                  //item trend
                  Text(
                    '180 day'
                  )
                ],)
              ],),
              //holds the buttons for how to view chart
              Row( mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: <Widget>[
                  //30 day button
                  RaisedButton(
                    child: Text('30 day'),
                    onPressed: () {
                      //on pressed switch to 30 day chart
                      if(cs != ChartSelection.thirty) {
                        cs = ChartSelection.thirty;
                        getItemById(_item.id.toString());
                      }
                    },
                  ),
                  //60 day chart
                  RaisedButton(
                    child: Text('60 day'),
                    onPressed: () {
                      //on pressed switch to 60 day chart
                      if(cs != ChartSelection.sixty) {
                        cs = ChartSelection.sixty;
                        getItemById(_item.id.toString());
                      }
                    },
                  ),
                  //90 day chart
                  RaisedButton(
                    child: Text('90 day'),
                    onPressed: () {
                      //on pressed switch to 90 day chart
                      if(cs != ChartSelection.ninety) {
                        cs = ChartSelection.ninety;
                        getItemById(_item.id.toString());
                      }
                    },
                  ),
              ],),
              //the chart itself
              Expanded(child: SimpleTimeSeriesChart(seriesList, animate: true)),
            ],
          ),
        ),
    );
  }
}

//an enumeration of the types of charts we can show
//TODO: perhaps an all chart if we have more than 90 days
enum ChartSelection {
  thirty,
  sixty,
  ninety
}