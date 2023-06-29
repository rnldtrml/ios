import 'package:flutter/material.dart';
// import 'package:in_out_ios/application/config/constants.dart';
import 'package:in_out_ios/application/views/pages/home.dart';

main() async {
  runApp(const MaterialApp(
    debugShowCheckedModeBanner: false,
    home: HomePage(title: 'Employee Check IN & OUT',),
  ));
}