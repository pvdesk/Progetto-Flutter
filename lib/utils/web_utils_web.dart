import 'dart:js_interop';

@JS('window.open')
external void _windowOpen(JSString url, JSString target);

void openUrlInNewTab(String url) {
  _windowOpen(url.toJS, '_blank'.toJS);
}
