import 'package:fluttertoast/fluttertoast.dart';

class CustomToast {
  void showToast(String title) {
    Fluttertoast.showToast(
        msg: title,
        toastLength: Toast.LENGTH_SHORT,
        gravity: ToastGravity.BOTTOM,
        timeInSecForIosWeb: 5,
    );
  }
}
