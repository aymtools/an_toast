A custom-drawn Flutter toast library that does not rely on native implementation.

## Usage

```dart
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
              Toast.show('当前的toast样式及动画');
            },
            child: const Text('显示Toast'),
          ),
          TextButton(
            onPressed: () {
              Toast.show('当前的toast样式及动画', duration: Toast.DURATION_LONG);
            },
            child: const Text('显示Toast'),
          ),
        ],
      ),
    );
  }
}
```

See [example](https://github.com/aymtools/an_toast/blob/main/example/example.dart)
for detailed.

## Issues

If you encounter issues, here are some tips for debug, if nothing helps report
to [issue tracker on GitHub](https://github.com/aymtools/an_toast/issues):