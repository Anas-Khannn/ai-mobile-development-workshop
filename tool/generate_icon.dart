// Draws the Studyy Buddy launcher icon: a graduation cap over an open book on
// an orange gradient. Run from the project root, then generate the platform
// icons:
//
//   dart run tool/generate_icon.dart
//   dart run flutter_launcher_icons
//
// Everything is drawn at 4x and downsampled so the polygon edges come out
// smooth.
import 'dart:io';
import 'dart:math';

import 'package:image/image.dart' as img;

const int _size = 1024;
const int _scale = 4;
const int _canvas = _size * _scale;

final img.Color _cream = img.ColorRgba8(255, 248, 238, 255);
final img.Color _pageEdge = img.ColorRgba8(255, 214, 170, 255);
final img.Color _navy = img.ColorRgba8(30, 42, 68, 255);
final img.Color _navyLight = img.ColorRgba8(52, 68, 104, 255);
final img.Color _gold = img.ColorRgba8(255, 202, 40, 255);

void main() {
  Directory('assets/icon').createSync(recursive: true);

  // Full icon (legacy launchers, iOS, web, Windows): gradient + art.
  final img.Image full = _gradient();
  _drawArt(full, offset: 0, zoom: 1);
  _save(_roundCorners(full), 'assets/icon/app_icon.png');

  // Adaptive icon parts for Android 8+: the launcher masks the background and
  // only guarantees the middle ~66% of the foreground is visible.
  _save(_gradient(), 'assets/icon/app_icon_background.png');
  final img.Image foreground = _transparent();
  _drawArt(foreground, offset: _canvas * 0.17, zoom: 0.66);
  _save(foreground, 'assets/icon/app_icon_foreground.png');

  stdout.writeln('Wrote assets/icon/*.png');
}

/// Transparent pixels carry the brand orange (not black) so downsampled edges
/// fade into orange instead of leaving a dark fringe.
img.Image _transparent() {
  final img.Image image = img.Image(
    width: _canvas,
    height: _canvas,
    numChannels: 4,
  );
  img.fill(image, color: img.ColorRgba8(255, 109, 0, 0));
  return image;
}

img.Image _gradient() {
  final img.Image image = _transparent();
  for (final img.Pixel p in image) {
    // Diagonal blend from amber (top-left) to deep orange (bottom-right).
    final double t = (p.x + p.y) / (2 * _canvas);
    p
      ..r = _lerp(255, 244, t)
      ..g = _lerp(160, 81, t)
      ..b = _lerp(0, 30, t)
      ..a = 255;
  }
  return image;
}

img.Image _roundCorners(img.Image image) {
  final double r = _canvas * 0.22;
  for (final img.Pixel p in image) {
    final double cx = p.x < r
        ? r
        : (p.x > _canvas - r ? _canvas - r : p.x.toDouble());
    final double cy = p.y < r
        ? r
        : (p.y > _canvas - r ? _canvas - r : p.y.toDouble());
    final double d = sqrt(pow(p.x - cx, 2) + pow(p.y - cy, 2));
    if (d > r) {
      p.a = 0;
    }
  }
  return image;
}

/// Art is authored in a 1024x1024 space and mapped onto the canvas.
void _drawArt(img.Image image, {required double offset, required double zoom}) {
  img.Point pt(num x, num y) =>
      img.Point(offset + x * _scale * zoom, offset + y * _scale * zoom);
  void poly(List<List<num>> points, img.Color color) => img.fillPolygon(
    image,
    vertices: <img.Point>[for (final List<num> q in points) pt(q[0], q[1])],
    color: color,
  );
  void circle(num x, num y, num r, img.Color color) => img.fillCircle(
    image,
    x: (offset + x * _scale * zoom).round(),
    y: (offset + y * _scale * zoom).round(),
    radius: (r * _scale * zoom).round(),
    color: color,
  );

  // Open book: page thickness first, then the two pages with a spine gap.
  poly(<List<num>>[
    [196, 600],
    [500, 650],
    [500, 862],
    [196, 812],
  ], _pageEdge);
  poly(<List<num>>[
    [524, 650],
    [828, 600],
    [828, 812],
    [524, 862],
  ], _pageEdge);
  poly(<List<num>>[
    [210, 572],
    [500, 622],
    [500, 836],
    [210, 786],
  ], _cream);
  poly(<List<num>>[
    [524, 622],
    [814, 572],
    [814, 786],
    [524, 836],
  ], _cream);
  // Text lines on the pages.
  for (int i = 0; i < 3; i++) {
    final double dy = i * 52.0;
    poly(<List<num>>[
      [256, 640 + dy],
      [456, 674 + dy],
      [456, 690 + dy],
      [256, 656 + dy],
    ], _pageEdge);
    poly(<List<num>>[
      [568, 674 + dy],
      [768, 640 + dy],
      [768, 656 + dy],
      [568, 690 + dy],
    ], _pageEdge);
  }

  // Graduation cap: skull cap, then the mortar board on top.
  poly(<List<num>>[
    [340, 400],
    [684, 400],
    [684, 515],
    [512, 570],
    [340, 515],
  ], _navyLight);
  poly(<List<num>>[
    [512, 196],
    [812, 330],
    [512, 464],
    [212, 330],
  ], _navy);

  // Tassel: button, cord running to the right corner, then hanging down.
  circle(512, 330, 26, _gold);
  poly(<List<num>>[
    [505, 318],
    [760, 344],
    [760, 368],
    [505, 342],
  ], _gold);
  poly(<List<num>>[
    [744, 344],
    [770, 344],
    [770, 500],
    [744, 500],
  ], _gold);
  poly(<List<num>>[
    [728, 488],
    [786, 488],
    [800, 560],
    [714, 560],
  ], _gold);
}

void _save(img.Image image, String path) {
  final img.Image small = img.copyResize(
    image,
    width: _size,
    height: _size,
    interpolation: img.Interpolation.average,
  );
  File(path).writeAsBytesSync(img.encodePng(small));
}

int _lerp(int a, int b, double t) => (a + (b - a) * t).round();
