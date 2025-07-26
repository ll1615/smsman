import 'package:flutter/material.dart';

import '../pages/index.dart';
import '../pages/detail.dart';

Map<String, WidgetBuilder> allRouters(BuildContext context) {
  return <String, WidgetBuilder>{
    "/": (context) => IndexPage(),
    "/detail": (context) => DetailPage(),
  };
}
