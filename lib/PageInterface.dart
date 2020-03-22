import 'package:flutter/material.dart';

///Holds the methods that any page must inherit
abstract class PageInterface {
  AppBar getAppBar();
  Padding getBody();
  FloatingActionButton getFAB();
}