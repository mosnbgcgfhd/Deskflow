import 'dart:html' as html;

void registerAppCloseListener(void Function() onClose) {
  html.window.addEventListener('beforeunload', (_) => onClose());
}
