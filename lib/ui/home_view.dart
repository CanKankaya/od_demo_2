import 'package:flutter/material.dart';

import 'package:od_demo_2/models/screen_params.dart';
import 'package:od_demo_2/ui/detector_widget.dart';

class HomeView extends StatelessWidget {
  const HomeView({super.key});

  @override
  Widget build(BuildContext context) {
    ScreenParameters.screenSize = MediaQuery.sizeOf(context);
    return Scaffold(
      key: GlobalKey(),
      backgroundColor: Colors.black,
      appBar: AppBar(
          title: const Text(
        'OD Demo',
      )),
      body: const DetectorWidget(),
    );
  }
}
