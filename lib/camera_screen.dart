import 'dart:developer';
import 'package:flutter/material.dart';

import 'package:camera/camera.dart';
import 'package:image_picker/image_picker.dart';

import 'package:od_demo_2/models/recognition.dart';
import 'package:od_demo_2/object_detection.dart';
import 'package:od_demo_2/widgets/overlay_container.dart';
import 'package:od_demo_2/widgets/custom_clipper.dart';
import 'package:od_demo_2/widgets/simpler_custom_loading.dart';

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
      ResolutionPreset.high,
    );
    _initializeControllerFuture = _controller.initialize();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.black26,
        title: const Text('Tester'),
      ),
      body: FutureBuilder<void>(
        future: _initializeControllerFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.done) {
            return Stack(
              children: [
                CameraPreview(
                  _controller,
                ),
                const OverlayWithRectangleClipping(),
                OverlayContainer(result: result),
                Align(
                  alignment: Alignment.bottomCenter,
                  child: _buildButton(),
                ),
              ],
            );
          } else {
            return const SimplerCustomLoader();
          }
        },
      ),
    );
  }

  Widget _buildButton() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
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
                    setState(() {
                      isLoading = false;
                    });
                  });
                } catch (e) {
                  log(e.toString());
                }
              },
        icon: isLoading
            ? const SimplerCustomLoader()
            : const Icon(
                Icons.camera,
                color: Color.fromARGB(215, 255, 193, 7),
              ),
      ),
    );
  }
}
