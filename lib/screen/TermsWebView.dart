import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';


class TermWebView extends StatelessWidget {
  const TermWebView({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: WebView(
        initialUrl: ModalRoute.of(context)!.settings.arguments.toString(),
      ),
    );
  }
}
