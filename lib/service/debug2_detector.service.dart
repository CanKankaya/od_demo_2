import 'dart:developer';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:od_demo_2/constants.dart';

import 'dart:async';
import 'dart:io';
import 'dart:isolate';

import 'package:tflite_flutter/tflite_flutter.dart';
import 'package:camera/camera.dart';
import 'package:image/image.dart' as image_library;

import 'package:od_demo_2/models/recognition.dart';
import 'package:od_demo_2/utils/image_utils.dart';

enum _EnumCodes {
  init,
  busy,
  ready,
  detect,
  result,
}

class _Command {
  const _Command(this.code, {this.args});

  final _EnumCodes code;
  final List<Object>? args;
}

class Detector {
  Detector._(this._isolate, this._interpreter, this._labels);

  final Isolate _isolate;
  late final Interpreter _interpreter;
  late final List<String> _labels;

  late final SendPort _sendPort;

  bool _ready = false;

  final StreamController<Map<String, dynamic>> resultStream =
      StreamController<Map<String, dynamic>>();

  static Future<Detector> start() async {
    final ReceivePort receivePort = ReceivePort();
    final Isolate isolate = await Isolate.spawn(_DetectorServer._run, receivePort.sendPort);

    final Detector result = Detector._(
      isolate,
      await _loadModel(),
      await _loadLabels(),
    );
    receivePort.listen((message) {
      result._commandHandler(message as _Command);
    });
    return result;
  }

  static Future<Interpreter> _loadModel() async {
    final interpreterOptions = InterpreterOptions();

    if (Platform.isAndroid) {
      interpreterOptions.addDelegate(XNNPackDelegate());
    }

    // if (Platform.isAndroid) {
    //   interpreterOptions.addDelegate(GpuDelegate());
    // }

    return Interpreter.fromAsset(
      modelPath,
      options: interpreterOptions..threads = 8,
    );
  }

  static Future<List<String>> _loadLabels() async {
    return (await rootBundle.loadString(labelPath)).split('\n');
  }

  void processor(CameraImage cameraImage) {
    if (_ready) {
      _sendPort.send(_Command(_EnumCodes.detect, args: [cameraImage]));
    }
  }

  void _commandHandler(_Command command) {
    switch (command.code) {
      case _EnumCodes.init:
        _sendPort = command.args?[0] as SendPort;

        RootIsolateToken rootIsolateToken = RootIsolateToken.instance!;
        _sendPort.send(_Command(_EnumCodes.init, args: [
          rootIsolateToken,
          _interpreter.address,
          _labels,
        ]));
      case _EnumCodes.ready:
        _ready = true;
      case _EnumCodes.busy:
        _ready = false;
      case _EnumCodes.result:
        _ready = true;
        resultStream.add(command.args?[0] as Map<String, dynamic>);
      default:
        debugPrint('Detector unrecognized command: ${command.code}');
    }
  }

  void kill() {
    _isolate.kill();
  }
}

class _DetectorServer {
  static const double confidence = 0.5;
  Interpreter? _interpreter;
  List<String>? _labels;

  _DetectorServer(this._sendPort);

  final SendPort _sendPort;

  static void _run(SendPort sendPort) {
    ReceivePort receivePort = ReceivePort();
    final _DetectorServer server = _DetectorServer(sendPort);
    receivePort.listen((message) async {
      final _Command command = message as _Command;
      await server._handleCommand(command);
    });
    sendPort.send(_Command(_EnumCodes.init, args: [receivePort.sendPort]));
  }

  Future<void> _handleCommand(_Command command) async {
    switch (command.code) {
      case _EnumCodes.init:
        RootIsolateToken rootIsolateToken = command.args?[0] as RootIsolateToken;
        BackgroundIsolateBinaryMessenger.ensureInitialized(rootIsolateToken);
        _interpreter = Interpreter.fromAddress(command.args?[1] as int);
        _labels = command.args?[2] as List<String>;
        _sendPort.send(const _Command(_EnumCodes.ready));
      case _EnumCodes.detect:
        _sendPort.send(const _Command(_EnumCodes.busy));
        _convertCameraImage(command.args?[0] as CameraImage);
      default:
        debugPrint('_DetectorService unrecognized command ${command.code}');
    }
  }

  void _convertCameraImage(CameraImage cameraImage) {
    var preConversionTime = DateTime.now().millisecondsSinceEpoch;

    convertCameraImageToImage(cameraImage).then((image) {
      if (image != null) {
        if (Platform.isAndroid) {
          image = image_library.copyRotate(image, angle: 90);
        }

        final results = imageAnalyser(image, preConversionTime);
        _sendPort.send(_Command(_EnumCodes.result, args: [results]));
      }
    });
  }

  Map<String, dynamic> imageAnalyser(image_library.Image? image, int preConversionTime) {
    var conversionElapsedTime = DateTime.now().millisecondsSinceEpoch - preConversionTime;

    var preProcessStart = DateTime.now().millisecondsSinceEpoch;

    final imgInput = image_library.copyResize(
      image!,
      width: inputSize,
      height: inputSize,
    );

    //** This is for float32 format */
    final imageMatrix = List.generate(
      imgInput.height,
      (y) => List.generate(
        imgInput.width,
        (x) {
          final pixel = imgInput.getPixel(x, y);
          // Convert pixels to float32 and normalize them to [0, 1]
          return [pixel.r / 255.0, pixel.g / 255.0, pixel.b / 255.0];
        },
      ),
    );

    // //** This is for uint8 format */
    // final imageMatrix = List.generate(
    //   imgInput.height,
    //   (y) => List.generate(
    //     imgInput.width,
    //     (x) {
    //       final pixel = imgInput.getPixel(x, y);
    //       return [pixel.r, pixel.g, pixel.b];
    //     },
    //   ),
    // );

    var preProcessTime = DateTime.now().millisecondsSinceEpoch - preProcessStart;
    var startTime = DateTime.now().millisecondsSinceEpoch;
    final outputRaw = _runInference(imageMatrix)[0] as List<List<double>>;

    // //* Previous Model OutputRaw Extraction
    // final locationsRaw = outputRaw.first.first as List<List<double>>;
    // final List<Rect> locations = locationsRaw
    //     .map((list) => list.map((value) => (value * inputSize)).toList())
    //     .map((rect) => Rect.fromLTRB(rect[1], rect[0], rect[3], rect[2]))
    //     .toList();

    // final classesRaw = outputRaw.elementAt(1).first as List<double>;
    // final classes = classesRaw.map((value) => value.toInt()).toList();
    // final scores = outputRaw.elementAt(2).first as List<double>;
    // final numberOfDetections = (output.last.first as double).toInt();

    // final List<String> classification = [];
    // for (var i = 0; i < numberOfDetections; i++) {
    //   classification.add(_labels![classes[i]]);
    // }

    // List<Recognition> recognitions = [];
    // for (int i = 0; i < numberOfDetections; i++) {
    //   var score = scores[i];
    //   var label = classification[i];

    //   if (score > confidence) {
    //     recognitions.add(
    //       Recognition(i, label, score, locations[i]),
    //     );
    //   }
    // }

    //* New Model OutputRaw Extraction
    List<Recognition> recognitions = [];
    for (int i = 0; i < outputRaw.length; i++) {
      for (int j = 0; j < outputRaw[i].length; j += 6) {
        var x = outputRaw[i][j];
        var y = outputRaw[i][j + 1];
        var width = outputRaw[i][j + 2];
        var height = outputRaw[i][j + 3];
        var labelIndex = outputRaw[i][j + 4].toInt();
        var score = outputRaw[i][j + 5];
        var label = _labels![labelIndex];

        if (score > confidence) {
          recognitions.add(
            Recognition(i, label, score, Rect.fromLTWH(x, y, width, height)),
          );
        }
      }
    }

    var elapsedTime = DateTime.now().millisecondsSinceEpoch - startTime;
    var totalTime = DateTime.now().millisecondsSinceEpoch - preConversionTime;

    return {
      //TODO: Stats here
      "recognitions": recognitions,
      "stats": <String, String>{
        // 'Conversion time:': conversionElapsedTime.toString(),
        // 'Pre-processing time:': preProcessTime.toString(),
        // 'Inference time:': elapsedTime.toString(),
        'Tahmin süresi (ms):': totalTime.toString(),
        // 'Frame': '${image.width} X ${image.height}',
      },
    };
  }

  List<List<Object>> _runInference(
    List<List<List<num>>> imageMatrix,
  ) {
    final input = [imageMatrix];
    final output = [List<List<num>>.filled(14, List<num>.filled(2100, 0))];

    // final output = {
    //   0: [List<List<num>>.filled(10, List<num>.filled(4, 0))],
    //   1: [List<num>.filled(10, 0)],
    //   2: [List<num>.filled(10, 0)],
    //   3: [0.0],
    // };

    var inputDetails = _interpreter!.getInputTensors();
    var outputDetails = _interpreter!.getOutputTensors();

    _interpreter!.run(input, output);
    // _interpreter!.runForMultipleInputs([input], output);

    log("debug tester");
    log(output[0][0][0].toString());

    return output;
  }
}
