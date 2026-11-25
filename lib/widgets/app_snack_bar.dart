import 'package:material_ui/material_ui.dart';

/// Shows a short message at the bottom of the screen, the same way everywhere:
/// - it goes away by itself after a few seconds, also when it has an action
///   such as "Undo" (since Flutter 3.50 a snack bar with an action stays until
///   it is tapped, unless told otherwise);
/// - it can be swiped away in any direction: left/right through the snack
///   bar itself, up/down through the drag on its content.
///
/// [messenger] is `ScaffoldMessenger.of(context)`, taken before any await or
/// before closing a sheet.
void showAppSnackBar(ScaffoldMessengerState messenger, String message, {SnackBarAction? action}) {
  void swipeAway(DragEndDetails _) => messenger.hideCurrentSnackBar(reason: SnackBarClosedReason.swipe);
  messenger
    ..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(
      content: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onVerticalDragEnd: swipeAway,
        child: Text(message),
      ),
      action: action,
      persist: false,
      duration: const Duration(seconds: 4),
      dismissDirection: DismissDirection.horizontal,
    ));
}
