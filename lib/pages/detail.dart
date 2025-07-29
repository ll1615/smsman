import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:sms_advanced/sms_advanced.dart';

import '../common/logger.dart';

class DetailPage extends StatelessWidget {
  const DetailPage({super.key});

  @override
  Widget build(BuildContext context) {
    SmsMessage msg = ModalRoute.of(context)!.settings.arguments as SmsMessage;
    logger.d('id: ${msg.id}, threadId: ${msg.threadId}');
    ThemeData theme = Theme.of(context);
    double screenHeight = MediaQuery.of(context).size.height;
    double screenWidth = MediaQuery.of(context).size.width;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) {
          return;
        }

        Navigator.pop(context);
      },
      child: Scaffold(
        appBar: AppBar(
          backgroundColor: Colors.grey[200],
          title: Text(msg.address!),
          actions: [
            PopupMenuButton(
              onSelected: (item) async {
                if (item == MenuItem.delete) {
                  var result = await SmsRemover().removeSmsById(
                    msg.id!,
                    msg.threadId!,
                  );
                  if (context.mounted) {
                    Navigator.pop(context, result);
                  }
                }
              },
              color: theme.colorScheme.surface,
              icon: const Icon(Icons.more_vert),
              shape: RoundedRectangleBorder(
                borderRadius: const BorderRadius.all(Radius.circular(10.0)),
              ),
              constraints: BoxConstraints.tightFor(width: screenWidth * 0.4),
              position: PopupMenuPosition.under,
              itemBuilder: (context) => [
                PopupMenuItem(
                  value: MenuItem.delete,
                  child: Container(
                    padding: const EdgeInsets.only(left: 10),
                    child: Text(
                      '删除',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
        body: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(height: 30),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 30),
              child: Text(formatDate(msg.date!)),
            ),
            Container(
              margin: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              padding: EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                msg.body!,
                style: theme.textTheme.titleMedium!.copyWith(
                  fontWeight: FontWeight.w500,
                  height: 1.5,
                  letterSpacing: 0.5,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String formatDate(DateTime date) {
    var now = DateTime.now();

    if (now.year > date.year) {
      return DateFormat('yyyy年M月d日 HH:mm').format(date);
    }

    return DateFormat('M月d日 HH:mm').format(date);
  }
}

enum MenuItem { delete }
