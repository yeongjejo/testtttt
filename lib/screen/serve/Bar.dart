import 'package:flutter/material.dart';

import '../../constant/CustomColor.dart';


class Bar extends StatelessWidget {
  final double barSize;
  const Bar({Key? key, required this.barSize}) : super(key: key);


  @override
  Widget build(BuildContext context) {
    return Container(
      color: BAR_COLOR,
      width: MediaQuery.of(context).size.width.toDouble(),
      height: barSize,
    );
  }
}
