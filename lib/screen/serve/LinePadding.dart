import 'package:flutter/material.dart';


// 라인 한줄 띄우기 용도
class LinePadding extends StatelessWidget {
  final double value;
  const LinePadding({Key? key, required this.value}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Padding(padding: EdgeInsets.all(value));
  }
}
