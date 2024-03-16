import 'package:flutter/material.dart';

import 'package:camera/camera.dart';

import 'package:od_demo_2/camera_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final cameras = await availableCameras();

  final firstCamera = cameras.first;

  runApp(
    MyApp(firstCamera: firstCamera),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({
    super.key,
    required this.firstCamera,
  });

  final CameraDescription? firstCamera;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: ThemeData.dark().copyWith(
        primaryColor: Colors.black,
        hintColor: Colors.amber,
      ),
      home: CameraScreen(
        camera: firstCamera!,
      ),
    );
  }
}
