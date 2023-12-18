

import 'package:flutter/cupertino.dart';

class AdvertisingEnc {
  String key1;
  String key2;
  String userId;
  late List listUserid;
  late List<int> result;

  AdvertisingEnc(this.key1, this.key2, this.userId);

  List digits = [
    '0', '1', '2', '3', '4', '5',
    '6', '7', '8', '9',
    'a', 'b', 'c', 'd', 'e', 'f'
  ];

  void startEncryption() {
    String temp1 = convert16(key1);
    debugPrint("temp1 통과 $temp1");
    String temp2 = convert16(key2);
    debugPrint("temp2 통과 $temp2");
    int temp3;
    int temp4;
    if (temp1.length < 2){
      temp1 = "0$temp1";
    }
    debugPrint("temp1 완성 $temp1");
    if (temp2.length < 2){
      temp2 = "0$temp2";
    }
    debugPrint("temp2 완성 $temp2");
    temp3 = int.parse("${temp1[1]}${temp1[0]}", radix: 16);
    debugPrint("temp3 완성");
    temp4 = int.parse("${temp2[1]}${temp2[0]}", radix: 16);
    debugPrint("temp4 완성");

    listUserid = ["${userId[1]}${userId[0]}", "${userId[3]}${userId[2]}", "${userId[5]}${userId[4]}", "${userId[7]}${userId[6]}", "${userId[9]}${userId[8]}", "${userId[11]}${userId[10]}"];
    debugPrint("userId 완성");
    List convetedList = listUserid.map((number) => int.parse(number, radix: 16)).toList();
    debugPrint("convert 완성");
    result = [80,convetedList[0],convetedList[1],convetedList[2],temp3,convetedList[3],convetedList[4],convetedList[5],temp4];
  }

  String convert16(String num) {
    int inputNum = int.parse(num);
    String result = "";
    int radix = digits.length;


    while (inputNum > 0) {
      int quotient = inputNum ~/ radix;
      int mod = inputNum % radix;

      inputNum = quotient;
      result = digits[mod] + result;
    }

    return result;
  }
}