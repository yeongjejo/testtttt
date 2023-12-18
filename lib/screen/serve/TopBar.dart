import 'package:flutter/material.dart';

import '../../constant/CustomColor.dart';

class TopBar extends StatelessWidget {
  final String title; // 페이지 이름

  const TopBar({Key? key, required this.title}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 60,
      decoration: BoxDecoration(
        color: MAIN_BACKGROUND_COLOR,
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.7),
            spreadRadius: 0,
            blurRadius: 1.0,
            offset: const Offset(0, 3), // changes position of shadow
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Padding(
            padding: const EdgeInsets.all(7),
            child: TextButton(
                onPressed: () {Navigator.pop(context);},
                child: Image.asset('asset/img/close_btn2.png')),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(0, 0, 80, 0),
              // 이미지 패딩값 7 + 이미지 사이즈 73 = 80
              child: Text(title,
                  style: const TextStyle(
                    fontSize: 18.0,
                  ),
                  textAlign: TextAlign.center),
            ),
          ),
        ],
      ),
    );
  }
}