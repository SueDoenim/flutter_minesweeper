import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'dart:math';

import 'package:universal_html/html.dart' as html;

import 'game.dart';

void main() {
  // Disable right click context menu.
  html.window.onContextMenu.listen((html.MouseEvent e) => e.preventDefault());
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Minesweeper',
      home: GameWidget(rowCount: 10, columnCount: 7, mineCount: 10),
    );
  }
}

class BoardWidget extends StatefulWidget {
  BoardWidget(this.grid, this.handleTap, this.handleLongPress);

  final List<List<Square>> grid;
  final void Function(int, int) handleTap;
  final void Function(int, int) handleLongPress;

  @override
  _BoardWidgetState createState() => _BoardWidgetState();
}

class _BoardWidgetState extends State<BoardWidget> {
  late TransformationController _controller;
  late VoidCallback _controllerListener;

  VoidCallback _createListener(
      BuildContext context, BoxConstraints constraints) {
    int rowCount = widget.grid.length;
    int columnCount = widget.grid[0].length;
    double squareWidth = min(
      constraints.maxHeight / rowCount,
      constraints.maxWidth / columnCount,
    );
    double boardWidth = columnCount * squareWidth;
    double boardHeight = rowCount * squareWidth;
    return () {
      // To keep the user from zooming into the margins, we use a custom
      // TransformationController for the InteractiveViewer.
      // The controller is a 4x4 matrix (column major) of the form
      // [S 0 0 X]
      // [0 S 0 Y]
      // [0 0 S 0]
      // [0 0 0 1]
      // where S is the scale and X and Y are translations.
      if (boardHeight < constraints.maxHeight) {
        // There are margins on the top and bottom.

        // Keep the margins equal, until the user has zoomed in far enough
        // that there are none. Then, don't allow the user to pan into the
        // top margin.
        _controller.value[13] = min(
          _controller.value[13],
          max(
            0.5 * (1 - _controller.value[0]) * constraints.maxHeight,
            -0.5 * _controller.value[0] * (constraints.maxHeight - boardHeight),
          ),
        );

        // Same for bottom margin.
        _controller.value[13] = max(
          _controller.value[13],
          min(
            0.5 * (1 - _controller.value[0]) * constraints.maxHeight,
            -0.5 *
                (_controller.value[0] * boardHeight +
                    constraints.maxHeight * (_controller.value[0] - 2)),
          ),
        );
      } else {
        // There are margins on the left and right.

        // Same for left margin.
        _controller.value[12] = min(
          _controller.value[12],
          max(
            0.5 * (1 - _controller.value[0]) * constraints.maxWidth,
            -0.5 * _controller.value[0] * (constraints.maxWidth - boardWidth),
          ),
        );

        // Same for right margin.
        _controller.value[12] = max(
          _controller.value[12],
          min(
            0.5 * (1 - _controller.value[0]) * constraints.maxWidth,
            -0.5 *
                (_controller.value[0] * boardWidth +
                    constraints.maxWidth * (_controller.value[0] - 2)),
          ),
        );
      }
    };
  }

  @override
  void initState() {
    super.initState();
    _controller = TransformationController();
  }

  @override
  void didUpdateWidget(covariant BoardWidget oldWidget) {
    _controller.removeListener(_controllerListener);
    super.didUpdateWidget(oldWidget);
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, constraints) {
      int rowCount = widget.grid.length;
      int columnCount = widget.grid[0].length;
      double squareWidth = min(
        constraints.maxHeight / rowCount,
        constraints.maxWidth / columnCount,
      );
      _controllerListener = _createListener(context, constraints);
      _controller.addListener(_controllerListener);
      return InteractiveViewer(
        maxScale: min(rowCount, columnCount).toDouble(),
        minScale: 1,
        transformationController: _controller,
        child: Center(
          child: Table(
            defaultColumnWidth: FixedColumnWidth(squareWidth),
            children: List.generate(
              rowCount,
              (r) => TableRow(
                children: List.generate(
                    columnCount,
                    (c) => SquareWidget(
                          data: widget.grid[r][c],
                          onTap: () => widget.handleTap(r, c),
                          onLongPress: () => widget.handleLongPress(r, c),
                        )),
              ),
            ),
          ),
        ),
      );
    });
  }
}

class SquareWidget extends StatelessWidget {
  SquareWidget({
    required this.data,
    required this.onTap,
    required this.onLongPress,
  });

  final Square data;
  final void Function() onTap;
  final void Function() onLongPress;

  static const List<IconData> adjacencyIcons = [
    Icons.filter_none,
    Icons.filter_1,
    Icons.filter_2,
    Icons.filter_3,
    Icons.filter_4,
    Icons.filter_5,
    Icons.filter_6,
    Icons.filter_7,
    Icons.filter_8,
  ];

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: 1,
      child: GestureDetector(
        child: Container(
            color: (data.isCovered) ? Colors.green : Colors.grey,
            child: Center(
              child: Icon(data.isCovered
                  ? (data.isFlagged ? Icons.outlined_flag : Icons.crop_square)
                  : ((data.isMine)
                      ? Icons.flare
                      : (adjacencyIcons[data.adjacentMines]))),
            )),
        onTap: onTap,
        onLongPress: onLongPress,
        onSecondaryTap: onLongPress,
      ),
    );
  }
}

class TopPanelWidget extends StatelessWidget {
  TopPanelWidget({
    required this.mineCount,
    required this.flaggedCount,
    required this.restart,
    required this.message,
  });

  final int mineCount;
  final int flaggedCount;
  final void Function() restart;
  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.grey,
      child: Row(
        children: [
          Icon(
            Icons.flare,
            color: Colors.amber,
          ),
          Text(
            (mineCount - flaggedCount).toString(),
          ),
          Expanded(
            child: Text(
              message,
              textAlign: TextAlign.center,
            ),
          ),
          GestureDetector(
            child: Icon(
              Icons.refresh,
              color: Colors.amber,
            ),
            onTap: () => restart(),
          ),
        ],
      ),
    );
  }
}
