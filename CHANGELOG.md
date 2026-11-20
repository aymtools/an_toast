## 1.2.0

* Add customizable `ToastThemeProvider` (`themeProvider`) to isolate `flutter/material.dart` dependency.

## 1.1.2

* Remove dependency on `flutter/material.dart`.
* Fix an issue where `LifecycleCountdownTimer` falsely triggered `onCancelCallback` upon natural countdown completion.

## 1.1.1

* Fix a bug where a toast might not disappear when it is canceled using a cancellable.

## 1.1.0

* Customize the display style of string messages.

## 1.0.0

* Added ToastManager.useLifecycleTimer, which uses a lifecycle-aware timer that pauses when the app
  is not visible.

## 0.3.0

* Upgrading Dependencies.

## 0.2.0

* Add documentation and usage instructions.

## 0.1.0

* A Flutter toast library with usage identical to Android.
