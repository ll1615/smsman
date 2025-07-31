import 'dart:async';

import 'package:flutter/services.dart';
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

Future<bool> isDefaultSmsApp() async {
  return (await getDefaultSmsApp()) == (await getPackageName());
}

Future<MethodChannel> get smsChannel async {
  return MethodChannel('${await getPackageName()}/smsApp');
}

Future<String> getDefaultSmsApp() async {
  return (await (await smsChannel).invokeMethod<String>('getDefaultSmsApp'))!;
}

Future<void> setDefaultSmsApp() async {
  await (await smsChannel).invokeMethod<String>('setDefaultSmsApp');
}

Future<void> resetDefaultSmsApp() async {
  await (await smsChannel).invokeMethod<String>('resetDefaultSmsApp');
}

enum MenuItem {
  delete,
  requestPermission,
  permissionSetting,
  setDefaultSmsApp,
  resetDefaultSmsApp,
  confirm,
  cancel,
}
