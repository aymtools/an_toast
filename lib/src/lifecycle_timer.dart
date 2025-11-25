import 'dart:async';

import 'package:flutter/widgets.dart';

/// ======================
/// 基础生命周期感知计时器
/// ======================
abstract class BaseLifecycleTimer implements Timer {
  final Duration interval;
  Timer? _ticker;
  final Stopwatch _stopwatch = Stopwatch();
  int _tickCount = 0;

  final void Function()? onCancelCallback;

  BaseLifecycleTimer(this.interval, this.onCancelCallback) {
    TimerManager.instance._addTimer(this);
  }

  /// 启动
  void start() {
    if (_stopwatch.isRunning) return;
    _stopwatch.start();
    _ticker ??= Timer.periodic(interval, (_) {
      _tickCount++;
      onTick();
    });
  }

  /// 暂停
  void pause() {
    if (!_stopwatch.isRunning) return;
    _stopwatch.stop();
    _ticker?.cancel();
    _ticker = null;
  }

  /// 恢复
  void resume() {
    if (_stopwatch.isRunning) return;
    _stopwatch.start();
    _ticker ??= Timer.periodic(interval, (_) {
      _tickCount++;
      onTick();
    });
  }

  /// 提前结束（等价于 cancel）
  @override
  void cancel() {
    pause();
    onCancelCallback?.call();
    TimerManager.instance._removeTimer(this);
  }

  /// 已流逝时间
  Duration get elapsed => _stopwatch.elapsed;

  /// Timer 接口：是否仍然活跃
  @override
  bool get isActive => _stopwatch.isRunning;

  /// Timer 接口：tick 次数
  @override
  int get tick => _tickCount;

  /// 子类实现：每 tick 执行
  void onTick();

  /// 子类实现：结束时执行
  void onFinish();
}

/// ======================
/// 正向计时器
/// ======================
class LifecycleTimer extends BaseLifecycleTimer {
  final void Function(Duration elapsed)? onTickCallback;
  final void Function()? onFinishCallback;

  LifecycleTimer({
    required Duration interval,
    this.onTickCallback,
    this.onFinishCallback,
    void Function()? onCancelCallback,
  }) : super(interval, onCancelCallback);

  @override
  void onTick() => onTickCallback?.call(elapsed);

  @override
  void onFinish() => onFinishCallback?.call();
}

/// ======================
/// 倒计时计时器
/// ======================
class LifecycleCountdownTimer extends BaseLifecycleTimer {
  final Duration totalDuration;
  final void Function(Duration remaining)? onTickCallback;
  final void Function()? onFinishCallback;

  LifecycleCountdownTimer({
    required Duration interval,
    required this.totalDuration,
    this.onTickCallback,
    this.onFinishCallback,
    void Function()? onCancelCallback,
  }) : super(interval, onCancelCallback);

  @override
  void onTick() {
    final remaining = totalDuration - elapsed;
    if (remaining > Duration.zero) {
      onTickCallback?.call(remaining);
    } else {
      onTickCallback?.call(Duration.zero);
      cancel();
    }
  }

  @override
  void onFinish() => onFinishCallback?.call();
}

/// ======================
/// Timer 管理器（生命周期感知）
/// ======================
class TimerManager with WidgetsBindingObserver {
  TimerManager._internal() {
    WidgetsBinding.instance.addObserver(this);
  }

  static final TimerManager instance = TimerManager._internal();

  final List<BaseLifecycleTimer> _timers = [];

  void _addTimer(BaseLifecycleTimer timer) {
    _timers.add(timer);
  }

  void _removeTimer(BaseLifecycleTimer timer) {
    _timers.remove(timer);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      for (final t in _timers) {
        if (!t.isActive) t.resume();
      }
    } else if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.inactive ||
        state == AppLifecycleState.detached) {
      for (final t in _timers) {
        if (t.isActive) t.pause();
      }
    }
  }

  void dispose() {
    for (final t in _timers) {
      t.cancel();
    }
    _timers.clear();
    WidgetsBinding.instance.removeObserver(this);
  }
}
