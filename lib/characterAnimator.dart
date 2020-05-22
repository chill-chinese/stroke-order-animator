import 'dart:convert';

import 'package:flutter/widgets.dart';

class CharacterAnimator extends StatelessWidget {
  final String strokeOrder;

  CharacterAnimator(this.strokeOrder);


  @override
  Widget build(BuildContext context) {
    var parsedJson = json.decode(strokeOrder.replaceAll("'", '"'));

    return Text('Number of strokes: ' + parsedJson['strokes'].length.toString() + '\n');
  }
}