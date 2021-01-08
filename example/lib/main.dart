import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'views/pubsub_view.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(GetMaterialApp(
    home: Home(),
    debugShowCheckedModeBanner: false
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
              child: Text('Create Meeting'),
              onPressed: () {
                Get.to(PubSubTestView(), transition: Transition.rightToLeft);
              }),
          RaisedButton(
              child: Text('Join Room'),
              onPressed: () {
                Get.to(PubSubTestView(), transition: Transition.rightToLeft);
              }),
        ],
      )));
}
