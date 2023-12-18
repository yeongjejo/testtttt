import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';


class UserManualWebView extends StatelessWidget {
  const UserManualWebView({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: WebView(
        initialUrl: ModalRoute.of(context)!.settings.arguments.toString(),
      ),
    );
  }
}
