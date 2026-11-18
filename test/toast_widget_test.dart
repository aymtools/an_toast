import 'package:an_toast/an_toast.dart';
import 'package:an_toast/src/toast_anim_widget.dart';
import 'package:cancellable/cancellable.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

Widget createTestApp({Widget? home}) {
  return WidgetsApp(
    color: const Color(0xFF000000),
    onGenerateRoute: (settings) {
      return PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) {
          return home ?? const SizedBox();
        },
      );
    },
  );
}

void main() {
  group('Toast Widget and Overlay Tests', () {
    testWidgets('Toast.show renders toast message in Overlay', (WidgetTester tester) async {
      // 构建包含 Navigator 和 Overlay 的测试应用
      await tester.pumpWidget(createTestApp());

      // 触发显示 Toast
      Toast.show('Test Toast Message', duration: 1000);

      // 推进帧以处理 PostFrameCallback 与 Overlay 挂载
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      // 验证 Overlay 中成功渲染出文本
      expect(find.text('Test Toast Message'), findsOneWidget);

      // 推进时间直到 Toast 计时器完成，清理 Pending Timer
      await tester.pump(const Duration(milliseconds: 1500));
    });

    testWidgets('Toast.showWidget renders custom widget in Overlay', (WidgetTester tester) async {
      // 构建包含 Navigator 和 Overlay 的测试应用
      await tester.pumpWidget(createTestApp());

      // 触发显示自定义 Widget Toast
      Toast.showWidget(
        const Text('Custom Widget Message', key: Key('custom_toast_key')),
        duration: 1000,
      );

      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      // 验证自定义 Key 的组件已成功在 Overlay 中显示
      expect(find.byKey(const Key('custom_toast_key')), findsOneWidget);

      // 推进时间直到 Toast 计时器完成，清理 Pending Timer
      await tester.pump(const Duration(milliseconds: 1500));
    });

    testWidgets('Toast canceled via Cancellable removes overlay entry', (WidgetTester tester) async {
      await tester.pumpWidget(createTestApp());

      bool onDismissCalled = false;
      final cancellable = Cancellable();

      // 显示带有 Cancellable 的 Toast
      Toast.show(
        'Cancellable Toast',
        duration: 3000,
        cancellable: cancellable,
        onDismiss: () {
          // 记录 onDismiss 回调触发
          onDismissCalled = true;
        },
      );

      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.text('Cancellable Toast'), findsOneWidget);

      // 主动取消 Cancellable
      cancellable.cancel();

      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      // 验证 Toast 已从 Overlay 中移除，且 onDismiss 回调执行
      expect(find.text('Cancellable Toast'), findsNothing);
      expect(onDismissCalled, isTrue);
    });

    testWidgets('AnimationToastWidget animates child widget', (WidgetTester tester) async {
      // 测试 AnimationToastWidget 的动画包裹行为
      await tester.pumpWidget(
        createTestApp(
          home: const Center(
            child: AnimationToastWidget(
              animationDuration: 1000,
              child: Text('Animated Child Text'),
            ),
          ),
        ),
      );

      // 初始帧渲染
      await tester.pump();
      expect(find.text('Animated Child Text'), findsOneWidget);

      // 推进动画
      await tester.pump(const Duration(milliseconds: 300));
      expect(find.text('Animated Child Text'), findsOneWidget);

      // 完成剩余动画与定时器清理
      await tester.pump(const Duration(milliseconds: 1000));
    });
  });
}
