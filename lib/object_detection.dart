import 'dart:convert';
import 'dart:developer';
import 'dart:io';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:image/image.dart' as img;
import 'package:od_demo_2/constants.dart';
import 'package:od_demo_2/models/recognition.dart';
import 'package:tflite_flutter/tflite_flutter.dart';

class ObjectDetection {
  Interpreter? _interpreter;
  List<String>? _labels;

  ObjectDetection() {
    _loadModel();
    _loadLabels();
    log('Done.');
  }

  Future<void> _loadModel() async {
    log('Loading interpreter options...');
    final interpreterOptions = InterpreterOptions();

    // Use XNNPACK Delegate
    if (Platform.isAndroid) {
      interpreterOptions.addDelegate(XNNPackDelegate());
    }

    // Use Metal Delegate
    if (Platform.isIOS) {
      interpreterOptions.addDelegate(GpuDelegate());
    }

    log('Loading interpreter...');
    _interpreter = await Interpreter.fromAsset(modelPath, options: interpreterOptions);
  }

  Future<void> _loadLabels() async {
    log('Loading labels...');
    final labelsRaw = await rootBundle.loadString(labelPath);
    _labels = labelsRaw.split('\n');
  }

  Future<List<Recognition>> analyseImage(String imagePath) async {
    log('Analysing image...');
    // Reading image bytes from file
    final imageData = File(imagePath).readAsBytesSync();

    // Decoding image
    final image = img.decodeImage(imageData);

    // Resizing image fpr model, [300, 300]
    final imageInput = img.copyResize(
      image!,
      width: 300,
      height: 300,
    );

    // Creating matrix representation, [300, 300, 3]

    // Demo Model Input
    final imageMatrix = List.generate(
      imageInput.height,
      (y) => List.generate(
        imageInput.width,
        (x) {
          final pixel = imageInput.getPixel(x, y);
          return [pixel.r, pixel.g, pixel.b];
        },
      ),
    );

    // Hocanın Model Input
    // final imageMatrix = List.generate(
    //   imageInput.height,
    //   (y) => List.generate(
    //     imageInput.width,
    //     (x) {
    //       final pixel = imageInput.getPixel(x, y);
    //       return [pixel.r / 255, pixel.g / 255, pixel.b / 255];
    //     },
    //   ),
    // );

    final output = await _runInference(imageMatrix);

    log('Processing outputs...');
    // Location
    final locationsRaw = output.first.first as List<List<double>>;
    final locations = locationsRaw.map((list) {
      return list.map((value) => (value * 300).toInt()).toList();
    }).toList();
    log('Locations: $locations');

    // Classes
    final classesRaw = output.elementAt(1).first as List<double>;
    final classes = classesRaw.map((value) => value.toInt()).toList();
    log('Classes: $classes');

    // Scores
    final scores = output.elementAt(2).first as List<double>;
    log('Scores: $scores');

    // Number of detections
    final numberOfDetectionsRaw = output.last.first as double;
    final numberOfDetections = numberOfDetectionsRaw.toInt();
    log('Number of detections: $numberOfDetections');

    log('Classifying detected objects...');
    final List<String> classication = [];
    for (var i = 0; i < numberOfDetections; i++) {
      classication.add(_labels![classes[i]]);
    }

    // log('Outlining objects...');
    // for (var i = 0; i < numberOfDetections; i++) {
    //   if (scores[i] > 0.6) {
    //     // Rectangle drawing
    //     img.drawRect(
    //       imageInput,
    //       x1: locations[i][1],
    //       y1: locations[i][0],
    //       x2: locations[i][3],
    //       y2: locations[i][2],
    //       color: img.ColorRgb8(255, 0, 0),
    //       thickness: 3,
    //     );

    // Label drawing
    //     img.drawString(
    //       imageInput,
    //       '${classication[i]} ${scores[i]}',
    //       font: img.arial14,
    //       x: locations[i][1] + 1,
    //       y: locations[i][0] + 1,
    //       color: img.ColorRgb8(255, 0, 0),
    //     );
    //   }
    // }

    // log('Done.');

    return List.generate(numberOfDetections, (i) {
      return Recognition(
        location: locations[i],
        label: classication[i],
        score: scores[i],
      );
    }).where((recognition) => recognition.score > 0.5).toList();
  }

  Future<List<List<Object>>> _runInference(
    List<List<List<num>>> imageMatrix,
  ) async {
    log('Running inference...');

    // Set input tensor [1, 300, 300, 3]
    final input = [imageMatrix];

    // Set output tensor
    // Locations: [1, 10, 4]
    // Classes: [1, 10],
    // Scores: [1, 10],
    // Number of detections: [1]
    final output = {
      0: [List<List<num>>.filled(10, List<num>.filled(4, 0))],
      1: [List<num>.filled(10, 0)],
      2: [List<num>.filled(10, 0)],
      3: [0.0],
    };

    _interpreter!.runForMultipleInputs([input], output);
    //  Remove delay, its only for debugging
    // await Future.delayed(const Duration(seconds: 1));

    return output.values.toList();
  }

  Future<List<dynamic>> _runInferenceOnAPI(
    List<List<List<num>>> imageMatrix,
  ) async {
    log('Running inference...');

    // Set input tensor [1, 300, 300, 3]
    final input = [imageMatrix];

    var response = await http.post(
      Uri.parse(apiUrl),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({"photo": input}),
    );

    // Parse the response
    var responseData = jsonDecode(response.body);
    log(response.statusCode.toString());

    // Set output tensor
    // Locations: [1, 10, 4]
    // Classes: [1, 10],
    // Scores: [1, 10],
    // Number of detections: [1]
    final output = {
      0: responseData['locations'],
      1: responseData['classes'],
      2: responseData['scores'],
      3: responseData['numberOfDetections'],
    };

    return output.values.toList();
  }
}
