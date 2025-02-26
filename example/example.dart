import 'package:an_toast/an_toast.dart';
import 'package:flutter/material.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Toast Demo',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: const ToastDemo(),
    );
  }
}

class ToastDemo extends StatefulWidget {
  const ToastDemo({super.key});

  @override
  State<ToastDemo> createState() => _ToastDemoState();
}

class _ToastDemoState extends State<ToastDemo> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Toast Demo'),
      ),
      body: ListView(
        children: [
          TextButton(
            onPressed: () {
              Toast.show('当前的toast样式及动画', duration: Toast.DURATION_SHORT);
            },
            child: const Text('显示Toast 短时间'),
          ),
          TextButton(
            onPressed: () {
              Toast.show('当前的toast样式及动画', duration: Toast.DURATION_LONG);
            },
            child: const Text('显示Toast 长时间'),
          ),
          TextButton(
            onPressed: () {
              Toast.show('当前的toast样式及动画', gravity: ToastGravity.center);
            },
            child: const Text('显示Toast 中间'),
          ),
          TextButton(
            onPressed: () {
              Toast.show('当前的toast样式及动画', gravity: ToastGravity.top);
            },
            child: const Text('显示Toast 顶部'),
          ),
          TextButton(
            onPressed: () {
              Widget custom = const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.add_alert_outlined,
                    size: 25,
                  ),
                  Padding(padding: EdgeInsets.only(left: 6)),
                  Text('自定义的toast样式'),
                ],
              );
              Toast.showWidget(custom, gravity: ToastGravity.bottom);
            },
            child: const Text('显示Toast 自定义'),
          ),
        ],
      ),
    );
  }
}
