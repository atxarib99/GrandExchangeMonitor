import 'package:flutter/material.dart';

///Holds the methods that any page must inherit
abstract class PageInterface {
  AppBar getAppBar(BuildContext context);
  Padding getBody(BuildContext context);
  FloatingActionButton getFAB(BuildContext context);
}