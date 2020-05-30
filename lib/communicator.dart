import 'dart:convert';
import 'dart:math';

import 'package:flutter/services.dart';
import 'package:http/http.dart';

import 'Item.dart';

class Communicator {
  
  //url data to prevent repetitive code
  static const String _BASE_URL = "http://services.runescape.com/m=itemdb_oldschool";
  static const String _BASIC_APPEND = "/api/catalogue/detail.json?item=";
  static const String _GRAPH_APPEND = "/api/graph/";

  Communicator();

  //Get random image
  String getRandomImage() {
    //randomize image
    getRandomItemImage();
    
    //return url to image
    return _url;
  }


  //holds url for random image
  String _url = 'http://services.runescape.com/m=itemdb_oldschool/1582802986184_obj_big.gif?id=13190';
  
  //load id to name map
  Future<String> loadAsset() async {
    //for some reason if you just do assets: assets/ this function does not work.
    return await rootBundle.loadString('assets/dict/IDtoItemName.csv');
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
  
  void getRandomItemImage() async {
    Random rand = new Random();
    int randomNum = rand.nextInt(3011); 
    //loads the item to id map
    loadAsset().then((value) {
      //split by lines
      List<String> lines = value.split("\n");
      //call the search by id method, then for the response
      searchItem(lines[randomNum].split(",")[0]).then((res) {
        //convert to a map from the JSON response
        Map<String, dynamic> body = json.decode(res.body);
        //set the item to the item generated from the JSON
        Item item = Item.fromJSON(body);
        _url = item.imageURL;
      });
    });
  }


}