import 'package:flutter/material.dart';

class MarginListItem extends StatelessWidget {

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding:EdgeInsets.all(4.0),
      child: Center(
        child: Row(
          children: <Widget>[
            Column(
              children: <Widget> [
                Text('Input Cost'),
                Text('placeholder')
              ]
            ),
            Icon(Icons.arrow_forward_sharp),
            Column(
              children: <Widget>[
                Text('Output Cost'),
                Text('Place Holder')
              ]
            )
          ]
        )
      )
    );
  }
}