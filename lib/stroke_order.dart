import 'dart:convert';

import 'package:flutter/rendering.dart';
import 'package:stroke_order_animator/download_stroke_order.dart';
import 'package:svg_path_parser/svg_path_parser.dart';

/// Represents the stroke order of a character.
/// A stroke order consists of the path information describing the outline of
/// all strokes ([strokeOutlines]), a list of points describing the median of
/// each stroke ([medians]), and a list of indices of the strokes that are part
/// of the radical of the character ([radicalStrokeIndices]).
/// The number of strokes is stored in [nStrokes].
///
/// A JSON string retrieved via [downloadStrokeOrder] can be passed directly to
/// the constructor.
class StrokeOrder {
  StrokeOrder(String strokeOrderJson) {
    final parsedJson = _parseJson(strokeOrderJson);

    strokeOutlines = _parseStrokeOutlines(parsedJson);
    medians = _parseMedians(parsedJson);
    radicalStrokeIndices = _parseRadicalStrokeIndices(parsedJson);
    nStrokes = strokeOutlines.length;

    if (medians.length != strokeOutlines.length) {
      throw const FormatException(
        'Number of strokes and medians not equal in stroke order JSON',
      );
    }
  }

  late final List<Path> strokeOutlines;
  late final List<List<Offset>> medians;
  late final List<int> radicalStrokeIndices;
  late final int nStrokes;

  Map<String, dynamic> _parseJson(String strokeOrderJson) {
    try {
      return json.decode(strokeOrderJson.replaceAll("'", '"'))
          as Map<String, dynamic>;
    } catch (error) {
      throw const FormatException('Invalid JSON string for stroke order');
    }
  }

  List<Path> _parseStrokeOutlines(Map<String, dynamic> parsedJson) {
    if (!parsedJson.containsKey('strokes')) {
      throw const FormatException('Missing strokes in stroke order JSON');
    }

    try {
      final rawStrokeOutlines =
          List.castFrom<dynamic, String>(parsedJson['strokes'] as List);
      return List.generate(
        rawStrokeOutlines.length,
        (index) => parseSvgPath(rawStrokeOutlines[index]).transform(
          // Transformation according to the makemeahanzi documentation
          Matrix4(1, 0, 0, 0, 0, -1, 0, 0, 0, 0, 1, 0, 0, 900, 0, 1).storage,
        ),
      );
    } catch (e) {
      throw const FormatException('Invalid strokes in stroke order JSON');
    }
  }

  List<List<Offset>> _parseMedians(Map<String, dynamic> parsedJson) {
    if (!parsedJson.containsKey('medians')) {
      throw const FormatException('Missing medians in stroke order JSON');
    }

    try {
      final rawMedians = parsedJson['medians'] as List;

      return rawMedians
          .map(
            (medianPoints) => (medianPoints as List).map<Offset>((point) {
              point = point as List;
              return Offset(
                (point[0] as int).toDouble(),
                ((point[1] as int) * -1 + 900).toDouble(),
              );
            }).toList(),
          )
          .toList();
    } catch (e) {
      throw const FormatException('Invalid medians in stroke order JSON');
    }
  }

  List<int> _parseRadicalStrokeIndices(Map<String, dynamic> parsedJson) {
    if (!parsedJson.containsKey('radStrokes')) {
      return [];
    }

    try {
      return List<int>.from(parsedJson['radStrokes'] as List);
    } catch (e) {
      throw const FormatException(
        'Invalid radical stroke indices in stroke order JSON',
      );
    }
  }
}
