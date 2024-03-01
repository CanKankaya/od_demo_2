import 'dart:async';
// import 'dart:isolate';

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:od_demo_2/models/recognition.dart';
import 'package:od_demo_2/models/screen_params.dart';
import 'package:od_demo_2/service/detector_service.dart';
import 'package:od_demo_2/ui/box_widget.dart';
import 'package:od_demo_2/ui/stats_widget.dart';

class DetectorWidget extends StatefulWidget {
  const DetectorWidget({super.key});

  @override
  State<DetectorWidget> createState() => _DetectorWidgetState();
}

class _DetectorWidgetState extends State<DetectorWidget> with WidgetsBindingObserver {
  late List<CameraDescription> cameras;
  CameraController? _cameraController;
  Detector? _detector;
  StreamSubscription? _subscription;
  List<Recognition>? results;
  Map<String, String>? stats;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initStateAsync();
  }

  void _initStateAsync() async {
    _initializeCamera();
    Detector.start().then((instance) {
      setState(() {
        _detector = instance;
        _subscription = instance.resultStream.stream.listen((values) {
          setState(() {
            results = values['recognitions'];
            stats = values['stats'];
          });
        });
      });
    });
  }

  void _initializeCamera() async {
    cameras = await availableCameras();
    _cameraController = CameraController(
      cameras[0],
      ResolutionPreset.low,
      enableAudio: false,
    )..initialize().then((_) async {
        await _cameraController?.startImageStream(onLatestImageAvailable);
        setState(() {});

        ScreenParameters.previewSize = _cameraController!.value.previewSize!;
      });
  }

  @override
  Widget build(BuildContext context) {
    if (_cameraController == null || !_cameraController!.value.isInitialized) {
      return const SizedBox.shrink();
    }

    var aspect = 1 / _cameraController!.value.aspectRatio;

    return Stack(
      children: [
        AspectRatio(
          aspectRatio: aspect,
          child: CameraPreview(_cameraController!),
        ),
        _statsWidget(),
        AspectRatio(
          aspectRatio: aspect,
          child: _boundingBoxes(),
        ),
      ],
    );
  }

  Widget _statsWidget() => (stats != null)
      ? Align(
          alignment: Alignment.bottomCenter,
          child: Container(
            color: Colors.white.withAlpha(150),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: stats!.entries.map((e) => StatsWidget(e.key, e.value)).toList(),
              ),
            ),
          ),
        )
      : const SizedBox.shrink();

  Widget _boundingBoxes() {
    if (results == null) {
      return const SizedBox.shrink();
    }
    return Stack(children: results!.map((box) => BoxWidget(result: box)).toList());
  }

  void onLatestImageAvailable(CameraImage cameraImage) async {
    _detector?.processor(cameraImage);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) async {
    switch (state) {
      case AppLifecycleState.inactive:
        _cameraController?.stopImageStream();
        _detector?.kill();
        _subscription?.cancel();
        break;
      case AppLifecycleState.resumed:
        _initStateAsync();
        break;
      default:
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _cameraController?.dispose();
    _detector?.kill();
    _subscription?.cancel();
    super.dispose();
  }
}
