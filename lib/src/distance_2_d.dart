import 'dart:math';
import 'dart:ui';

double distance2D(Offset p, Offset q) {
  return sqrt(pow(p.dx - q.dx, 2) + pow(p.dy - q.dy, 2));
}
