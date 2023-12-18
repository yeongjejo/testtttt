import 'package:connectivity_plus/connectivity_plus.dart';

Future<String> checkNetwork() async {
  var connectivityResult = await (Connectivity().checkConnectivity());
  if (connectivityResult == ConnectivityResult.mobile) {
    return "데이터 사용중";
  } else if (connectivityResult == ConnectivityResult.wifi) {
    return "Wifi 사용중";
  } else {
    return "인터넷 연결 안됨";
  }
}