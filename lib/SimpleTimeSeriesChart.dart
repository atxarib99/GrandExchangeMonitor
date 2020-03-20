import 'dart:convert';
import 'dart:math';

import 'package:charts_flutter/flutter.dart' as charts;
import 'package:flutter/cupertino.dart';
import 'package:http/http.dart';

//strings for url to prevent repetitive code
final String _BASE_URL = "http://services.runescape.com/m=itemdb_oldschool";
final String _BASIC_APPEND = "/api/catalogue/detail.json?item=";
final String _GRAPH_APPEND = "/api/graph/";

//the class for time series chart
class SimpleTimeSeriesChart extends StatelessWidget {
  //holds the data
  final List<charts.Series> seriesList;
  //holds if we should animate
  final bool animate;
  //holds the ticks
  // final charts.StaticNumericTickProviderSpec ticks;

  //default constructor
  SimpleTimeSeriesChart(this.seriesList, {this.animate});

  //creates a chart based on item name
  factory SimpleTimeSeriesChart.forItem(String id) {
    return new SimpleTimeSeriesChart(
      _createData(id),
      // Disable animations for image tests.
      animate: false,
    );
  }

  //creates a chart based on id
  factory SimpleTimeSeriesChart.withID(String id) {
    return new SimpleTimeSeriesChart(_createDataFromID(id));
  }

  //creates a widget
  @override
  Widget build(BuildContext context) 
  {
    //build the layout based on a constraint
    return LayoutBuilder(
      builder: (context, constraint) {
        //if the box is too small 
        if (constraint.maxHeight < 100.0) {
          // don't build
          return Container();
        } else {
          // build the chart
          return new charts.LineChart(seriesList, animate: animate);
        }
      },
    );
  }

  //creates a series of data from id
  //as far as im aware this method is not used and should be deprecated
  //@deprecated
  static List<charts.Series<SimpleDataPoint, num>> _createDataFromID(String id) {
    //get url
    //get data from JSON
    searchItem(id).then((res) {

      //parse json
      Map<String, dynamic> body = json.decode(res.body)['daily'];

      //create data
      final data = [
        new SimpleDataPoint((int.parse(body.keys.first)/10000000).round(), 25392),
        new SimpleDataPoint((int.parse(body.keys.first)/10000000).round() + 5, 26234),
        new SimpleDataPoint((int.parse(body.keys.first)/10000000).round() + 10, 27321),
        new SimpleDataPoint((int.parse(body.keys.first)/10000000).round() + 15, 28918), 
      ];

      //return a 5 element series from the data we created
      return [
        new charts.Series<SimpleDataPoint, int>(
          id: 'Prices',
          colorFn: (_, __) => charts.MaterialPalette.blue.shadeDefault,
          domainFn: (SimpleDataPoint prices, _) => prices.domain,
          measureFn: (SimpleDataPoint prices, _) => prices.amount,
          data: data,
        )
      ];
    });
  }
  
  //search for an item based on id
  static Future<Response> searchItem(String search) {
    //construct url
    String finalURL = _BASE_URL + _GRAPH_APPEND + search + ".json";
    //return response
    return get(
      finalURL,
      // Send authorization headers to the backend.
      headers: {"Access-Control-Allow-Origin": "*"},
    );
  }


  /// Create random data.
  static List<charts.Series<SimpleDataPoint, num>> _createData(String id) {

    //if id doesn't exist or its null
    if(id == null || id == '') {
      //log that we were forced to do this
      print('had to do random');
      //obj to generate randoms
      final random = new Random();

      //create random data
      final data = [
        new SimpleDataPoint(0, random.nextInt(100)),
        new SimpleDataPoint(1, random.nextInt(100)),
        new SimpleDataPoint(2, random.nextInt(100)),
        new SimpleDataPoint(3, random.nextInt(100)),
      ];

    //return single item list of random data
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
    else {
      //if id was give create data from id
      return _createDataFromID(id);
    }
  }

}
/// Sample linear data type.
class LinearSales {
  final int year;
  final int sales;

  LinearSales(this.year, this.sales);
}

/// Simple data point same as linear data but refactored to make more sense.
class SimpleDataPoint {
  final int domain;
  final int amount;
  SimpleDataPoint(this.domain, this.amount);
}
