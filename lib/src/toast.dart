import 'dart:async';
import 'dart:collection';

import 'package:an_toast/src/lifecycle_timer.dart';
import 'package:cancellable/cancellable.dart';
import 'package:flutter/material.dart';

import 'cancellable_timer.dart';
import 'toast_anim_widget.dart';

typedef ToastMessageWidgetBuilder = Widget Function(
    BuildContext context, String message, Widget? icon, Axis axis);

class _ToastTask {
  final Widget Function(BuildContext context, int duration) builder;

  final int _duration;
  final bool _useLifecycleTimer;

  final ToastGravity gravity;
  late final OverlayEntry _toastOverlay = _makeToastOverlay();

  final Cancellable _activeCancellable;

  Timer? _timer;

  bool get isActive => _timer != null && _timer!.isActive;

  _ToastTask(this.builder, this._duration, this._useLifecycleTimer,
      void Function() onFinish, Cancellable? cancellable, this.gravity)
      : _activeCancellable =
            cancellable?.makeCancellable(infectious: true) ?? Cancellable() {
    _activeCancellable.onCancel.then((value) => onFinish());
    // cancellable?.bindCancellable(_activeCancellable);
  }

  void run(OverlayState overlayState) {
    if (_activeCancellable.isUnavailable) return;
    finishTimer() {
      if (_activeCancellable.isUnavailable) {
        return;
      }
      _activeCancellable.cancel();
      try {
        _toastOverlay.remove();
      } catch (_) {}
      _timer = null;
    }

    overlayState.insert(_toastOverlay);

    if (_useLifecycleTimer) {
      _timer = LifecycleCountdownTimer(
          interval: Duration(milliseconds: 100),
          totalDuration: Duration(milliseconds: _duration),
          onFinishCallback: finishTimer)
        ..start();
    } else {
      _timer = CancellableTimer(
          Duration(milliseconds: _duration), finishTimer, finishTimer);
    }
  }

  void cancel() {
    if (_activeCancellable.isUnavailable) return;
    if (_timer == null) {
      _activeCancellable.cancel();
    } else {
      _timer?.cancel();
    }
  }

  OverlayEntry _makeToastOverlay() {
    Widget builder(BuildContext context) {
      Widget toast =
          Builder(builder: (context) => this.builder(context, _duration));

      toast = Padding(
        padding: const EdgeInsets.symmetric(horizontal: 27),
        child: Center(
          child: toast,
        ),
      );

      toast = Material(
        type: MaterialType.transparency,
        color: Colors.transparent,
        child: toast,
      );

      toast = SafeArea(child: toast);

      toast = IgnorePointer(
        child: toast,
      );
      switch (gravity) {
        case ToastGravity.top:
          toast =
              Positioned(top: kToolbarHeight, left: 0, right: 0, child: toast);
          break;
        case ToastGravity.center:
          break;
        case ToastGravity.bottom:
          toast = Positioned(
              bottom: kBottomNavigationBarHeight,
              left: 0,
              right: 0,
              child: toast);
          break;
      }
      return toast;
    }

    return OverlayEntry(builder: builder);
  }
}

/// 可以管理 全局 toast 的默认配置信息
class ToastManager {
  // ignore: constant_identifier_names
  static const int DURATION_SHORT = 1000;

  // ignore: constant_identifier_names
  static const int DURATION_LONG = 3000;

  ToastManager._();

  static final ToastManager _instance = ToastManager._();

  // 唯一实例
  static ToastManager get instance => _instance;

  ///是否立即展示最新的toast 之前的toast将会立即结束或跳过展示
  bool immediately = true;

  /// 使用与生命周期相关的计时器 当app不可见时会暂停计时器
  bool useLifecycleTimer = true;

  /// 默认的 toast 的展示位置
  ToastGravity gravity = ToastGravity.bottom;

  /// 默认的 toast 的展示时间
  int duration = ToastManager.DURATION_LONG;

  /// 用来自定义toast显示的 overlay 的寄存器
  OverlayState? Function() findOverlayState = _findOverlayState;

  /// 定义如何将 String 的 message 转换为widget
  ToastMessageWidgetBuilder messageWidgetBuilder =
      (_, message, __, ___) => Text(message);

  final Queue<_ToastTask> _toastQueue = Queue<_ToastTask>();

  /// 自定义全局的toast的出现动画
  Widget Function(BuildContext context, int duration, Widget toastWidget)
      toastAnimateBuilder = (_, d, t) => AnimationToastWidget(
            animationDuration: d,
            child: Container(
              margin: const EdgeInsets.symmetric(vertical: 24),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xC0000000),
                // Color(0xFF000000).withOpacity(0.75)
                borderRadius: const BorderRadius.all(Radius.circular(12)),
              ),
              child: DefaultTextStyle.merge(
                  style: const TextStyle(color: Colors.white), child: t),
            ),
          );

  /// 也可以使用此函数 来展示一个完全自定义效果的toast 可自定义动画效果
  void showToast(Widget Function(BuildContext context, int duration) builder,
      {int? duration,
      ToastGravity? gravity,
      void Function()? onDismiss,
      Cancellable? cancellable}) {
    assert(() {
      if (duration != null && duration < 1) {
        assert(false, 'showToast duration must >0');
      }
      return true;
    }());

    late _ToastTask toast;
    taskFinish() {
      _toastQueue.remove(toast);
      onDismiss?.call();
      _peekToast();
    }

    toast = _ToastTask(builder, duration ?? this.duration, useLifecycleTimer,
        taskFinish, cancellable, gravity ?? this.gravity);
    _toastQueue.addLast(toast);
    _peekToast();
  }

  OverlayState? _overlayState;

  void _peekToast() {
    if (_overlayState == null || !_overlayState!.mounted) {
      _overlayState = findOverlayState.call();
      if (_overlayState == null || !_overlayState!.mounted) {
        WidgetsBinding.instance.addPostFrameCallback((_) => _peekToast());
        return;
      }
    }
    if (_toastQueue.isNotEmpty) {
      var curr = _toastQueue.first;
      if (immediately && _toastQueue.length > 1) {
        curr.cancel();
      } else if (!curr.isActive) {
        curr.run(_overlayState!);
      }
    }
  }
}

OverlayState? _findOverlayState() {
  try {
    final rootElement = WidgetsBinding.instance.rootElement;
    if (rootElement != null) {
      NavigatorState? navigator = _findStateForChildren(rootElement);
      if (navigator != null && navigator.mounted) {
        return navigator.overlay;
      }
    }
  } catch (_) {}
  return null;
}

T? _findStateForChildren<T extends State>(Element element) {
  if (element is StatefulElement && element.state is T) {
    return element.state as T;
  }
  T? target;
  element.visitChildElements((e) => target ??= _findStateForChildren(e));
  return target;
}

/// 唯一 对象
class ToastCompanion {
  ///  默认的 toast 的展示时间 短时间 1s
  // ignore: non_constant_identifier_names
  final int DURATION_SHORT = ToastManager.DURATION_SHORT;

  ///  默认的 toast 的展示时间 长时间 3s
  // ignore: non_constant_identifier_names
  final int DURATION_LONG = ToastManager.DURATION_LONG;

  ///  默认的 toast 的展示时间 短时间 1s
  final int durationShort = ToastManager.DURATION_LONG;

  ///  默认的 toast 的展示时间 长时间 3s
  final int durationLong = ToastManager.DURATION_LONG;

  const ToastCompanion._();
}

// Toast的默认对象 来模拟Android的static效果
// ignore: constant_identifier_names, non_constant_identifier_names
const ToastCompanion Toast = ToastCompanion._();

extension ToastCompanionDefShow on ToastCompanion {
  /// 展示普通的toast内容
  void show(String message,
          {Widget? icon,
          Axis axis = Axis.horizontal,
          int? duration,
          ToastGravity? gravity,
          void Function()? onDismiss,
          Cancellable? cancellable}) =>
      showWidgetBuilder(
          (context, duration) => ToastManager.instance.toastAnimateBuilder(
                context,
                duration,
                ToastManager.instance
                    .messageWidgetBuilder(context, message, icon, axis),
              ),
          duration: duration,
          gravity: gravity,
          onDismiss: onDismiss,
          cancellable: cancellable);

  /// 自定义的toast 使用默认的动画效果
  void showWidget(Widget messageWidget,
          {int? duration,
          ToastGravity? gravity,
          void Function()? onDismiss,
          Cancellable? cancellable}) =>
      showWidgetBuilder(
          (context, duration) => ToastManager.instance
              .toastAnimateBuilder(context, duration, messageWidget),
          duration: duration,
          gravity: gravity,
          onDismiss: onDismiss,
          cancellable: cancellable);

  /// 完全自定义的toast 包含自定义动画效果
  void showWidgetBuilder(
      Widget Function(BuildContext context, int duration) messageWidgetBuilder,
      {int? duration,
      ToastGravity? gravity,
      void Function()? onDismiss,
      Cancellable? cancellable}) {
    ToastManager.instance.showToast(messageWidgetBuilder,
        duration: duration,
        gravity: gravity,
        onDismiss: onDismiss,
        cancellable: cancellable);
  }
}

/// toast 的显示位置
enum ToastGravity {
  top,
  center,
  bottom,
}
