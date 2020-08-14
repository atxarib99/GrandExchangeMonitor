import 'dart:convert';
import 'dart:math';

import 'package:flutter/services.dart';
import 'package:http/http.dart';
import 'package:charts_flutter/flutter.dart' as charts;

import 'Item.dart';
import 'SimpleTimeSeriesChart.dart';
import 'chartselection.dart';

class Communicator {
  
  //url data to prevent repetitive code
  static const String _BASE_URL = "http://services.runescape.com/m=itemdb_oldschool";
  static const String _BASIC_APPEND = "/api/catalogue/detail.json?item=";
  static const String _GRAPH_APPEND = "/api/graph/";

  Communicator() {
    getRandomImage();
  }

  /************
  * Get item
  ************/
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
  
  Future<Item> getItemByNameNow(String name) async {
    String value = await loadAsset();
    //split by lines
    List<String> lines = value.split("\n");
    //corresponding id
    String id = "";
    //for each line
    lines.forEach((element) {
      //split on commas
      List<String> line = element.split(',');
      //if the name matches
      if(line[1] == name) {
        id = line[0];
      }
    });
    return await getItemByIdNow(id);
  }

  Future<Item> getItemByIdNow(String id) async {
    Response res = await searchItem(id);
    //convert to a map from the JSON response
    try {
      Map<String, dynamic> body = json.decode(res.body);
      //set the item to the item generated from the JSON
      return Item.fromJSON(body);
    } on FormatException {
      new Future.error("Incorrect response from server.");
    }
  }

  Future<List<charts.Series<SimpleDataPoint, num>>> getItemChartNow(String id) async {
    Response res = await searchItemGraph(id);
    //get the JSON map
    Map<String, dynamic> body;
    try {
      body = json.decode(res.body)['daily'];
    } on FormatException {
      return Future.error("Incorrect response from server.");
    }
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

    return [
      new charts.Series<SimpleDataPoint, num>(
        id: 'Prices',
        colorFn: (_, __) => charts.MaterialPalette.blue.shadeDefault,
        domainFn: (SimpleDataPoint prices, _) => prices.domain,
        measureFn: (SimpleDataPoint prices, _) => prices.amount,
        data: data,
      )
    ];
  }


  List<charts.Series<SimpleDataPoint, num>> truncateGraph(List<charts.Series<SimpleDataPoint, num>> seriesList, ChartSelection cs) {
    List<charts.Series<SimpleDataPoint, num>> truncList;
    List<SimpleDataPoint> data = seriesList[0].data;
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

    return [
      new charts.Series<SimpleDataPoint, num>(
        id: 'Prices',
        colorFn: (_, __) => charts.MaterialPalette.blue.shadeDefault,
        domainFn: (SimpleDataPoint prices, _) => prices.domain,
        measureFn: (SimpleDataPoint prices, _) => prices.amount,
        data: truncData,
      )
    ];
  }



  /************
  * Get random image logic
  ************/
  String _backupURL = 'http://services.runescape.com/m=itemdb_oldschool/1582802986184_obj_big.gif?id=13190';
  String _url = 'http://services.runescape.com/m=itemdb_oldschool/1582802986184_obj_big.gif?id=13190';
  
  //Get random image
  String getRandomImage() {
    //randomize image
    getRandomItemImage();
    
    //return url to image
    return _url;
  }

  //load id to name map
  Future<String> loadAsset() async {
    //for some reason if you just do assets: assets/ this function does not work.
    return await rootBundle.loadString('assets/dict/IDtoItemName.csv');
  }
  
  void getRandomItemImage() async {
    Random rand = new Random();
    int randomNum = rand.nextInt(3011); 
    //loads the item to id map
    loadAsset().then((value) {
      //split by lines
      List<String> lines = value.split("\n");
      //call the search by id method, then for the response
      searchItem(lines[randomNum].split(",")[0]).then((res) {
        try {
          //convert to a map from the JSON response
          Map<String, dynamic> body = json.decode(res.body);
          //set the item to the item generated from the JSON
          Item item = Item.fromJSON(body);
          _url = item.imageURL;
        } on FormatException {
          _url = _backupURL;
        }
      });
    });
  }

}