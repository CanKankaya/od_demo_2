import 'dart:developer';
import 'package:flutter/material.dart';

import 'package:camera/camera.dart';
import 'package:image_picker/image_picker.dart';

import 'package:od_demo_2/models/recognition.dart';
import 'package:od_demo_2/object_detection.dart';
import 'package:od_demo_2/widgets/api_container.dart';
import 'package:od_demo_2/widgets/debug_container.dart';
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
  var flashMode = FlashMode.off;

  final imagePicker = ImagePicker();
  ObjectDetection? objectDetection;
  List<Recognition> result = [];
  List<int> newResult = [];
  var timeDiff = const Duration();
  var debugText = '';
  var statusCode = 0;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    objectDetection = ObjectDetection();
    _controller = CameraController(
      widget.camera,
      ResolutionPreset.high,
      enableAudio: false,
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
                ApiContainer(result: newResult),
                OverlayContainer(result: result),
                DebugContainer(
                  debugText: "Status Code: $statusCode\nJson Response: $debugText",
                ),
                Align(
                  alignment: Alignment.bottomCenter,
                  child: _buildApiButton(),
                ),
                Align(
                  alignment: Alignment.bottomRight,
                  child: _buildButton(),
                ),
                Container(
                  margin: const EdgeInsets.all(4),
                  padding: const EdgeInsets.all(4),
                  child: Column(
                    children: [
                      const Text(
                        'API Time;',
                        style: TextStyle(
                          color: Color.fromARGB(255, 200, 200, 200),
                          fontSize: 16,
                        ),
                      ),
                      Text(
                        '${timeDiff.inMilliseconds} ms',
                        style: const TextStyle(
                          color: Color.fromARGB(255, 200, 200, 200),
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                ),
                Positioned(
                  right: 0,
                  child: _buildFlashButton(),
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
                newResult = [];
                timeDiff = const Duration();
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
                Icons.construction,
                color: Color.fromARGB(215, 255, 193, 7),
              ),
      ),
    );
  }

  Widget _buildApiButton() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: IconButton(
        iconSize: 50,
        onPressed: isLoading
            ? null
            : () async {
                result = [];
                setState(() {
                  isLoading = true;
                });

                await _initializeControllerFuture;
                final image = await _controller.takePicture();

                var startTime = DateTime.now();
                var tempResult = await objectDetection!.runInferenceOnAPI(image.path);
                newResult = tempResult[0];
                debugText = tempResult[1].toString();
                statusCode = tempResult[2];

                var endTime = DateTime.now();
                timeDiff = endTime.difference(startTime);

                //TODO: Debugging, Remove later
                if (newResult.isEmpty) {
                  newResult.add(1);
                  newResult.add(2);
                  newResult.add(3);
                  newResult.add(4);
                  newResult.add(5);
                  newResult.add(6);
                }

                WidgetsBinding.instance.addPostFrameCallback((_) {
                  setState(() {
                    isLoading = false;
                  });
                });
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

  Widget _buildFlashButton() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: IconButton(
        iconSize: 30,
        onPressed: () async {
          if (flashMode == FlashMode.off) {
            await _controller.setFlashMode(FlashMode.torch);
            setState(() {
              flashMode = FlashMode.torch;
            });
          } else {
            await _controller.setFlashMode(FlashMode.off);
            setState(() {
              flashMode = FlashMode.off;
            });
          }
        },
        icon: Icon(
          flashMode == FlashMode.off ? Icons.flash_off : Icons.flash_on,
          color: flashMode == FlashMode.off ? Colors.white54 : Colors.amber,
        ),
      ),
    );
  }
}
