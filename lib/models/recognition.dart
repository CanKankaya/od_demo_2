import 'package:flutter/cupertino.dart';
import 'package:od_demo_2/constants.dart';

import 'package:od_demo_2/models/screen_params.dart';

class Recognition {
  final int _id;
  final String _lbl;
  final double _sc;
  final Rect _loc;

  Recognition(this._id, this._lbl, this._sc, this._loc);

  int get id => _id;
  String get label => _lbl;
  double get score => _sc;
  Rect get location => _loc;

  Rect get renderLocation {
    final double scaleX = ScreenParameters.screenPreviewSize.width / inputSize;
    final double scaleY = ScreenParameters.screenPreviewSize.height / inputSize;
    return Rect.fromLTWH(
      location.left * scaleX,
      location.top * scaleY,
      location.width * scaleX,
      location.height * scaleY,
    );
  }

  @override
  String toString() {
    return 'Recognition(id: $id, label: $label, score: $score, location: $location)';
  }
}
