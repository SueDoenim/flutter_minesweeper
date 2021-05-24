import 'package:flutter/widgets.dart';
import 'package:flutter/material.dart';

import 'dart:math';

import 'game.dart';

class BoardWidget extends StatefulWidget {
  BoardWidget(this.grid, this.gameWon, this.handleTap, this.handleLongPress);

  final List<List<Square>> grid;
  final bool? gameWon;
  final void Function(int, int)? handleTap;
  final void Function(int, int)? handleLongPress;

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
        child: GridWidget(
          grid: widget.grid,
          gameWon: widget.gameWon,
          squareWidth: squareWidth,
          handleTap: widget.handleTap,
          handleLongPress: widget.handleLongPress,
        ),
      );
    });
  }
}

class GridWidget extends StatelessWidget {
  GridWidget({
    required this.grid,
    required this.squareWidth,
    required this.gameWon,
    required this.handleTap,
    required this.handleLongPress,
  })   : rowCount = grid.length,
        columnCount = grid[0].length;
  final List<List<Square>> grid;
  final double squareWidth;
  final bool? gameWon;
  final void Function(int, int)? handleTap;
  final void Function(int, int)? handleLongPress;
  final int rowCount;
  final int columnCount;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      child: Center(
        child: Table(
          defaultColumnWidth: FixedColumnWidth(squareWidth),
          children: List.generate(rowCount, (r) {
            return TableRow(
              children: List.generate(columnCount, (c) {
                return SquareWidget(
                  data: grid[r][c],
                  gameWon: gameWon,
                  onTap: (handleTap != null) ? () => handleTap!(r, c) : null,
                  onLongPress: (handleLongPress != null)
                      ? () => handleLongPress!(r, c)
                      : null,
                );
              }),
            );
          }),
        ),
      ),
    );
  }
}

class SquareWidget extends StatelessWidget {
  SquareWidget({
    required this.data,
    required this.gameWon,
    required this.onTap,
    required this.onLongPress,
  });

  final Square data;
  final bool? gameWon;
  final void Function()? onTap;
  final void Function()? onLongPress;

  @override
  Widget build(BuildContext context) {
    Widget? icon;
    if (data.isCovered) {
      if (gameWon == null) {
        icon = data.isFlagged ? Icon(Icons.flag, color: Colors.amber) : null;
      } else {
        if (data.isFlagged && data.isMine!) {
          icon = GridView.count(
            crossAxisCount: 2,
            physics: NeverScrollableScrollPhysics(),
            children: [
              SizedBox.shrink(),
              Icon(Icons.flag, color: Colors.amber),
              Icon(Icons.flare, color: Colors.amber),
              SizedBox.shrink(),
            ],
          );
        } else if (data.isFlagged) {
          icon = Icon(Icons.flag, color: Colors.amber);
        } else if (data.isMine!) {
          icon = Icon(Icons.flare, color: Colors.amber);
        }
      }
    } else {
      if (data.isMine!) {
        icon = Icon(Icons.flare, color: Colors.amber);
      } else {
        icon =
            data.adjacentMines > 0 ? Text(data.adjacentMines.toString()) : null;
      }
    }
    return AspectRatio(
      aspectRatio: 1,
      child: GestureDetector(
        child: Container(
            margin: EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: (data.isCovered) ? Colors.blue : Colors.white,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Center(
              child: icon,
            )),
        onTap: onTap,
        onLongPress: onLongPress,
        onSecondaryTap: onLongPress,
      ),
    );
  }
}

class PanelWidget extends StatelessWidget {
  PanelWidget({
    required this.mineCount,
    required this.flaggedCount,
    required this.restart,
    required this.gameWon,
  });

  final int mineCount;
  final int flaggedCount;
  final void Function() restart;
  final bool? gameWon;

  @override
  Widget build(BuildContext context) {
    String message;
    if (gameWon == null) {
      message = '';
    } else {
      message = gameWon! ? 'You win!' : 'You lose!';
    }
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
              style: TextStyle(fontSize: 32),
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
