import 'dart:async' show Future;
import 'dart:math';
import 'package:GrandExchangeMonitor/NavDrawer.dart';
import 'package:GrandExchangeMonitor/SimpleTimeSeriesChart.dart';
import 'package:GrandExchangeMonitor/communicator.dart';
import 'package:GrandExchangeMonitor/home.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter_typeahead/flutter_typeahead.dart';
import 'package:flutter/material.dart';
import 'package:charts_flutter/flutter.dart' as charts;
import 'package:shared_preferences/shared_preferences.dart';
import 'Item.dart';
import 'chartselection.dart';
import 'AnimatedFloatingActionButton.dart';

class SearchPage extends StatefulWidget {
  final HomePageState parent;

  SearchPage(this.parent);

  @override
  _SearchPageState createState() => _SearchPageState(parent);
}

class _SearchPageState extends State<SearchPage> {
  TextEditingController mainSearch = new TextEditingController();

  //gets default item if it couldn't be loaded
  Item _item = Item.fromDefault();
  bool isWatchList = false;

  //gets suggestions
  //TODO: perhaps we should remove the No Suggestions so that it doesn't show up as a suggestion
  List<String> suggestions = ['No Suggestions'];
  //the form key for the autocomplete
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  //the controller for the textedit for the autocomplete
  final TextEditingController _typeAheadController = TextEditingController();

  //the series list. Essentially the data
  List<charts.Series<SimpleDataPoint, num>> seriesList = _createDefaultGraph();
  List<charts.Series<SimpleDataPoint, num>> toShowList = _createDefaultGraph();
  //holds the ticks for the range
  charts.StaticNumericTickProviderSpec ticks;

  //holds how many days of data to show
  double chartDays = 30.0;

  //holds the communicator to the server
  Communicator communicator = new Communicator();

  AnimatedFloatingActionButton fab;

  //holds parent
  final HomePageState parent;

  //default constructor
  _SearchPageState(this.parent) {
    //builds the suggestions to prevent null pointers
    buildSuggestions();
    communicator.getItemByIdNow('13190')
      .then((value) {
      setState(() {
        _item = value;
        updateChart(_item.id.toString());
      });
    })
    .catchError((error) {
      Scaffold.of(context).showSnackBar(SnackBar(
        content: Text(error.toString()),
      ));
    });

    fab = new AnimatedFloatingActionButton(() => FABOnPressed());
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

  void getItemByName(String name) {
    communicator.getItemByNameNow(name).then((value) {
      setState(() {
        _item = value;
        FocusManager.instance.primaryFocus.unfocus();
      });
      updateChart(value.id.toString());
    })
    .catchError((error) {
      setState(() {
        fab.animate();
      });

    });

  }

  void getItemById(String id) {
    communicator.getItemByIdNow(id).then((value) {
      setState(() {
        _item = value;
      });
    })
    .catchError((error) {
      Scaffold.of(context).showSnackBar(SnackBar(
        content: Text(error.toString()),
      ));
    });

    communicator.getItemChartNow(id).then((value) {
      // List<charts.Series<SimpleDataPoint, num>>
      setState(() {
        seriesList = value;
        toShowList = communicator.truncateGraph(value, chartDays);
      });
    })
      .catchError((error) {
      Scaffold.of(context).showSnackBar(SnackBar(
        content: Text(error.toString()),
      ));
    });

    isWatchlisted();
  }

  void updateChart(String id) {
    communicator.getItemChartNow(id).then((value) {
      // List<charts.Series<SimpleDataPoint, num>>
      setState(() {
        seriesList = value;
        toShowList = communicator.truncateGraph(value, chartDays);
      });
    })
    .catchError((error) {
      Scaffold.of(context).showSnackBar(SnackBar(
        content: Text(error.toString()),
      ));
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

  //edit items watch list status
  void _editWatchListStatus() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    List<String> watchList = (prefs.getStringList('watchlist'));
    if (watchList == null) {
      watchList = new List<String>();
    }
    if (watchList.contains(_item.id.toString())) {
      watchList.remove(_item.id.toString());
    } else {
      watchList.add(_item.id.toString());
    }
    prefs.setStringList('watchlist', watchList);
    isWatchlisted();
  }

  void isWatchlisted() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    List<String> watchList = (prefs.getStringList('watchlist'));
    if (watchList == null) {
      watchList = new List<String>();
    }
    if (watchList.contains(_item.id.toString())) {
      isWatchList = true;
    } else {
      isWatchList = false;
    }
    setState(() {});
  }

  Icon _getIcon() {
    if (isWatchList) {
      return Icon(Icons.star);
    } else {
      return Icon(Icons.star_border);
    }
  }

  AppBar getAppBar(BuildContext context) {
    return AppBar(
      // Here we take the value from the MyHomePage object that was created by
      // the App.build method, and use it to set our appbar title.
      title: Form(
        key: this._formKey,
        child: Column(
          children: <Widget>[
            //searchable auto complete field
            TypeAheadFormField(
              textFieldConfiguration: TextFieldConfiguration(
                controller: this._typeAheadController,
                decoration: InputDecoration(
                  hintText: 'Search for an item...',
                  hintStyle: TextStyle(color: Colors.white),
                ),
                style: TextStyle(color: Colors.white),
              ),
              //how to get suggestions
              suggestionsCallback: (pattern) {
                if (pattern != '') {
                  String correction = pattern[0].toUpperCase() + pattern.substring(1);
                  return getSuggestionsWithParam(correction);
                }
                return [];
              },
              //how should the suggestion items look
              itemBuilder: (context, suggestion) {
                return ListTile(
                  title: Text(suggestion),
                );
              },
              //how should the menu look
              transitionBuilder: (context, suggestionsBox, controller) {
                return suggestionsBox;
              },
              //what happens when a suggestion is pressed
              onSuggestionSelected: (suggestion) {
                //on suggestion pressed, update the view with new textfield
                this._typeAheadController.text = suggestion;
                setState(() {});
                //set item when we have it
                communicator.getItemByNameNow(suggestion).then((value) {
                  setState(() {
                    _item = value;
                    isWatchlisted();
                    updateChart(_item.id.toString());
                  });
                })
                .catchError((error) {
                  Scaffold.of(context).showSnackBar(SnackBar(
                    content: Text(error.toString()),
                  ));
                });
              },
            ),
          ],
        ),
      ),
      actions: <Widget>[
        Padding(
            padding: EdgeInsets.only(right: 10),
            child: GestureDetector(
                onTap: () {
                  _editWatchListStatus();
                },
                child: _getIcon())),
      ],
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
                Image.network(
                  _item.imageURL,
                  height: 125,
                  width: 125,
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
            Expanded(child: SimpleTimeSeriesChart(toShowList, animate: true)),
            //holds the buttons for how to view chart
            Slider(
              value: chartDays,
              onChanged: (newValue) {
                setState(() {
                  chartDays = newValue;
                  toShowList = communicator.truncateGraph(seriesList, chartDays);
                });
              },
              min: 0,
              max: 180,
              divisions: 18,
              label: "$chartDays"
            ),
          ],
        ),
      ),
    );
  }

  FloatingActionButton getFAB(BuildContext context) {
    return FloatingActionButton(
      onPressed: () {
        getItemByName(this._typeAheadController.text);
      },
      tooltip: 'Search',
      child: Icon(Icons.search),
      //add background color here.
    );

    // return AnimatedFloatingActionButton(icon: Icons.search, tooltip: 'Search', onPressed: getItemByName(this._typeAheadController.text));
    
  }

  void FABOnPressed() {
    String pattern = this._typeAheadController.text;
    String correction = pattern[0].toUpperCase() + pattern.substring(1);
    getItemByName(correction);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: getBody(context),
      floatingActionButton: fab,
      appBar: getAppBar(context),
      drawer: NavDrawer(parent, communicator.getRandomImage()),
    );
  }
}