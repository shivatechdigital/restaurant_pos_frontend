import 'dart:html' as html;

/// Opens the browser's native print dialog for the current page.
void triggerBrowserPrint() {
  html.window.print();
}
