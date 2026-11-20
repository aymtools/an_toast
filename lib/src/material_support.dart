import 'package:an_toast/src/toast.dart';

// ignore: deprecated_member_use
import 'package:flutter/material.dart';

@Deprecated('will remove in 1.2.0 , use `ToastThemeProvider` instead')
ToastThemeProvider materialThemeProvider =
    ({required Widget child}) => Material(
          type: MaterialType.transparency,
          color: Colors.transparent,
          child: child,
        );

// 用 DefaultTextStyle 替代透明 Material
// 注意：外层已经包了 IgnorePointer，所以内部绝对不可能有点击水波纹交互，替换 100% 安全！
ToastThemeProvider defaultThemeProvider =
    ({required Widget child}) => DefaultTextStyle(
          style: const TextStyle(
            color: Color(0xFFFFFFFF),
            fontSize: 14.0,
            fontWeight: FontWeight.normal,
            decoration: TextDecoration.none, // 消除 Overlay 默认黄色双下划线
          ),
          child: child,
        );
