import 'dart:math';
import 'dart:ui';

/// [ScreenParameters] holds the screen and preview sizes

class ScreenParameters {
  static late Size screenSize;
  static late Size previewSize;

  static double ratio =
      max(previewSize.height, previewSize.width) / min(previewSize.height, previewSize.width);

  static Size screenPreviewSize = Size(screenSize.width, screenSize.width * ratio);
}
