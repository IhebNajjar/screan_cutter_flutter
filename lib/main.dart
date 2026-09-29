import 'dart:math' as math;

import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import 'package:flutter/material.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Screen Cutter',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xffef8354)),
        scaffoldBackgroundColor: const Color(0xfff7f3ed),
      ),
      home: const MyHomePage(),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key});

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  final List<_Tile> _tiles = <_Tile>[];
  final List<_CanvasSnapshot> _undoStack = <_CanvasSnapshot>[];
  final List<_CanvasSnapshot> _redoStack = <_CanvasSnapshot>[];
  int _cuts = 0;
  double _borderWidth = 1;
  double _cornerRadius = 0;
  Color _selectedColor = const Color(0xff4f6d7a);
  bool _randomNextColor = false;
  bool _randomColors = false;

  Color get _color {
    return _randomColors ? _randomColor() : _shadeForTile(_tiles.length);
  }

  Color _shadeForTile(int index) {
    final HSLColor base = HSLColor.fromColor(_selectedColor);
    final double lightness = (0.42 + (index % 5) * 0.08).clamp(0.0, 0.86);
    return base
        .withSaturation((base.saturation * 0.9).clamp(0.35, 1.0))
        .withLightness(lightness)
        .toColor();
  }

  void _selectColor(Color color) {
    if (color == _selectedColor && !_randomNextColor) return;
    _recordChange();
    setState(() {
      _selectedColor = _randomNextColor ? _randomColor() : color;
      _randomNextColor = false;
      _randomColors = false;
      for (int index = 0; index < _tiles.length; index++) {
        _tiles[index] = _Tile(_tiles[index].rect, _shadeForTile(index));
      }
    });
  }

  Future<void> _pickCustomColor() async {
    final Color? color = await showDialog<Color>(
      context: context,
      builder: (BuildContext context) {
        Color pickedColor = _selectedColor;
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setDialogState) {
            return AlertDialog(
              title: const Text('Choose a color'),
              content: SingleChildScrollView(
                child: ColorPicker(
                  pickerColor: pickedColor,
                  onColorChanged: (Color color) =>
                      setDialogState(() => pickedColor = color),
                  enableAlpha: false,
                  pickerAreaHeightPercent: 0.75,
                ),
              ),
              actions: <Widget>[
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Cancel'),
                ),
                FilledButton(
                  onPressed: () => Navigator.of(context).pop(pickedColor),
                  child: const Text('Choose'),
                ),
              ],
            );
          },
        );
      },
    );
    if (color != null) _selectColor(color);
  }

  _CanvasSnapshot _snapshot() => _CanvasSnapshot(
        _tiles.map((tile) => _Tile(tile.rect, tile.color)).toList(),
        _cuts,
        _selectedColor,
        _randomColors,
        _randomNextColor,
      );

  void _recordChange() {
    _undoStack.add(_snapshot());
    _redoStack.clear();
  }

  void _restore(_CanvasSnapshot snapshot) {
    _tiles
      ..clear()
      ..addAll(snapshot.tiles);
    _cuts = snapshot.cuts;
    _selectedColor = snapshot.selectedColor;
    _randomColors = snapshot.randomColors;
    _randomNextColor = snapshot.randomNextColor;
  }

  void _undo() {
    if (_undoStack.isEmpty) return;
    setState(() {
      _redoStack.add(_snapshot());
      _restore(_undoStack.removeLast());
    });
  }

  void _redo() {
    if (_redoStack.isEmpty) return;
    setState(() {
      _undoStack.add(_snapshot());
      _restore(_redoStack.removeLast());
    });
  }

  void _cutAt(Offset point, Size size) {
    if (_tiles.isEmpty) {
      _recordChange();
      _tiles.add(_Tile(Rect.fromLTWH(0, 0, size.width, size.height), _color));
    }

    final int tileIndex =
        _tiles.lastIndexWhere((tile) => tile.rect.contains(point));
    if (tileIndex == -1) return;

    final Rect tile = _tiles[tileIndex].rect;
    if (tile.width < 2 && tile.height < 2) return;
    if (_tiles.length > 1 || tileIndex != 0) _recordChange();

    final bool splitVertically = tile.width >= tile.height;
    final double cut = splitVertically ? tile.center.dx : tile.center.dy;

    final List<_Tile> replacement;
    if (splitVertically) {
      replacement = <_Tile>[
        _Tile(
          Rect.fromLTRB(tile.left, tile.top, cut, tile.bottom),
          _randomColors ? _randomColor() : _shadeForTile(tileIndex),
        ),
        _Tile(
          Rect.fromLTRB(cut, tile.top, tile.right, tile.bottom),
          _randomColors ? _randomColor() : _shadeForTile(tileIndex + 1),
        ),
      ];
    } else {
      replacement = <_Tile>[
        _Tile(
          Rect.fromLTRB(tile.left, tile.top, tile.right, cut),
          _randomColors ? _randomColor() : _shadeForTile(tileIndex),
        ),
        _Tile(
          Rect.fromLTRB(tile.left, cut, tile.right, tile.bottom),
          _randomColors ? _randomColor() : _shadeForTile(tileIndex + 1),
        ),
      ];
    }

    setState(() {
      _tiles
        ..removeAt(tileIndex)
        ..insertAll(tileIndex, replacement);
      _cuts++;
    });
  }

  void _reset() {
    if (_tiles.isEmpty) return;
    _recordChange();
    setState(() {
      _tiles.clear();
      _cuts = 0;
    });
  }

  Color _randomColor() {
    final math.Random random = math.Random();
    return HSLColor.fromAHSL(
      1,
      random.nextDouble() * 360,
      0.7 + random.nextDouble() * 0.2,
      0.4 + random.nextDouble() * 0.2,
    ).toColor();
  }

  void _randomizeColors() {
    _recordChange();
    setState(() {
      _randomColors = true;
      _randomNextColor = false;
      _selectedColor = _randomColor();
      for (int index = 0; index < _tiles.length; index++) {
        _tiles[index] = _Tile(_tiles[index].rect, _randomColor());
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Screen Cutter'),
        actions: <Widget>[
          Center(child: Text('Cuts: $_cuts')),
          IconButton(
            onPressed: _undoStack.isEmpty ? null : _undo,
            tooltip: 'Undo',
            icon: const Icon(Icons.undo),
          ),
          IconButton(
            onPressed: _redoStack.isEmpty ? null : _redo,
            tooltip: 'Redo',
            icon: const Icon(Icons.redo),
          ),
          IconButton(
            onPressed: _reset,
            tooltip: 'Reset canvas',
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: LayoutBuilder(
        builder: (BuildContext context, BoxConstraints constraints) {
          final Size size = Size(constraints.maxWidth, constraints.maxHeight);
          return GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTapDown: (TapDownDetails details) =>
                _cutAt(details.localPosition, size),
            child: CustomPaint(
              painter: _CutterPainter(
                _tiles,
                borderWidth: _borderWidth,
                cornerRadius: _cornerRadius,
              ),
              child: const SizedBox.expand(),
            ),
          );
        },
      ),
      drawer: Drawer(
        child: SafeArea(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 28),
            children: <Widget>[
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: <Widget>[
                  Text('Canvas settings', style: Theme.of(context).textTheme.titleLarge),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    tooltip: 'Close settings',
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Text('Border width: ${_borderWidth.toStringAsFixed(1)}'),
              Slider(
                value: _borderWidth,
                min: 0.5,
                max: 8,
                divisions: 15,
                label: _borderWidth.toStringAsFixed(1),
                onChanged: (double value) => setState(() => _borderWidth = value),
              ),
              const SizedBox(height: 12),
              Text('Corner roundness: ${_cornerRadius.toStringAsFixed(0)}'),
              Slider(
                value: _cornerRadius,
                min: 0,
                max: 32,
                divisions: 16,
                label: _cornerRadius.toStringAsFixed(0),
                onChanged: (double value) => setState(() => _cornerRadius = value),
              ),
              const SizedBox(height: 20),
              Text('Tile color', style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 12),
              OutlinedButton.icon(
                onPressed: _pickCustomColor,
                icon: const Icon(Icons.colorize),
                label: const Text('Open color picker'),
              ),
              const SizedBox(height: 10),
              OutlinedButton.icon(
                onPressed: _randomizeColors,
                icon: Icon(_randomColors ? Icons.check : Icons.shuffle),
                label: Text(
                  _randomColors ? 'Random colors on' : 'Randomize colors',
                ),
              ),
              const SizedBox(height: 14),
              Text(
                'Choose any hue, saturation, and brightness. New cuts use lighter shades of your chosen color.',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Tile {
  const _Tile(this.rect, this.color);

  final Rect rect;
  final Color color;
}

class _CanvasSnapshot {
  const _CanvasSnapshot(
    this.tiles,
    this.cuts,
    this.selectedColor,
    this.randomColors,
    this.randomNextColor,
  );

  final List<_Tile> tiles;
  final int cuts;
  final Color selectedColor;
  final bool randomColors;
  final bool randomNextColor;
}

class _CutterPainter extends CustomPainter {
  const _CutterPainter(
    this.tiles, {
    required this.borderWidth,
    required this.cornerRadius,
  });

  final List<_Tile> tiles;
  final double borderWidth;
  final double cornerRadius;

  @override
  void paint(Canvas canvas, Size size) {
    if (tiles.isEmpty) {
      final Paint background = Paint()..color = const Color(0xffeee8df);
      canvas.drawRect(Offset.zero & size, background);
      return;
    }

    final Paint fill = Paint();
    final Paint border = Paint()..style = PaintingStyle.stroke;
    for (final _Tile tile in tiles) {
      final RRect roundedTile = RRect.fromRectAndRadius(
        tile.rect,
        Radius.circular(math.min(cornerRadius, tile.rect.shortestSide / 2)),
      );
      fill.color = tile.color;
      border
        ..color = HSLColor.fromColor(tile.color)
            .withLightness((HSLColor.fromColor(tile.color).lightness + 0.25)
                .clamp(0.0, 1.0))
            .toColor()
        ..strokeWidth = math.min(borderWidth, size.shortestSide / 100);
      canvas.drawRect(tile.rect, fill);
      canvas.drawRRect(roundedTile, border);
    }
  }

  @override
  bool shouldRepaint(covariant _CutterPainter oldDelegate) =>
      oldDelegate.tiles != tiles ||
      oldDelegate.borderWidth != borderWidth ||
      oldDelegate.cornerRadius != cornerRadius;
}
