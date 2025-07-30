import 'dart:async';

import 'package:package_info_plus/package_info_plus.dart';

debounce(Duration delay, void Function() callback) {
  Timer? timer;
  return () {
    if (timer != null) {
      timer!.cancel();
    }
    timer = Timer(delay, () {
      callback();
      timer = null;
    });
  };
}

Future<String> getPackageName() async {
  var packageInfo = await PackageInfo.fromPlatform();
  return packageInfo.packageName;
}

enum MenuItem {
  delete,
  requestPermission,
  permissionSetting,
  setDefaultSmsApp,
  resetDefaultSmsApp,
}
