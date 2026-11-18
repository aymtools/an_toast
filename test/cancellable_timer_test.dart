import 'package:an_toast/src/cancellable_timer.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('CancellableTimer Tests', () {
    test('Timer triggers callback when duration elapses', () async {
      // 标记回调函数是否执行
      bool callbackFired = false;
      bool cancelFired = false;

      final timer = CancellableTimer(
        const Duration(milliseconds: 50),
        () => callbackFired = true,
        () => cancelFired = true,
      );

      // 验证初始状态下 Timer 处于活跃状态
      expect(timer.isActive, isTrue);
      expect(timer.tick, equals(0));

      // 等待 Timer 时间到达
      await Future.delayed(const Duration(milliseconds: 80));

      // 验证超时回调已触发，且未手动触发 cancel
      expect(callbackFired, isTrue);
      expect(cancelFired, isFalse);
    });

    test('Calling cancel cancels timer and invokes onCancel callback', () {
      // 标记回调和取消是否执行
      bool callbackFired = false;
      bool cancelFired = false;

      final timer = CancellableTimer(
        const Duration(milliseconds: 200),
        () => callbackFired = true,
        () => cancelFired = true,
      );

      // 手动取消定时器
      timer.cancel();

      // 验证取消后的状态及回调结果
      expect(timer.isActive, isFalse);
      expect(cancelFired, isTrue);
      expect(callbackFired, isFalse);
    });
  });
}
