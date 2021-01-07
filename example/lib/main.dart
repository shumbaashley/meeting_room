import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'views/echotest_view.dart';
import 'views/pubsub_view.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(GetMaterialApp(
    home: Home(),
  ));
}

class Home extends StatelessWidget {
  @override
  Widget build(context) => Scaffold(
      appBar: AppBar(title: Text('Meeting Room')),
      body: Center(
          child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          RaisedButton(
              child: Text('Meeting Room'),
              onPressed: () {
                Get.to(PubSubTestView(), transition: Transition.rightToLeft);
              }),
        ],
      )));
}
