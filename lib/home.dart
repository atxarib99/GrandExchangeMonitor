import 'dart:convert';
import 'dart:async' show Future;
import 'dart:math';
import 'package:GrandExchangeMonitor/SimpleTimeSeriesChart.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter_typeahead/flutter_typeahead.dart';
import 'package:http/http.dart';
import 'package:flutter/material.dart';
import 'package:charts_flutter/flutter.dart' as charts;


import 'Item.dart';

class Home extends StatefulWidget {

  @override
  _MyHomePageState createState() => _MyHomePageState();
}

TextEditingController mainSearch = new TextEditingController();

class _MyHomePageState extends State<Home> {

  //url data to prevent repetitive code
  final String _BASE_URL = "http://services.runescape.com/m=itemdb_oldschool";
  final String _BASIC_APPEND = "/api/catalogue/detail.json?item=";
  final String _GRAPH_APPEND = "/api/graph/";

  //gets default item if it couldn't be loaded
  Item _item = Item.fromDefault();

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

  //default constructor
  _MyHomePageState() {
    //builds the suggestions to prevent null pointers
    buildSuggestions();
    //attempts to search for the old school bond
    searchItem('13190').then((res) => _item = Item.fromJSON(json.decode(res.body)));
  }

  //private method that searches based on the search field
  void _search() {
    getItemByName(mainSearch.text);
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
      //force UI update
      setState(() {
        //set the series to be the series of the series we created, set the domain and range
        seriesList = [
          new charts.Series<SimpleDataPoint, num>(
            id: 'Prices',
            colorFn: (_, __) => charts.MaterialPalette.blue.shadeDefault,
            domainFn: (SimpleDataPoint prices, _) => prices.domain,
            measureFn: (SimpleDataPoint prices, _) => prices.amount,
            data: data,
          )
        ];
        //create ticks based on data
        ticks = buildMeasureAxisTicks(min, max);
      });
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
      ticks.add(new charts.TickSpec((maxi - mini) / countOfTicks * i + mini));
    }

    //return ticks
    return new charts.StaticNumericTickProviderSpec(
      ticks,
    );
  }

  @override
  Widget build(BuildContext context) {
    // This method is rerun every time setState is called, for instance as done
    // by the _incrementCounter method above.
    //
    // The Flutter framework has been optimized to make rerunning build methods
    // fast, so that you can just rebuild anything that needs updating rather
    // than having to individually change instances of widgets.
    return Scaffold(
      appBar: AppBar(
        // Here we take the value from the MyHomePage object that was created by
        // the App.build method, and use it to set our appbar title.
        title: Form(
          key: this._formKey,
          child: Column(
            children: <Widget>[
              TypeAheadFormField(
                textFieldConfiguration: TextFieldConfiguration(
                  controller: this._typeAheadController,
                  decoration: InputDecoration(
                    hintText: 'Search for an item...'
                  )
                ),
                suggestionsCallback: (pattern) {
                  if(pattern != '') {
                    return getSuggestionsWithParam(pattern);
                  }
                  return [];
                },
                itemBuilder: (context, suggestion) {
                  return ListTile(
                    title: Text(suggestion),
                  );
                },
                transitionBuilder: (context, suggestionsBox, controller) {
                  return suggestionsBox;
                },
                onSuggestionSelected: (suggestion) {
                  setState(() {
                    this._typeAheadController.text = suggestion;
                  });
                  getItemByName(suggestion);
                },
              ),
            ],
          ),
        ),
      ),
      body: Padding(
        padding: EdgeInsets.all(6.0),
        child:
          Center(
            child: Column(
              children: <Widget>[
                Row(children: <Widget>[
                  Image.network(_item.imageURL, height: 125, width: 125,),
                  Expanded(            
                    child: Text(
                      '${_item.description}',
                      style: Theme.of(context).textTheme.headline6,
                      overflow: TextOverflow.ellipsis,
                      maxLines: 3
                    ),
                  ),
                ],),
                Row( mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: <Widget>[
                  Column(children: <Widget>[
                    Text(
                      ' ${_item.currentPrice}',
                      style: Theme.of(context).textTheme.headline5,
                    ),
                    Text(
                      ' ${_item.currentTrend}'
                    )
                  ],),
                  Image.asset(getTrendImageAsset()),
                ],),
                Expanded(child: SimpleTimeSeriesChart(seriesList, animate: true, ticks: ticks)),
                // Expanded(child: SimpleTimeSeriesChart.withSampleData()),
              ],
            ),
          ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed:  _search,
        tooltip: 'Search',
        child: Icon(Icons.search),
      ), // This trailing comma makes auto-formatting nicer for build methods.
    );
  }
}