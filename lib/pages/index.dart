import 'package:easy_refresh/easy_refresh.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_smart_dialog/flutter_smart_dialog.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:sms_advanced/sms_advanced.dart';

import '../common/loading.dart';
import '../common/common.dart';
import '../common/extension.dart';

class IndexPage extends StatefulWidget {
  const IndexPage({super.key});

  @override
  State<IndexPage> createState() => _IndexPageState();
}

class _IndexPageState extends State<IndexPage> {
  List<SmsMessage> smsList = [];
  String searchWords = '';
  bool isSelectMode = false;
  Map<int, SmsMessage> selectedIds = {};

  final textController = TextEditingController();
  final smsQuery = SmsQuery();
  final smsRemover = SmsRemover();

  void observer() async {
    var current = textController.text.trim();
    if (current == searchWords) {
      return;
    }

    selectedIds.clear();
    searchWords = current;

    loadingCall(updateSmsList);
  }

  @override
  void initState() {
    super.initState();

    // 监听输入框
    textController.addListener(debounce(Duration(milliseconds: 500), observer));
  }

  @override
  Widget build(BuildContext context) {
    var theme = Theme.of(context);
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
        appBar: _buildAppBar(),
        body: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              height: 60,
              padding: const EdgeInsets.only(left: 20, right: 20, top: 20),
              child: Text(
                _getHeaderText(),
                style: theme.textTheme.headlineLarge!.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
              child: TextField(
                controller: textController,
                decoration: InputDecoration(
                  prefixIcon: const Icon(Icons.search),
                  suffixIcon: searchWords.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear),
                          onPressed: textController.clear,
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
              child: Scrollbar(
                child: EasyRefresh(
                  header: const MaterialHeader(),
                  onRefresh: updateSmsList,
                  refreshOnStart: true,
                  child: ListView(children: _buildListView()),
                ),
              ),
            ),
          ],
        ),
        bottomNavigationBar: _buildBottomNavigationBar(),
      ),
    );
  }

  Future<List<SmsMessage>> getSmsList() async {
    if (!(await Permission.sms.isGranted)) {
      SmartDialog.showToast('无短信读取权限!');
      return List.empty();
    }

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

    return messages;
  }

  Future<void> updateSmsList() async {
    var messages = await getSmsList();

    setState(() {
      selectedIds.clear();
      smsList = messages;
    });
  }

  String _getHeaderText() {
    if (!isSelectMode) {
      return '信息 (${smsList.length} 项)';
    }

    var selectedCount = selectedIds.keys.length;
    if (selectedCount > 0) {
      return '已选择 $selectedCount 项';
    }

    return '选择信息';
  }

  List<Widget> _buildListView() {
    var theme = Theme.of(context);

    var addressTextStyle = TextStyle(fontWeight: FontWeight.w500, fontSize: 16);
    var bodyTextStyle = TextStyle(color: Colors.grey[600]);

    return smsList.map((msg) {
      var address =
          _buildHighlight(msg.address!, searchWords, addressTextStyle) ??
          Text(msg.address!, style: addressTextStyle);
      var body =
          _buildHighlight(msg.body!, searchWords, bodyTextStyle) ??
          Text(
            msg.body!,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(color: Colors.grey[600]),
          );

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
          SizedBox(
            width: 40,
            height: 65,
            child: Transform.scale(
              scale: 1.4,
              child: Checkbox(
                visualDensity: VisualDensity.comfortable,
                value: selectedIds[msg.id] != null,
                onChanged: (checked) {
                  setState(() {
                    if (checked!) {
                      selectedIds[msg.id!] = msg;
                    } else {
                      selectedIds.remove(msg.id!);
                    }
                  });
                },
                shape: CircleBorder(),
                side: BorderSide(width: 2, color: Colors.grey[400]!),
                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
            ),
          ),
        );
      }

      Color color = theme.colorScheme.surface;
      if (selectedIds[msg.id] != null) {
        color = Colors.grey[200]!;
      }

      return InkWell(
        child: Ink(
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
            selectedIds[msg.id!] = msg;
            isSelectMode = true;
          });
        },
        onTap: () async {
          if (isSelectMode) {
            setState(() {
              if (selectedIds[msg.id!] != null) {
                selectedIds.remove(msg.id!);
              } else {
                selectedIds[msg.id!] = msg;
              }
            });
            return;
          }

          FocusManager.instance.primaryFocus?.unfocus();
          var result = await Navigator.pushNamed(
            context,
            "/detail",
            arguments: msg,
          );
          if (result != null && (result as bool)) {
            updateSmsList();
          }
        },
      );
    }).toList();
  }

  Widget? _buildHighlight(String str, String target, TextStyle style) {
    if (target.isEmpty || !str.contains(target)) {
      return null;
    }

    var highlightText = TextSpan(
      text: target,
      style: style.copyWith(color: Colors.green),
    );
    var texts = str
        .split(target)
        .where((s) => s.isNotEmpty)
        .map((s) => TextSpan(text: s, style: style))
        .toList()
        .insertBetween(highlightText);
    if (str.startsWith(target)) {
      texts.insert(0, highlightText);
    }
    if (str.endsWith(target)) {
      texts.add(highlightText);
    }

    return Text.rich(
      TextSpan(children: texts),
      maxLines: 2,
      overflow: TextOverflow.ellipsis,
    );
  }

  bool get _isNotSelectAll {
    return selectedIds.keys.length != smsList.length;
  }

  PreferredSizeWidget _buildAppBar() {
    var actionsPadding = const EdgeInsets.symmetric(
      horizontal: 10,
      vertical: 10,
    );

    var textButtonStyle = TextButton.styleFrom(
      foregroundColor: Colors.green,
      textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
    );

    if (isSelectMode) {
      return AppBar(
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
                    if (_isNotSelectAll) {
                      setState(() {
                        for (var msg in smsList) {
                          selectedIds[msg.id!] = msg;
                        }
                      });
                    } else {
                      setState(() {
                        selectedIds.clear();
                      });
                    }
                  },
                  child: Text(_isNotSelectAll ? '全选' : '全不选'),
                ),
              ],
            ),
          ),
        ],
      );
    }

    var theme = Theme.of(context);
    double screenWidth = MediaQuery.of(context).size.width;
    return AppBar(
      actionsPadding: actionsPadding,
      actions: [
        PopupMenuButton(
          onSelected: moreMenuSelected,
          color: theme.colorScheme.surface,
          icon: const Icon(Icons.more_vert),
          shape: RoundedRectangleBorder(
            borderRadius: const BorderRadius.all(Radius.circular(10.0)),
          ),
          constraints: BoxConstraints.tightFor(width: screenWidth * 0.4),
          position: PopupMenuPosition.under,
          itemBuilder: (context) =>
              [
                    (MenuItem.requestPermission, '申请短信权限'),
                    (MenuItem.permissionSetting, '应用权限设置'),
                    (MenuItem.setDefaultSmsApp, '设置默认短信应用'),
                    (MenuItem.resetDefaultSmsApp, '恢复默认短信应用'),
                  ]
                  .map(
                    (menu) => PopupMenuItem(
                      value: menu.$1,
                      child: Container(
                        padding: const EdgeInsets.only(left: 10),
                        child: Text(
                          menu.$2,
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                  )
                  .toList(),
        ),
      ],
    );
  }

  void moreMenuSelected(item) async {
    switch (item) {
      case MenuItem.requestPermission:
        await Permission.sms.request();
        break;
      case MenuItem.permissionSetting:
        await openAppSettings();
        break;
      case MenuItem.setDefaultSmsApp:
        await setDefaultSmsApp();
        break;
      case MenuItem.resetDefaultSmsApp:
        await resetDefaultSmsApp();
        break;
    }
  }

  Widget? _buildBottomNavigationBar() {
    if (!isSelectMode) {
      return null;
    }

    var theme = Theme.of(context);
    var screenHeight = MediaQuery.sizeOf(context).height;
    var buttomNavigatorBarSize = screenHeight / 12;
    return BottomAppBar(
      color: theme.colorScheme.surface,
      height: buttomNavigatorBarSize,
      padding: EdgeInsets.only(left: 20, right: 20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          const SizedBox.shrink(),
          SizedBox(
            height: buttomNavigatorBarSize,
            width: buttomNavigatorBarSize,
            child: InkWell(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.delete_forever_outlined),
                  Text('删除', style: theme.textTheme.bodySmall),
                ],
              ),
              onTap: () {
                showModalBottomSheet(
                  context: context,
                  clipBehavior: Clip.antiAlias,
                  requestFocus: false,
                  builder: (context) {
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        InkWell(
                          onTap: () {
                            _deleteSmsMessages();
                          },
                          child: Padding(
                            padding: const EdgeInsets.symmetric(vertical: 20),
                            child: Center(
                              child: Text(
                                '删除 ${selectedIds.length} 条短信',
                                style: TextStyle(
                                  color: Colors.red,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 17,
                                ),
                              ),
                            ),
                          ),
                        ),
                        Divider(height: 0, indent: 20, endIndent: 20),
                        InkWell(
                          onTap: () {
                            Navigator.pop(context);
                          },
                          child: Padding(
                            padding: const EdgeInsets.symmetric(vertical: 20),
                            child: Center(
                              child: Text(
                                '取消',
                                style: TextStyle(
                                  color: Colors.blue[500],
                                  fontWeight: FontWeight.w600,
                                  fontSize: 17,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  _deleteSmsMessages() async {
    if (!(await isDefaultSmsApp())) {
      SmartDialog.showToast('请将应用设置为默认短信应用！');
      return;
    }

    await loadingCall(() async {
      if (mounted) {
        Navigator.pop(context);
      }

      var futures = selectedIds.values.map((msg) async {
        return await smsRemover.removeSmsById(msg.id!, msg.threadId!);
      });
      await Future.wait(futures);

      var messages = await getSmsList();
      setState(() {
        smsList = messages;
        isSelectMode = false;
        selectedIds.clear();
      });
    });
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
