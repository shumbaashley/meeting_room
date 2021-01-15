import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:ion_flutter_example/views/create_meeting.dart';
import 'package:ion_flutter_example/views/join_meeting.dart';

import 'views/pubsub_view.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(GetMaterialApp(home: Home(), debugShowCheckedModeBanner: false));
}

class Home extends StatelessWidget {
  @override
  Widget build(context) => Scaffold(
      appBar: AppBar(title: Text('Pamwe')),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              RaisedButton(
                onPressed: () {
                  Get.to(CreateMeeting(), transition: Transition.rightToLeft);
                },
                child: Text(
                  'Create Meeting',
                  style: TextStyle(color: Colors.white),
                ),
                color: Theme.of(context).primaryColor,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(5.0),
                ),
              ),
              SizedBox(
                width: 20,
              ),
              RaisedButton(
                onPressed: () {
                  Get.to(JoinMeeting(), transition: Transition.rightToLeft);
                },
                child: Text(
                  'Join Meeting',
                  style: TextStyle(color: Colors.white),
                ),
                color: Colors.green,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(5.0),
                ),
              ),
            ],
          ),
        ],
      ));
}
