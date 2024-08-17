import 'dart:collection';

import 'package:cancellable/cancellable.dart';
import 'package:flutter/material.dart';

import 'cancellable_timer.dart';
import 'toast_widget.dart';

class _ToastTask {
  final Widget Function(BuildContext context, int duration) builder;

  final int _duration;

  final ToastGravity gravity;
  late final OverlayEntry _toastOverlay = _makeToastOverlay();

  final Cancellable _activeCancellable;

  CancellableTimer? _timer;

  bool get isActive => _timer != null && _timer!.isActive;

  _ToastTask(this.builder, this._duration, void Function() onFinish,
      Cancellable? cancellable, this.gravity)
      : _activeCancellable = Cancellable() {
    _activeCancellable.onCancel.then((value) => onFinish());
    cancellable?.bindCancellable(_activeCancellable);
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
    _timer = CancellableTimer(
        Duration(milliseconds: _duration), finishTimer, finishTimer);
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
        padding: const EdgeInsets.all(24),
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

/// 可以管理 toast 的默认配置信息
class ToastManager {
  static const int DURATION_SHORT = 1000;
  static const int DURATION_LONG = 3000;

  ToastManager._();

  static final ToastManager _instance = ToastManager._();

  static ToastManager get instance => _instance;

  ///是否立即展示最新的toast 之前的toast将会立即结束或跳过展示
  bool immediately = true;

  /// 默认的 toast 的展示位置
  ToastGravity gravity = ToastGravity.bottom;

  /// 默认的 toast 的展示时间
  int duration = ToastManager.DURATION_LONG;

  /// 用来自定义toast显示的 overlay 的寄存器
  OverlayState? Function() findOverlayState = _findOverlayState;

  final Queue<_ToastTask> _toastQueue = Queue<_ToastTask>();
  Widget Function(BuildContext context, int duration, Widget toastWidget)
      toastAnimateBuilder = (_, d, t) => AnimationToastWidget(
            animationDuration: d,
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFF000000).withOpacity(0.75),
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

    toast = _ToastTask(builder, duration ?? this.duration, taskFinish,
        cancellable, gravity ?? this.gravity);
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
    final rootElement = WidgetsBinding.instance.renderViewElement;
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
  final int DURATION_SHORT = ToastManager.DURATION_SHORT;
  final int DURATION_LONG = ToastManager.DURATION_LONG;

  const ToastCompanion._();
}

/// Toast的默认对象 来模拟Android的static效果
const ToastCompanion Toast = ToastCompanion._();

extension ToastCompanionDefShow on ToastCompanion {
  /// 展示普通的toast内容
  void show(String message,
          {int? duration,
          ToastGravity? gravity,
          void Function()? onDismiss,
          Cancellable? cancellable}) =>
      showWidget(Text(message),
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
