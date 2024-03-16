// ** For model changes;
//* change the inputSize below,
//* modelPath and labelPath,
//* and the formatting in imageAnalyser() in detector_service.dart */

const inputSize = 300;

const apiUrl = "http://18.234.85.247:8000/predict/";

const String modelPath = 'assets/models/ssd_mobilenet.tflite';
const String labelPath = 'assets/models/labelmap.txt';

// const String modelPath = 'assets/models/best_int8_320.tflite';
// const String labelPath = 'assets/models/best_int8.txt';
