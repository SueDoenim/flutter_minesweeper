import 'dart:math';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: "Minesweeper",
      home: BoardWidget(
        rowCount: 10,
        columnCount: 7,
        mineCount: 10,
      ),
    );
  }
}

class Square {
  Square(this.isMine, this.isCovered, this.isFlagged, this.adjacentMines,
      this.adjacentFlags);
  bool? isMine;
  bool isCovered;
  bool isFlagged;
  int adjacentMines;
  int adjacentFlags;
}

class BoardPosition {
  BoardPosition(this.row, this.column);
  int row;
  int column;
}

class BoardWidget extends StatefulWidget {
  BoardWidget(
      {required this.rowCount,
      required this.columnCount,
      required this.mineCount});
  final int rowCount;
  final int columnCount;
  final int mineCount;
  @override
  _BoardWidgetState createState() =>
      _BoardWidgetState(rowCount, columnCount, mineCount);
}

class _BoardWidgetState extends State<BoardWidget> {
  _BoardWidgetState(rowCount, columnCount, mineCount)
      : coveredCount = rowCount * columnCount,
        flaggedCount = 0,
        grid = List.generate(rowCount, (row) {
          return List.generate(columnCount, (column) {
            return Square(null, true, false, 0, 0);
          });
        });

  int coveredCount;
  int flaggedCount;
  List<List<Square>> grid;

  TransformationController _controller = TransformationController();

  void _initializeGrid(int row, int column) {
    // Use a shuffled list to randomly place mines anywhere but where the
    // player clicked.
    int _squareCount = widget.rowCount * widget.columnCount;
    List<int> _randomList = List.generate(_squareCount - 1, (i) => i)
      ..shuffle()
      ..insert(row * widget.columnCount + column, _squareCount - 1);

    for (int r = 0; r < widget.rowCount; r++) {
      for (int c = 0; c < widget.columnCount; c++) {
        if (_randomList[r * widget.columnCount + c] < widget.mineCount) {
          grid[r][c].isMine = true;
          _getAdjacentSquares(r, c).forEach((position) {
            grid[position.row][position.column].adjacentMines++;
          });
        } else {
          grid[r][c].isMine = false;
        }
      }
    }
  }

  List<BoardPosition> _getAdjacentSquares(int row, int column) {
    List<BoardPosition> adjacentSquares = [];
    if (row - 1 >= 0 && column - 1 >= 0) {
      adjacentSquares.add(BoardPosition(row - 1, column - 1));
    }
    if (row - 1 >= 0) {
      adjacentSquares.add(BoardPosition(row - 1, column));
    }
    if (row - 1 >= 0 && column + 1 < widget.columnCount) {
      adjacentSquares.add(BoardPosition(row - 1, column + 1));
    }
    if (column - 1 >= 0) {
      adjacentSquares.add(BoardPosition(row, column - 1));
    }
    if (column + 1 < widget.columnCount) {
      adjacentSquares.add(BoardPosition(row, column + 1));
    }
    if (row + 1 < widget.rowCount && column - 1 >= 0) {
      adjacentSquares.add(BoardPosition(row + 1, column - 1));
    }
    if (row + 1 < widget.rowCount) {
      adjacentSquares.add(BoardPosition(row + 1, column));
    }
    if (row + 1 < widget.rowCount && column + 1 < widget.columnCount) {
      adjacentSquares.add(BoardPosition(row + 1, column + 1));
    }
    return adjacentSquares;
  }

  _handleTap(int row, int column) {
    if (grid[row][column].isMine == null) {
      _initializeGrid(row, column);
    }
    if (grid[row][column].isCovered == true &&
        grid[row][column].isFlagged == false) {
      _uncoverSquare(row, column);
    }
    if (grid[row][column].isCovered == false) {
      if (grid[row][column].adjacentFlags == grid[row][column].adjacentMines) {
        _getAdjacentSquares(row, column).forEach((position) {
          if (grid[position.row][position.column].isFlagged == false) {
            _uncoverSquare(position.row, position.column);
          }
        });
      }
    }
  }

  _handleLongPress(int row, int column) {
    _flagSquare(row, column);
  }

  _uncoverSquare(int row, int column) {
    if (grid[row][column].isCovered == false) {
      return;
    }
    setState(() {
      grid[row][column].isCovered = false;
      coveredCount--;
      if (grid[row][column].isMine == true) {
        _handleLose();
      }
      if (grid[row][column].adjacentMines == 0) {
        _getAdjacentSquares(row, column).forEach((position) {
          if (grid[position.row][position.column].isCovered == true &&
              grid[position.row][position.column].isFlagged == false) {
            _uncoverSquare(position.row, position.column);
          }
        });
      }
      if (coveredCount == widget.mineCount) {
        _handleWin();
      }
    });
  }

  _flagSquare(int row, int column) {
    setState(() {
      if (grid[row][column].isFlagged == false) {
        grid[row][column].isFlagged = true;
        flaggedCount++;
        _getAdjacentSquares(row, column).forEach(
            (position) => grid[position.row][position.column].adjacentFlags++);
      } else {
        grid[row][column].isFlagged = false;
        flaggedCount--;
        _getAdjacentSquares(row, column).forEach(
            (position) => grid[position.row][position.column].adjacentFlags--);
      }
    });
  }

  _handleWin() {
    print("yay.");
  }

  _handleLose() {
    print("u lose haha lozer");
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(child: LayoutBuilder(builder: (context, constraints) {
      final double squareWidth = min(constraints.maxHeight / widget.rowCount,
          constraints.maxWidth / widget.columnCount);
      _controller.addListener(() {
        // To keep the user from zooming into the margins, we use a custom
        // TransformationController for the InteractiveViewer.
        // The controller is a 4x4 matrix (column major) of the form
        // [S 0 0 X]
        // [0 S 0 Y]
        // [0 0 S 0]
        // [0 0 0 1]
        // where S is the scale and X and Y are translations.
        if (widget.rowCount * squareWidth < constraints.maxHeight) {
          // There are margins on the top and bottom.

          // Keep the margins equal, until the user has zoomed in far enough
          // that there are none. Then, don't allow the user to pan into the
          // top margin.
          _controller.value[13] = min(
              _controller.value[13],
              max(
                  0.5 * (1 - _controller.value[0]) * constraints.maxHeight,
                  -0.5 *
                      _controller.value[0] *
                      (constraints.maxHeight - squareWidth * widget.rowCount)));

          // Same for bottom margin.
          _controller.value[13] = max(
              _controller.value[13],
              min(
                  0.5 * (1 - _controller.value[0]) * constraints.maxHeight,
                  -0.5 *
                      (_controller.value[0] * widget.rowCount * squareWidth +
                          constraints.maxHeight * (_controller.value[0] - 2))));
        } else {
          // There are margins on the left and right.

          // Same for left margin.
          _controller.value[12] = min(
              _controller.value[12],
              max(
                  0.5 * (1 - _controller.value[0]) * constraints.maxWidth,
                  -0.5 *
                      _controller.value[0] *
                      (constraints.maxWidth -
                          squareWidth * widget.columnCount)));

          // Same for right margin.
          _controller.value[12] = max(
              _controller.value[12],
              min(
                  0.5 * (1 - _controller.value[0]) * constraints.maxWidth,
                  -0.5 *
                      (_controller.value[0] * widget.columnCount * squareWidth +
                          constraints.maxWidth * (_controller.value[0] - 2))));
        }
      });
      return InteractiveViewer(
        maxScale: min(widget.rowCount, widget.columnCount).toDouble(),
        minScale: 1,
        transformationController: _controller,
        child: Center(
          child: Table(
            defaultColumnWidth: FixedColumnWidth(squareWidth),
            children: List.generate(
              widget.rowCount,
              (row) => TableRow(
                children: List.generate(
                    widget.columnCount,
                    (column) => SquareWidget(
                          grid[row][column],
                          onTap: () => _handleTap(row, column),
                          onLongPress: () => _handleLongPress(row, column),
                        )),
              ),
            ),
          ),
        ),
      );
    }));
  }
}

class SquareWidget extends StatefulWidget {
  SquareWidget(this.data, {required this.onTap, required this.onLongPress});

  final Square data;
  final Function onTap;
  final Function onLongPress;

  @override
  _SquareWidgetState createState() => _SquareWidgetState();
}

class _SquareWidgetState extends State<SquareWidget> {
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
            color: (widget.data.isCovered) ? Colors.green : Colors.grey,
            child: Center(
              child: Icon(widget.data.isCovered
                  ? (widget.data.isFlagged
                      ? Icons.outlined_flag
                      : Icons.crop_square)
                  : ((widget.data.isMine ?? false)
                      ? Icons.flare
                      : (adjacencyIcons[widget.data.adjacentMines]))),
            )),
        onTap: widget.onTap as void Function()?,
        onLongPress: widget.onLongPress as void Function()?,
        onSecondaryTap: widget.onLongPress as void Function()?,
      ),
    );
  }
}
