import 'package:an_toast/src/lifecycle_timer.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('LifecycleTimer Tests', () {
    test('LifecycleTimer start, pause, resume, cancel lifecycle', () async {
      int tickCount = 0;
      bool cancelCalled = false;

      final timer = LifecycleTimer(
        interval: const Duration(milliseconds: 30),
        onTickCallback: (elapsed) {
          // 每次 tick 累计计数
          tickCount++;
        },
        onCancelCallback: () {
          // 标记取消已被触发
          cancelCalled = true;
        },
      );

      // 初始状态下未启动
      expect(timer.isActive, isFalse);

      // 启动定时器
      timer.start();
      expect(timer.isActive, isTrue);

      await Future.delayed(const Duration(milliseconds: 80));
      expect(tickCount, greaterThan(0));

      // 暂停定时器
      timer.pause();
      expect(timer.isActive, isFalse);
      final currentTickCount = tickCount;

      await Future.delayed(const Duration(milliseconds: 80));
      // 暂停期间 tick 计数不应增加
      expect(tickCount, equals(currentTickCount));

      // 恢复定时器
      timer.resume();
      expect(timer.isActive, isTrue);

      await Future.delayed(const Duration(milliseconds: 80));
      expect(tickCount, greaterThan(currentTickCount));

      // 取消定时器
      timer.cancel();
      expect(timer.isActive, isFalse);
      expect(cancelCalled, isTrue);
    });

    test('LifecycleCountdownTimer counts down and completes', () async {
      bool finished = false;
      Duration lastRemaining = const Duration(seconds: 10);

      final timer = LifecycleCountdownTimer(
        interval: const Duration(milliseconds: 20),
        totalDuration: const Duration(milliseconds: 100),
        onTickCallback: (remaining) {
          // 记录剩余时间
          lastRemaining = remaining;
        },
        onFinishCallback: () {
          // 标记倒计时结束
          finished = true;
        },
      );

      timer.start();
      await Future.delayed(const Duration(milliseconds: 160));

      // 验证倒计时已结束，且最终剩余时间归零
      expect(finished, isTrue);
      expect(lastRemaining, equals(Duration.zero));
      expect(timer.isActive, isFalse);
    });

    test('TimerManager responds to app lifecycle state changes', () async {
      int tickCount = 0;

      final timer = LifecycleTimer(
        interval: const Duration(milliseconds: 20),
        onTickCallback: (_) => tickCount++,
      );

      timer.start();
      expect(timer.isActive, isTrue);

      // 模拟应用进入后台（paused 状态）
      TimerManager.instance.didChangeAppLifecycleState(AppLifecycleState.paused);
      expect(timer.isActive, isFalse);

      // 模拟应用重回前台（resumed 状态）
      TimerManager.instance.didChangeAppLifecycleState(AppLifecycleState.resumed);
      expect(timer.isActive, isTrue);

      timer.cancel();
    });
  });
}
