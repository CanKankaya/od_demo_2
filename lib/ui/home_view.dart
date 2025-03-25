import 'package:flutter/material.dart';
import 'package:od_demo_2/models/screen_params.dart';
import 'package:od_demo_2/ui/detector_widget.dart';

/// [HomeView] stacks [DetectorWidget]
class HomeView extends StatelessWidget {
  const HomeView({super.key});

  @override
  Widget build(BuildContext context) {
    ScreenParams.screenSize = MediaQuery.sizeOf(context);
    return Scaffold(
      key: GlobalKey(),
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text('Live Object Detection TFLite'),
      ),
      body: const DetectorWidget(),
    );
  }
}
