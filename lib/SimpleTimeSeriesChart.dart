import 'dart:convert';
import 'dart:math';

import 'package:charts_flutter/flutter.dart' as charts;
import 'package:flutter/cupertino.dart';
import 'package:http/http.dart';

final String _BASE_URL = "http://services.runescape.com/m=itemdb_oldschool";
final String _BASIC_APPEND = "/api/catalogue/detail.json?item=";
final String _GRAPH_APPEND = "/api/graph/";

class SimpleTimeSeriesChart extends StatelessWidget {
  final List<charts.Series> seriesList;
  final bool animate;
  final charts.StaticNumericTickProviderSpec ticks;

  SimpleTimeSeriesChart(this.seriesList, {this.animate, this.ticks});

  factory SimpleTimeSeriesChart.forItem(String id) {
    return new SimpleTimeSeriesChart(
      _createData(id),
      // Disable animations for image tests.
      animate: false,
    );
  }

  factory SimpleTimeSeriesChart.withID(String id) {
    return new SimpleTimeSeriesChart(_createDataFromID(id));
  }

  @override
  Widget build(BuildContext context) {
    return new charts.LineChart(seriesList, animate: animate, primaryMeasureAxis: charts.NumericAxisSpec(tickProviderSpec: ticks));
  }

  static List<charts.Series<SimpleDataPoint, num>> _createDataFromID(String id) {
    //get url
    //get data from JSON
    searchItem(id).then((res) {

      Map<String, dynamic> body = json.decode(res.body)['daily'];

      final data = [
        new SimpleDataPoint((int.parse(body.keys.first)/10000000).round(), 25392),
        new SimpleDataPoint((int.parse(body.keys.first)/10000000).round() + 5, 26234),
        new SimpleDataPoint((int.parse(body.keys.first)/10000000).round() + 10, 27321),
        new SimpleDataPoint((int.parse(body.keys.first)/10000000).round() + 15, 28918), 
      ];

      // body.keys.forEach((element) {
      //   if(data.length < 30) {
      //     data.add(new SimpleDataPoint((int.parse(element)/10000000).round(), 5));
      //   }
      // });

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
  
  static Future<Response> searchItem(String search) {
    String finalURL = _BASE_URL + _GRAPH_APPEND + search + ".json";
    return get(
      finalURL,
      // Send authorization headers to the backend.
      headers: {"Access-Control-Allow-Origin": "*"},
    );
  }


  /// Create random data.
  static List<charts.Series<SimpleDataPoint, num>> _createData(String id) {

    if(id == null || id == '') {
      print('had to do random');
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
    else {
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

class SimpleDataPoint {
  final int domain;
  final int amount;
  SimpleDataPoint(this.domain, this.amount);
}
