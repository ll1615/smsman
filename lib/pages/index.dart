import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sms_advanced/sms_advanced.dart';

import '/common/logger.dart';

class IndexPage extends StatefulWidget {
  const IndexPage({super.key});

  @override
  State<IndexPage> createState() => _IndexPageState();
}

class _IndexPageState extends State<IndexPage> {
  List<SmsMessage> smsList = [];
  String searchWords = '';
  bool isSelectMode = false;
  var selectedIds = <int, bool>{};

  final controller = TextEditingController();
  final SmsQuery smsQuery = SmsQuery();

  @override
  void initState() {
    super.initState();

    // 监听输入框
    controller.addListener(() {
      var current = controller.text.trim();
      if (current == searchWords) {
        return;
      }

      selectedIds.clear();
      searchWords = current;
      getAllSms();
    });

    getAllSms();
  }

  getAllSms() async {
    List<SmsMessage> messages = await smsQuery.querySms();
    if (searchWords.isNotEmpty) {
      messages = messages
          .where(
            (msg) =>
                msg.address!.contains(searchWords) ||
                msg.body!.contains(searchWords),
          )
          .toList();
    }

    setState(() {
      smsList = messages;
    });
  }

  @override
  Widget build(BuildContext context) {
    var theme = Theme.of(context);

    var textButtonStyle = TextButton.styleFrom(
      foregroundColor: Colors.green,
      textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
    );

    var actionsPadding = const EdgeInsets.symmetric(
      horizontal: 10,
      vertical: 10,
    );

    PreferredSizeWidget? appBar;

    var isNotSelectAll =
        selectedIds.values.length != smsList.length ||
        selectedIds.values.any((selected) => !selected);

    if (isSelectMode) {
      appBar = AppBar(
        actionsPadding: actionsPadding,
        actions: [
          Expanded(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                TextButton(
                  style: textButtonStyle,
                  onPressed: () => {
                    setState(() {
                      selectedIds.clear();
                      isSelectMode = false;
                    }),
                  },
                  child: Text('取消'),
                ),
                TextButton(
                  style: textButtonStyle,
                  onPressed: () {
                    if (isNotSelectAll) {
                      setState(() {
                        for (var msg in smsList) {
                          selectedIds[msg.id!] = true;
                        }
                      });
                    } else {
                      setState(() {
                        selectedIds.clear();
                      });
                    }
                  },
                  child: Text(isNotSelectAll ? '全选' : '全不选'),
                ),
              ],
            ),
          ),
        ],
      );
    }

    var list = smsList.map((msg) {
      var children = [
        Padding(
          padding: const EdgeInsets.only(right: 8.0),
          child: Icon(Icons.info_outline, size: 40, color: Colors.grey),
        ),
        Expanded(
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    msg.address!,
                    style: TextStyle(fontWeight: FontWeight.w500, fontSize: 16),
                  ),
                  Text(
                    formatDate(msg.date!),
                    style: TextStyle(color: Colors.grey[600]),
                  ),
                ],
              ),
              Text(
                msg.body!,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(color: Colors.grey[600]),
              ),
            ],
          ),
        ),
      ];
      if (isSelectMode) {
        children.add(
          Checkbox(
            value: selectedIds[msg.id] ?? false,
            onChanged: (checked) {
              setState(() {
                selectedIds[msg.id!] = checked!;
              });
            },
          ),
        );
      }

      return GestureDetector(
        child: Container(
          margin: const EdgeInsets.only(top: 10, bottom: 10),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: children,
          ),
        ),
        onLongPress: () {
          setState(() {
            selectedIds[msg.id!] = true;
            isSelectMode = true;
          });
        },
      );
    }).toList();

    var headText = '信息';
    if (isSelectMode) {
      headText = '选择信息';
      var selectedCount = selectedIds.values
          .where((selected) => selected)
          .toList()
          .length;
      if (selectedCount > 0) {
        headText = '已选择 $selectedCount 项';
      }
    }

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) {
          return;
        }

        if (isSelectMode) {
          setState(() {
            selectedIds.clear();
            isSelectMode = false;
          });
          return;
        }
        if (mounted) {
          SystemNavigator.pop();
        }
      },
      child: Scaffold(
        appBar: appBar ?? AppBar(actionsPadding: actionsPadding),
        body: Padding(
          padding: const EdgeInsets.only(top: 20, right: 20, left: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                headText,
                style: theme.textTheme.headlineLarge!.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              Container(
                margin: const EdgeInsets.only(top: 15, bottom: 15),
                child: TextField(
                  controller: controller,
                  decoration: InputDecoration(
                    prefixIcon: const Icon(Icons.search),
                    suffixIcon: searchWords.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear),
                            onPressed: controller.clear,
                          )
                        : null,
                    hintText: '搜索',
                    isDense: true,
                    filled: true,
                    fillColor: Colors.grey[200],
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
              ),
              Expanded(
                child: Scrollbar(child: ListView(children: list)),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String formatDate(DateTime date) {
    var now = DateTime.now();

    // 当天
    if (DateUtils.isSameDay(now, date)) {
      return '${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
    }

    // 昨天
    if (DateUtils.isSameDay(now, DateUtils.addDaysToDate(date, 1))) {
      return '昨天';
    }

    return '${date.month}月${date.day}日';
  }
}
