import 'dart:convert';
import 'dart:async' show Future;
import 'package:autocomplete_textfield/autocomplete_textfield.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:http/http.dart';
import 'package:flutter/material.dart';

import 'Item.dart';

class Home extends StatefulWidget {

  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<Home> {
  int _counter = 0;

  String _title = "Search for an item...";
  final String _BASE_URL = "http://services.runescape.com/m=itemdb_oldschool";
  final String _BASIC_APPEND = "/api/catalogue/detail.json?item=";
  Item _item = Item.fromDefault();
  TextEditingController mainSearch = new TextEditingController();
  GlobalKey<AutoCompleteTextFieldState<String>> key = new GlobalKey();
  List<String> suggestions = ['No Suggestions'];

  _MyHomePageState() {
    buildSuggestions();
    searchItem('13190').then((res) => _item = Item.fromJSON(json.decode(res.body)));

  }


  void _incrementCounter() {
    // searchItem("2").then((res) {
    //   Map<String, dynamic> body = json.decode(res.body);
    //   setState(() {
    //     _title = body['item']['name'];
    //     _item = Item.fromJSON(body);
    //   });
    // });
    setState(() {
      // This call to setState tells the Flutter framework that something has
      // changed in this State, which causes it to rerun the build method below
      // so that the display can reflect the updated values. If we changed
      // _counter without calling setState(), then the build method would not be
      // called again, and so nothing would appear to happen.
      _counter++;
    });
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

  void getItemById(String id) {
    searchItem(id).then((res) {
      Map<String, dynamic> body = json.decode(res.body);
      setState(() {
        _title = body['item']['name'];
        _item = Item.fromJSON(body);
      });

    });
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
        title: SimpleAutoCompleteTextField(
          key: key,
          decoration: InputDecoration(
            border: InputBorder.none,
            hintText: 'Enter a search term',
            labelStyle: new TextStyle(
              color: Colors.white //this line isn't doing anything
            ),
          ),
          controller: mainSearch,
          submitOnSuggestionTap: true,
          suggestions: getSuggestions(),
          textSubmitted: (data) => getItemByName(data),
        ),
      ),
      body: Padding(
        padding: EdgeInsets.all(6.0),
        child:
          Center(
            // Center is a layout widget. It takes a single child and positions it
            // in the middle of the parent.
            child: Column(
              // Column is also a layout widget. It takes a list of children and
              // arranges them vertically. By default, it sizes itself to fit its
              // children horizontally, and tries to be as tall as its parent.
              //
              // Invoke "debug painting" (press "p" in the console, choose the
              // "Toggle Debug Paint" action from the Flutter Inspector in Android
              // Studio, or the "Toggle Debug Paint" command in Visual Studio Code)
              // to see the wireframe for each widget.
              //
              // Column has various properties to control how it sizes itself and
              // how it positions its children. Here we use mainAxisAlignment to
              // center the children vertically; the main axis here is the vertical
              // axis because Columns are vertical (the cross axis would be
              // horizontal).
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
                ],)

              ],
            ),
          ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed:  _incrementCounter,
        tooltip: 'Search',
        child: Icon(Icons.search),
      ), // This trailing comma makes auto-formatting nicer for build methods.
    );
  }
}