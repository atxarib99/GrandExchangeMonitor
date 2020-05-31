import 'dart:async' show Future;
import 'dart:math';
import 'package:GrandExchangeMonitor/SimpleTimeSeriesChart.dart';
import 'package:GrandExchangeMonitor/communicator.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter/material.dart';
import 'package:charts_flutter/flutter.dart' as charts;
import 'Item.dart';
import 'chartselection.dart';

class ItemPage extends StatefulWidget {
  final String id;
  ItemPage(this.id);

  @override
  _ItemPageState createState() => _ItemPageState(id);
}

class _ItemPageState extends State<ItemPage> {
  TextEditingController mainSearch = new TextEditingController();

  //gets default item if it couldn't be loaded
  Item _item = Item.fromDefault();
  bool isWatchList = false;

  //gets suggestions
  //TODO: perhaps we should remove the No Suggestions so that it doesn't show up as a suggestion
  List<String> suggestions = ['No Suggestions'];

  //the series list. Essentially the data
  List<charts.Series<SimpleDataPoint, num>> seriesList = _createDefaultGraph();
  //holds the ticks for the range
  charts.StaticNumericTickProviderSpec ticks;

  //holds the chart config of how many element to show
  ChartSelection cs = ChartSelection.thirty;

  //holds the communicator to the server
  Communicator communicator = new Communicator();

  //default constructor
  _ItemPageState(String id) {
    //builds the suggestions to prevent null pointers
    buildSuggestions();
    communicator.getItemByIdNow(id).then((value) {
      setState(() {
        _item = value;
        updateChart(_item.id.toString());
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

  void getItemById(String id) {
    communicator.getItemByIdNow(id).then((value) {
      setState(() {
        _item = value;
      });
    });

    communicator.getItemChartNow(id).then((value) {
      // List<charts.Series<SimpleDataPoint, num>>
      setState(() {
        seriesList = communicator.truncateGraph(value, cs);
      });
    });
  }

  void updateChart(String id) {
    communicator.getItemChartNow(id).then((value) {
      // List<charts.Series<SimpleDataPoint, num>>
      setState(() {
        seriesList = communicator.truncateGraph(value, cs);
      });
    });
  }


  //load id to name map
  Future<String> loadAsset() async {
    //for some reason if you just do assets: assets/ this function does not work.
    return await rootBundle.loadString('assets/dict/IDtoItemName.csv');
  }

  //gets the autocorrect suggestions
  List<String> getSuggestions() {
    //if suggestions is empty
    if (suggestions == ['No Suggestions']) {
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
    if (suggestions == ['No Suggestions']) {
      //return blank
      return suggestions;
      //else create new list
    } else {
      List<String> matchingSuggestions = [];
      //for each suggestion
      suggestions.forEach((element) {
        //if the element has some substring that matches the search
        if (element.contains(search)) {
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
  charts.StaticNumericTickProviderSpec buildMeasureAxisTicks(
      int mini, int maxi) {
    //get number of ticks needed
    final int countOfTicks = min(10, maxi - mini);

    //holds tick list
    List<charts.TickSpec<num>> ticks = [];
    //for each tick we should have
    for (int i = 0; i < countOfTicks; i++) {
      //create tick
      ticks.add(new charts.TickSpec((maxi - mini) / countOfTicks * i + mini,
          label: "", style: new charts.TextStyleSpec()));
    }

    //return ticks
    return new charts.StaticNumericTickProviderSpec(
      ticks,
    );
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