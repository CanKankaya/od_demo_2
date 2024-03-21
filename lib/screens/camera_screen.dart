import 'dart:async';

import 'package:connectivity/connectivity.dart';
import 'package:flutter/material.dart';

import 'package:camera/camera.dart';

import 'package:od_demo_2/utils/object_detection.dart';
import 'package:od_demo_2/widgets/api_container.dart';
import 'package:od_demo_2/widgets/custom_clipper.dart';
import 'package:od_demo_2/widgets/custom_error_message.dart';
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
  StreamSubscription<ConnectivityResult>? _connectivitySubscription;

  var _isLoading = false;
  var _flashMode = FlashMode.off;
  var _isOnline = false;

  ObjectDetection? objectDetection;
  List<int> apiResult = [];
  var timeDiff = const Duration();

  @override
  void dispose() {
    _controller.dispose();
    _connectivitySubscription?.cancel();

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
    _initializeControllerFuture = _controller.initialize().then(
          (value) => _controller.setFocusMode(FocusMode.auto),
        );

    _connectivitySubscription =
        Connectivity().onConnectivityChanged.listen((ConnectivityResult result) {
      setState(() {
        _isOnline = result != ConnectivityResult.none;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 23, 23, 23),
      appBar: AppBar(
        backgroundColor: Colors.black12,
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
                ApiContainer(result: apiResult),
                Align(
                  alignment: Alignment.bottomCenter,
                  child: _buildApiButton(),
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
                          fontSize: 14,
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
                if (!_isOnline)
                  Positioned(
                    top: 0,
                    left: 0,
                    right: 0,
                    child: Container(
                      color: Colors.red,
                      padding: const EdgeInsets.all(12.0),
                      child: const Text(
                        'İnternet bağlantınızı kontrol edin.',
                        style: TextStyle(color: Colors.white, fontSize: 16),
                        textAlign: TextAlign.center,
                      ),
                    ),
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

  Widget _buildApiButton() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: IconButton(
        color: const Color.fromARGB(215, 255, 193, 7),
        iconSize: 60,
        onPressed: _isLoading || !_isOnline
            ? null
            : () async {
                setState(() {
                  _isLoading = true;
                });

                await _initializeControllerFuture;
                final image = await _controller.takePicture();

                var startTime = DateTime.now();
                var tempResult = await objectDetection?.runInferenceOnAPI(image.path);
                if (tempResult != null) {
                  setState(() {
                    apiResult = tempResult;
                  });
                } else {
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    customErrorMessage(
                      context,
                      'Server\'a bağlanırken bir hata oluştu. Lütfen tekrar deneyin.',
                      '',
                      null,
                      false,
                    );
                  });
                }
                var endTime = DateTime.now();
                timeDiff = endTime.difference(startTime);

                WidgetsBinding.instance.addPostFrameCallback((_) {
                  setState(() {
                    _isLoading = false;
                  });
                });
              },
        icon: _isLoading
            ? const SimplerCustomLoader()
            : const Icon(
                Icons.camera,
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
          if (_flashMode == FlashMode.off) {
            await _controller.setFlashMode(FlashMode.torch);
            setState(() {
              _flashMode = FlashMode.torch;
            });
          } else {
            await _controller.setFlashMode(FlashMode.off);
            setState(() {
              _flashMode = FlashMode.off;
            });
          }
        },
        icon: Icon(
          _flashMode == FlashMode.off ? Icons.flash_off : Icons.flash_on,
          color: _flashMode == FlashMode.off ? Colors.white54 : Colors.amber,
        ),
      ),
    );
  }
}
