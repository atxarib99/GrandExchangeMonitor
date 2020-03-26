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

class SearchPage implements PageInterface {

  TextEditingController mainSearch = new TextEditingController();
  //url data to prevent repetitive code
  final String _BASE_URL = "http://services.runescape.com/m=itemdb_oldschool";
  final String _BASIC_APPEND = "/api/catalogue/detail.json?item=";
  final String _GRAPH_APPEND = "/api/graph/";

  //gets default item if it couldn't be loaded
  Item _item = Item.fromDefault();
  bool isWatchList = false;

  //gets suggestions
  //TODO: perhaps we should remove the No Suggestions so that it doesn't show up as a suggestion
  List<String> suggestions = ['No Suggestions'];
  //the form key for the autocomplete
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  //the controller for the textedit for the autocomplete
  final TextEditingController _typeAheadController = TextEditingController();

  //the series list. Essentially the data
  List<charts.Series<SimpleDataPoint, num>> seriesList = _createDefaultGraph();
  //holds the ticks for the range
  charts.StaticNumericTickProviderSpec ticks;

  //holds the chart config of how many element to show
  ChartSelection cs = ChartSelection.thirty;

  //parent
  HomePageState parent;

  //default constructor
  SearchPage(this.parent) {
    //builds the suggestions to prevent null pointers
    buildSuggestions();
    //attempts to search for the old school bond
    //TODO: fix search on open. Always shows default item
    searchItem('13190').then((res) => _item = Item.fromJSON(json.decode(res.body)));
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
      _item = Item.fromJSON(body);
      isWatchlisted();
      parent.refresh();
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
      seriesList = [
        new charts.Series<SimpleDataPoint, num>(
          id: 'Prices',
          colorFn: (_, __) => charts.MaterialPalette.blue.shadeDefault,
          domainFn: (SimpleDataPoint prices, _) => prices.domain,
          measureFn: (SimpleDataPoint prices, _) => prices.amount,
          data: truncData,
        )
      ];
      parent.refresh();
      });
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

  //gets an item by its name
  void getItemByName(String name) {
      //loads the item to id map
      loadAsset().then((value) {
        //split by lines
        List<String> lines = value.split("\n");
        //for each line
        lines.forEach((element) {
          //split on commas
          List<String> line = element.split(',');
          //if the name matches
          if(line[1] == name) {
            //search by matching id
            getItemById(line[0]);
          }
        });
      });
  }

  //load id to name map
  Future<String> loadAsset() async {
    //for some reason if you just do assets: assets/ this function does not work.
    return await rootBundle.loadString('assets/dict/IDtoItemName.csv');
  }

  //get the trend asset image
  String getTrendImageAsset() {
    if(_item.currentTrend == 'negative') {
      return 'assets/images/downtrend.png';
    } else {
      return 'assets/images/uptrend.png';
    }
  }

  //gets the autocorrect suggestions
  List<String> getSuggestions() {
    //if suggestions is empty
    if(suggestions == ['No Suggestions']) {
      //build suggestions
      return buildSuggestions();
    //else return prebuilt suggestions
    } else {
      return suggestions;
    }
  }

  //get suggestions by current search string
  List<String> getSuggestionsWithParam(String search) {
    //if current suggestion is empty
    if(suggestions == ['No Suggestions']) {
      //return blank
      return suggestions;
      //else create new list
    } else {
      List<String> matchingSuggestions = [];
      //for each suggestion
      suggestions.forEach((element) {
        //if the element has some substring that matches the search
        if(element.contains(search)) {
          //add that to the matching elements
          matchingSuggestions.add(element);
        }
      });
      //return the list of matching elements
      return matchingSuggestions;
    }
  }

  //builds a suggestion list
  List<String> buildSuggestions() {
    //for each element of the id to name map
    loadAsset().then((value) {
      //split by line
      List<String> lines = value.split("\n");
      //for each line
      lines.forEach((element) {
        //split on commas
        List<String> line = element.split(',');
        //get bane
        suggestions.add(line[1]);
      });
      //return names
      return suggestions;
    });
    //return names
    return suggestions;
  }

  //get ticks based on minimum and maximum of graph
  charts.StaticNumericTickProviderSpec buildMeasureAxisTicks(int mini, int maxi) {
    //get number of ticks needed
    final int countOfTicks = min(10, maxi - mini);

    //holds tick list
    List<charts.TickSpec<num>> ticks = [];
    //for each tick we should have
    for(int i = 0; i < countOfTicks; i++) {
      //create tick
      ticks.add(new charts.TickSpec((maxi-mini) / countOfTicks * i + mini, label: "", style: new charts.TextStyleSpec()));
    }

    //return ticks
    return new charts.StaticNumericTickProviderSpec(
      ticks,
    );
  }

  //edit items watch list status
  void _editWatchListStatus() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    List<String> watchList = (prefs.getStringList('watchlist'));
    if(watchList == null) {
      watchList = new List<String>();
    }
    if(watchList.contains(_item.id.toString())) {
      watchList.remove(_item.id.toString());
    } else {
      watchList.add(_item.id.toString());
    }
    prefs.setStringList('watchlist', watchList);
    isWatchlisted();
  }

  void isWatchlisted() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    List<String> watchList = (prefs.getStringList('watchlist'));
    if(watchList == null) {
      watchList = new List<String>();
    }
    if(watchList.contains(_item.id.toString())) {
      isWatchList = true;
    } else {
      isWatchList = false;
    }
    parent.refresh();
  }

  Icon _getIcon() {
    if(isWatchList) {
      return Icon(Icons.star);
    }
    else {
      return Icon(Icons.star_border);
    }
  }

  AppBar getAppBar(BuildContext context) {
    return AppBar(
      // Here we take the value from the MyHomePage object that was created by
      // the App.build method, and use it to set our appbar title.
      title: Form(
        key: this._formKey,
        child: Column(
          children: <Widget>[
            //searchable auto complete field
            TypeAheadFormField(
              textFieldConfiguration: TextFieldConfiguration(
                controller: this._typeAheadController,
                decoration: InputDecoration(
                  hintText: 'Search for an item...',
                  hintStyle: TextStyle(color: Colors.white),
                ),
                style: TextStyle(color: Colors.white),
              ),
              //how to get suggestions
              suggestionsCallback: (pattern) {
                if(pattern != '') {
                  return getSuggestionsWithParam(pattern);
                }
                return [];
              },
              //how should the suggestion items look
              itemBuilder: (context, suggestion) {
                return ListTile(
                  title: Text(suggestion),
                );
              },
              //how should the menu look
              transitionBuilder: (context, suggestionsBox, controller) {
                return suggestionsBox;
              },
              //what happens when a suggestion is pressed
              onSuggestionSelected: (suggestion) {
                //on suggestion pressed, update the view with new textfield
                  this._typeAheadController.text = suggestion;
                  parent.refresh();
                //get the item based on the suggestions name
                getItemByName(suggestion);
              },
            ),
          ],
        ),
      ),
      actions: <Widget>[
        Padding(
          padding: EdgeInsets.only(right: 10),
          child:         
            GestureDetector(
              onTap : () {_editWatchListStatus();},
              child : _getIcon()
            )
        ),
      ],
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
                Image.network(_item.imageURL, height: 125, width: 125,),
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

  FloatingActionButton getFAB(BuildContext context) {
    return FloatingActionButton(
        onPressed: () {getItemById(_item.id.toString());},
        tooltip: 'Search',
        child: Icon(Icons.search),
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