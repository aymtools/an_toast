import 'package:an_toast/an_toast.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('ToastManager and ToastCompanion Tests', () {
    test('ToastManager singleton default values', () {
      final manager = ToastManager.instance;

      // 验证 ToastManager 默认配置项
      expect(ToastManager.DURATION_SHORT, equals(1000));
      expect(ToastManager.DURATION_LONG, equals(3000));
      expect(manager.immediately, isTrue);
      expect(manager.useLifecycleTimer, isTrue);
      expect(manager.gravity, equals(ToastGravity.bottom));
      expect(manager.duration, equals(ToastManager.DURATION_LONG));
    });

    test('ToastCompanion constants match ToastManager', () {
      // 验证 Toast 全局静态属性常量与 ToastManager 对应一致
      expect(Toast.DURATION_SHORT, equals(ToastManager.DURATION_SHORT));
      expect(Toast.DURATION_LONG, equals(ToastManager.DURATION_LONG));
      expect(Toast.durationShort, equals(ToastManager.DURATION_LONG));
      expect(Toast.durationLong, equals(ToastManager.DURATION_LONG));
    });

    test('ToastGravity enum has correct values', () {
      // 验证 ToastGravity 枚举类型包含 top, center, bottom
      expect(ToastGravity.values.length, equals(3));
      expect(ToastGravity.values, containsAll([
        ToastGravity.top,
        ToastGravity.center,
        ToastGravity.bottom,
      ]));
    });
  });
}
