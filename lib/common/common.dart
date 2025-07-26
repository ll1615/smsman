import 'dart:async';

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
