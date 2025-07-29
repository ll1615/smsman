import 'package:logger/logger.dart';

final logger = init();

Logger init() {
  return Logger(
    printer: PrettyPrinter(
      dateTimeFormat: DateTimeFormat.onlyTime,
      methodCount: 1,
      errorMethodCount: 5,
    ),
  );
}
