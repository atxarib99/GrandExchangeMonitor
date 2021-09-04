import 'dart:async' show Future;
import 'dart:math';
import 'package:GrandExchangeMonitor/SimpleTimeSeriesChart.dart';
import 'package:GrandExchangeMonitor/communicator.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter/material.dart';
import 'package:charts_flutter/flutter.dart' as charts;
import 'Item.dart';

class ItemPage extends StatefulWidget {
  final Item item;
  final List<charts.Series<SimpleDataPoint, num>> seriesList;
  ItemPage(this.item, this.seriesList);

  @override
  _ItemPageState createState() => _ItemPageState(item, seriesList);
}

class _ItemPageState extends State<ItemPage> {
  TextEditingController mainSearch = new TextEditingController();

  //gets default item if it couldn't be loaded
  Item _item = Item.fromDefault();

  //the full series list. Cache to prevent excessive server calls.
  List<charts.Series<SimpleDataPoint, num>> fullSeriesList =
      _createDefaultGraph();

  //the series list. Essentially the data
  List<charts.Series<SimpleDataPoint, num>> seriesList = _createDefaultGraph();
  //holds the ticks for the range
  charts.StaticNumericTickProviderSpec ticks;

  //holds how many past days to show on the chart
  double chartDays = 30.0;

  //holds the communicator to the server
  Communicator communicator = new Communicator();

  //default constructor
  _ItemPageState(Item item, List<charts.Series<SimpleDataPoint, num>> list) {
    _item = item;
    fullSeriesList = list;
    seriesList = communicator.truncateGraph(fullSeriesList, chartDays);
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
    }).catchError((error) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(error.toString()),
      ));
    });

    communicator.getItemChartNow(id).then((value) {
      // List<charts.Series<SimpleDataPoint, num>>
      setState(() {
        seriesList = communicator.truncateGraph(value, chartDays);
      });
    }).catchError((error) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(error.toString()),
      ));
    });
  }

  void updateChart() {
    setState(() {
      seriesList = communicator.truncateGraph(fullSeriesList, chartDays);
    });
  }

  //load id to name map
  Future<String> loadAsset() async {
    //for some reason if you just do assets: assets/ this function does not work.
    return await rootBundle.loadString('assets/dict/IDtoItemName.csv');
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
            Row(
              children: <Widget>[
                //image
                Hero(
                  tag: 'watchlistedItem' + _item.imageURL,
                  child: Image.network(
                    _item.imageURL,
                    height: 125,
                    width: 125,
                  ),
                ),
                //image desc
                Expanded(
                  child: Text('${_item.description}',
                      style: Theme.of(context).textTheme.headline6,
                      overflow: TextOverflow.ellipsis,
                      maxLines: 3),
                ),
              ],
            ),
            //holds the current price, and trend
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: <Widget>[
                Column(
                  children: <Widget>[
                    //item price
                    Text(
                      ' ${_item.currentPrice}',
                      style: Theme.of(context)
                          .textTheme
                          .headline5
                          .copyWith(fontWeight: FontWeight.bold),
                    ),
                    //item trend
                    Text(' current')
                  ],
                ),
                Column(
                  children: <Widget>[
                    Text(
                      '${_item.thirtyDayChange}',
                      style: Theme.of(context).textTheme.headline5,
                    ),
                    //item trend
                    Text('30 day')
                  ],
                ),
                Column(
                  children: <Widget>[
                    Text(
                      '${_item.ninetyDayChange}',
                      style: Theme.of(context).textTheme.headline5,
                    ),
                    //item trend
                    Text('90 day')
                  ],
                ),
                Column(
                  children: <Widget>[
                    Text(
                      '${_item.oneEightyDayChange}',
                      style: Theme.of(context).textTheme.headline5,
                    ),
                    //item trend
                    Text('180 day')
                  ],
                )
              ],
            ),
            //the chart itself
            Expanded(child: SimpleTimeSeriesChart(seriesList, animate: true)),
            //holds the buttons for how to view chart
            Slider(
                value: chartDays,
                onChanged: (newValue) {
                  setState(() {
                    chartDays = newValue;
                    seriesList =
                        communicator.truncateGraph(fullSeriesList, chartDays);
                  });
                },
                min: 0,
                max: 180,
                divisions: 18,
                label: "$chartDays"),
          ],
        ),
      ),
    );
  }
}
