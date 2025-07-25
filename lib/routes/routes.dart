import 'package:flutter/material.dart';
import 'package:smsman/pages/index.dart';

Map<String, WidgetBuilder> allRouters(BuildContext context) {
  return <String, WidgetBuilder>{
    "/": (context) => IndexPage(),
    "/detail": (context) => Placeholder(),
  };
}
