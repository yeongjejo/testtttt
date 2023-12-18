import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:kakao_flutter_sdk/kakao_flutter_sdk.dart';
import 'package:newep/screen/LoadingScreen.dart';
import 'package:newep/screen/MainScreen.dart';
import 'package:newep/screen/SetttingScreen.dart';
import 'package:newep/screen/TermsOfServiceScreen.dart';
import 'package:newep/screen/TermsWebView.dart';
import 'package:newep/screen/UpdateUserDataScreen.dart';
import 'package:newep/screen/UserManualWebView.dart';


import 'firebase_options.dart';


void main() async {
  //instance 초기화 + methodChannel 통신 안정성 보장, 정적 바인딩
  WidgetsFlutterBinding.ensureInitialized();
  FirebaseApp app = await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  KakaoSdk.init(
    nativeAppKey: '83ce8d6e03a7823d0beffa856d0d9e9d',
  );

  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);
  runApp(MaterialApp(
    debugShowCheckedModeBanner: false,

    initialRoute: '/',
    routes: {
      '/main' : (BuildContext context) => const MainScreen(),
      '/setting' : (BuildContext context) => const SettingScreen(),
      '/updateUser' : (BuildContext context) => const UpdateUserDataScreen(),
      '/termsOfService' : (BuildContext context) => const TermsOfServiceScreen(),
      '/terms' : (BuildContext context) => const TermWebView(),
      '/manual' : (BuildContext context) => const UserManualWebView(),
      '/' : (BuildContext context) => const LoadingScreen(),
    },
  ));
}

