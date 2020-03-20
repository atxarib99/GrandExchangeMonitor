import 'package:charts_flutter/flutter.dart' as charts;
import 'package:flutter/cupertino.dart';

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
