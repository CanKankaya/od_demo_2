import 'dart:convert';
import 'dart:developer';
import 'package:http/http.dart' as http;
import 'package:od_demo_2/constants.dart';

import 'package:http_parser/http_parser.dart';

//global variable notifier

class ObjectDetection {
  Future<List<int>?> runInferenceOnAPI(String imagePath) async {
    log('Running inference on API...');

    var request = http.MultipartRequest('POST', Uri.parse(apiUrl))
      ..files.add(await http.MultipartFile.fromPath(
        'file',
        imagePath,
        contentType: MediaType('image', 'jpeg'),
      ));

    var response = await request.send();

    if (response.statusCode == 200) {
      log('Response: 200');
      var responseData = await response.stream.toBytes();

      var responseString = String.fromCharCodes(responseData);
      log(responseString);
      var jsonResponse = jsonDecode(responseString);
      if (jsonResponse is Map<String, dynamic> && jsonResponse['prediction'] is List) {
        return List<int>.from(
          jsonResponse['prediction'].map((x) => x as int),
        );
      } else {
        return null;
      }
    } else {
      log('Error: ${response.statusCode}');
      return null;
    }
  }
}
