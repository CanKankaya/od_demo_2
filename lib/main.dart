import 'dart:developer';
import 'package:flutter/material.dart';

import 'package:camera/camera.dart';
import 'package:image_picker/image_picker.dart';

import 'package:od_demo_2/models/recognition.dart';
import 'package:od_demo_2/object_detection.dart';
import 'package:od_demo_2/widgets/simpler_custom_loading.dart';

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

class CameraScreen extends StatefulWidget {
  const CameraScreen({
    Key? key,
    required this.camera,
  }) : super(key: key);
  final CameraDescription camera;

  @override
  State<CameraScreen> createState() => _CameraScreenState();
}

class _CameraScreenState extends State<CameraScreen> {
  late CameraController _controller;
  late Future<void> _initializeControllerFuture;
  var isLoading = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  final imagePicker = ImagePicker();

  ObjectDetection? objectDetection;

  List<Recognition> result = [];

  @override
  void initState() {
    super.initState();
    objectDetection = ObjectDetection();
    _controller = CameraController(
      widget.camera,
      ResolutionPreset.veryHigh,
    );
    _initializeControllerFuture = _controller.initialize();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Tester'),
      ),
      body: Stack(
        children: [
          FutureBuilder<void>(
            future: _initializeControllerFuture,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.done) {
                return CameraPreview(_controller);
              } else {
                return const Center(child: CircularProgressIndicator());
              }
            },
          ),
          Column(
            children: [
              _boxWidget(),
              if (result.isNotEmpty)
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      for (var item in result)
                        Expanded(
                          child: Container(
                            margin: const EdgeInsets.all(4),
                            padding: const EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: Colors.amber,
                                width: 2,
                              ),
                            ),
                            child: Text(
                              '${item.label} - ${item.score.toStringAsFixed(2)}',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
            ],
          ),
          Align(
            alignment: Alignment.bottomCenter,
            child: IconButton(
              iconSize: 50,
              onPressed: isLoading
                  ? null
                  : () async {
                      setState(() {
                        isLoading = true;
                      });
                      try {
                        await _initializeControllerFuture;
                        final image = await _controller.takePicture();

                        result = await objectDetection!.analyseImage(image.path);

                        WidgetsBinding.instance.addPostFrameCallback((_) {
                          if (!context.mounted) return;
                        });
                        setState(() {
                          isLoading = false;
                        });
                      } catch (e) {
                        log(e.toString());
                      }
                    },
              icon: isLoading
                  ? const SimplerCustomLoader()
                  : const Icon(
                      Icons.camera,
                      color: Colors.amber,
                    ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _boxWidget() {
    return Container(
      margin: const EdgeInsets.only(left: 16, right: 16, top: 150, bottom: 16),
      padding: const EdgeInsets.all(16),
      width: double.infinity,
      height: 100,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.amber,
          width: 3,
        ),
      ),
    );
  }
}
