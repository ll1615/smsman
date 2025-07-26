import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sms_advanced/sms_advanced.dart';
import 'package:smsman/common/extension.dart';

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
  Map<int, bool> selectedIds = {};
  int? pressedId;

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

    var isNotSelectAll =
        selectedIds.values.length != smsList.length ||
        selectedIds.values.any((selected) => !selected);

    PreferredSizeWidget appBar = AppBar(actionsPadding: actionsPadding);

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

    var addressTextStyle = TextStyle(fontWeight: FontWeight.w500, fontSize: 16);
    var list = smsList.map((msg) {
      var address = Text(msg.address!, style: addressTextStyle);
      var body = Text(
        msg.body!,
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(color: Colors.grey[600]),
      );
      if (searchWords.isNotEmpty) {
        if (msg.address!.contains(searchWords)) {
          var highlightText = TextSpan(
            text: searchWords,
            style: addressTextStyle.copyWith(color: Colors.green),
          );
          var texts = msg.address!
              .split(searchWords)
              .where((s) => s.isNotEmpty)
              .map((s) => TextSpan(text: s, style: addressTextStyle))
              .toList()
              .insertBetween(highlightText);
          if (msg.address!.startsWith(searchWords)) {
            texts.insert(0, highlightText);
          }
          if (msg.address!.endsWith(searchWords)) {
            texts.add(highlightText);
          }
          address = Text.rich(TextSpan(children: texts));
        }

        if (msg.body!.contains(searchWords)) {
          var highlightText = TextSpan(
            text: searchWords,
            style: body.style!.copyWith(color: Colors.green),
          );
          var texts = msg.body!
              .split(searchWords)
              .where((s) => s.isNotEmpty)
              .map((s) => TextSpan(text: s, style: body.style))
              .toList()
              .insertBetween(highlightText);
          if (msg.body!.startsWith(searchWords)) {
            texts.insert(0, highlightText);
          }
          if (msg.body!.endsWith(searchWords)) {
            texts.add(highlightText);
          }
          body = Text.rich(
            TextSpan(children: texts),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          );
        }
      }

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
                  address,
                  Text(
                    formatDate(msg.date!),
                    style: TextStyle(color: Colors.grey[600]),
                  ),
                ],
              ),
              body,
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

      Color color = theme.colorScheme.surface;
      if (selectedIds[msg.id] ?? false) {
        color = Colors.grey[200]!;
      }
      if (pressedId == msg.id) {
        color = Colors.grey[300]!;
      }

      return GestureDetector(
        child: Container(
          color: color,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
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
        onTap: () {
          if (isSelectMode) {
            setState(() {
              selectedIds[msg.id!] = !(selectedIds[msg.id!] ?? false);
            });
            return;
          }

          Navigator.pushNamed(context, "/detail", arguments: msg);
        },
        onTapDown: (details) {
          setState(() {
            pressedId = msg.id;
          });
        },
        onTapUp: (details) {
          setState(() {
            pressedId = null;
          });
        },
        onTapCancel: () {
          setState(() {
            pressedId = null;
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

    var buttomNavigatorBarSize = MediaQuery.sizeOf(context).height / 12;
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
        appBar: appBar,
        body: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              height: 60,
              padding: const EdgeInsets.only(left: 20, right: 20, top: 20),
              child: Text(
                headText,
                style: theme.textTheme.headlineLarge!.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
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
        bottomNavigationBar: isSelectMode
            ? BottomAppBar(
                color: theme.colorScheme.surface,
                height: buttomNavigatorBarSize,
                padding: EdgeInsets.only(left: 20, right: 20),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    SizedBox.shrink(),
                    SizedBox(
                      height: buttomNavigatorBarSize,
                      width: buttomNavigatorBarSize,
                      child: InkWell(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.delete_forever_outlined),
                            Text('删除', style: theme.textTheme.bodySmall),
                          ],
                        ),
                        onTap: () {
                          // TODO: 添加点击处理逻辑
                        },
                      ),
                    ),
                  ],
                ),
              )
            : null,
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
