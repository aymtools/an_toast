import 'package:flutter/material.dart';

/// 默认的附带动画的效果的toast
class AnimationToastWidget extends StatefulWidget {
  final Widget child;
  final int animationDuration;

  const AnimationToastWidget(
      {super.key, required this.child, required this.animationDuration})
      : assert(animationDuration > 500, 'animationDuration > 500');

  @override
  State<AnimationToastWidget> createState() => _AnimationToastWidgetState();
}

class _AnimationToastWidgetState extends State<AnimationToastWidget>
    with TickerProviderStateMixin {
  late AnimationController controllerShowAnim,
      controllerShowOffset,
      controllerHide;

  late Animation<double> opacityAnim1,
      controllerCurvedShowOffset,
      opacityAnim2,
      offsetAnim;

  bool _isDisposed = false;

  @override
  void initState() {
    super.initState();
    _isDisposed = false;
    controllerShowAnim = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 250),
    );
    controllerShowOffset = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 350),
    );
    controllerHide = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 250),
    );
    opacityAnim1 = Tween(begin: 0.0, end: 1.0).animate(controllerShowAnim);
    controllerCurvedShowOffset = CurvedAnimation(
        parent: controllerShowOffset, curve: const _BounceOutCurve._());
    offsetAnim =
        Tween(begin: 30.0, end: 0.0).animate(controllerCurvedShowOffset);
    opacityAnim2 = Tween(begin: 1.0, end: 0.0).animate(controllerHide);

    controllerShowAnim.forward();
    controllerShowOffset.forward();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      Future.delayed(Duration(milliseconds: widget.animationDuration - 500))
          .then((_) {
        if (!_isDisposed) controllerHide.forward();
      });
    });
  }

  @override
  void dispose() {
    _isDisposed = true;
    controllerShowAnim.dispose();
    controllerShowOffset.dispose();
    controllerHide.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: opacityAnim1,
      child: widget.child,
      builder: (context, child) {
        return Opacity(
          opacity: opacityAnim1.value,
          child: AnimatedBuilder(
            animation: offsetAnim,
            builder: (context, _) {
              return Transform.translate(
                offset: Offset(0, offsetAnim.value),
                child: AnimatedBuilder(
                  animation: opacityAnim2,
                  builder: (context, _) {
                    return Opacity(
                      opacity: opacityAnim2.value,
                      child: child,
                    );
                  },
                ),
              );
            },
          ),
        );
      },
    );
  }
}

class _BounceOutCurve extends Curve {
  const _BounceOutCurve._();

  @override
  double transform(double t) {
    t -= 1.0;
    return t * t * ((2 + 1) * t + 2) + 1.0;
  }
}
