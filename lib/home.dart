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

  final String _BASE_URL = "http://services.runescape.com/m=itemdb_oldschool";
  final String _BASIC_APPEND = "/api/catalogue/detail.json?item=";
  final String _GRAPH_APPEND = "/api/graph/";
  Item _item = Item.fromDefault();

  List<String> suggestions = ['No Suggestions'];
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _typeAheadController = TextEditingController();

  List<charts.Series<SimpleDataPoint, num>> seriesList = _createDefaultGraph();
  charts.StaticNumericTickProviderSpec ticks;

  _MyHomePageState() {
    buildSuggestions();
    searchItem('13190').then((res) => _item = Item.fromJSON(json.decode(res.body)));
  }

  void _search() {
    getItemByName(mainSearch.text);
  }

  Future<Response> searchItem(String search) {
    String finalURL = _BASE_URL + _BASIC_APPEND + search;
    return get(
      finalURL,
      // Send authorization headers to the backend.
      headers: {"Access-Control-Allow-Origin": "*"},
    );
  }

  
  Future<Response> searchItemGraph(String search) {
    String finalURL = _BASE_URL + _GRAPH_APPEND + search + ".json";
    return get(
      finalURL,
      // Send authorization headers to the backend.
      headers: {"Access-Control-Allow-Origin": "*"},
    );
  }

  void getItemById(String id) {
    searchItem(id).then((res) {
      Map<String, dynamic> body = json.decode(res.body);
      setState(() {
        _item = Item.fromJSON(body);
      });
    });
    searchItemGraph(id).then((res) {
      Map<String, dynamic> body = json.decode(res.body)['daily'];

      List<SimpleDataPoint> data = [];

      bool first = true;
      int startingDay = 0;
      int min = 3000000000000;
      int max = 0;
      body.keys.forEach((element) {
        if(first) {
          startingDay = (int.parse(element)/86400000).round();
          first = false;
        }
        data.add(new SimpleDataPoint((int.parse(element)/86400000).round() - startingDay, body[element]));
        if(body[element] < min) {
          min = body[element];
        }
        if(body[element] > max) {
          max = body[element];
        }
      });

      setState(() {
        seriesList = [
          new charts.Series<SimpleDataPoint, num>(
            id: 'Prices',
            colorFn: (_, __) => charts.MaterialPalette.blue.shadeDefault,
            domainFn: (SimpleDataPoint prices, _) => prices.domain,
            measureFn: (SimpleDataPoint prices, _) => prices.amount,
            data: data,
          )
        ];
        ticks = buildMeasureAxisTicks(min, max);
      });
    });
  }

  static List<charts.Series<SimpleDataPoint, num>> _createDefaultGraph() {
    final random = new Random();

    final data = [
      new SimpleDataPoint(0, random.nextInt(100)),
      new SimpleDataPoint(1, random.nextInt(100)),
      new SimpleDataPoint(2, random.nextInt(100)),
      new SimpleDataPoint(3, random.nextInt(100)),
    ];

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

  void getItemByName(String name) {
      loadAsset().then((value) {
        List<String> lines = value.split("\n");
        lines.forEach((element) {
          List<String> line = element.split(',');
          if(line[1] == name) {
            getItemById(line[0]);
          }
        });
      });
  }

  Future<String> loadAsset() async {
    //for some reason if you just do assets: assets/ this function does not work.
    return await rootBundle.loadString('assets/dict/IDtoItemName.csv');
  }

  String getTrendImageAsset() {
    if(_item.currentTrend == 'negative') {
      return 'assets/images/downtrend.png';
    } else {
      return 'assets/images/uptrend.png';
    }
  }

  List<String> getSuggestions() {
    if(suggestions == ['No Suggestions']) {
      return buildSuggestions();
    } else {
      return suggestions;
    }
  }

  List<String> getSuggestionsWithParam(String search) {
    if(suggestions == ['No Suggestions']) {
      return suggestions;
    } else {
      List<String> matchingSuggestions = [];
      suggestions.forEach((element) {
        if(element.contains(search)) {
          matchingSuggestions.add(element);
        }
      });
      return matchingSuggestions;
    }
  }

  List<String> buildSuggestions() {
    loadAsset().then((value) {
      List<String> lines = value.split("\n");
      lines.forEach((element) {
        List<String> line = element.split(',');
        suggestions.add(line[1]);
      });
      return suggestions;
    });
    return suggestions;
  }

  charts.StaticNumericTickProviderSpec buildMeasureAxisTicks(int mini, int maxi) {
    final int countOfTicks = min(10, maxi - mini);

    List<charts.TickSpec<num>> ticks = [];
    for(int i = 0; i < countOfTicks; i++) {
      ticks.add(new charts.TickSpec((maxi - mini) / countOfTicks * i + mini));
    }

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