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
  bool isMine;
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
      {@required this.rowCount,
      @required this.columnCount,
      @required this.mineCount});
  final int rowCount;
  final int columnCount;
  final int mineCount;
  @override
  _BoardWidgetState createState() =>
      _BoardWidgetState(rowCount, columnCount, mineCount);
}

class _BoardWidgetState extends State<BoardWidget> {
  _BoardWidgetState(rowCount, columnCount, mineCount) {
    this.coveredCount = rowCount * columnCount;
    this.flaggedCount = 0;
    grid = List.generate(rowCount, (i) {
      return List.generate(columnCount, (j) {
        return Square(null, true, false, 0, 0);
      }, growable: false);
    }, growable: false);
  }

  int coveredCount;
  int flaggedCount;
  List<List<Square>> grid;

  _initializeGrid(int row, int column) {
    setState(() {
      Random random = Random();
      for (int i = 0; i < widget.mineCount; i++) {
        int mineRow, mineColumn;
        do {
          mineRow = random.nextInt(widget.rowCount);
          mineColumn = random.nextInt(widget.columnCount);
        } while ((mineRow == row && mineColumn == column) ||
            (grid[mineRow][mineColumn].isMine == true));
        grid[mineRow][mineColumn].isMine = true;
      }
      for (int i = 0; i < widget.rowCount; i++) {
        for (int j = 0; j < widget.columnCount; j++) {
          if (grid[i][j].isMine == null) {
            grid[i][j].isMine = false;
          }
          _getAdjacentSquares(i, j).forEach((position) {
            if (grid[position.row][position.column].isMine == true) {
              grid[i][j].adjacentMines++;
            }
          });
        }
      }
    });
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
    return SafeArea(
      child: Center(
        child: InteractiveViewer(
          maxScale: 10,
          minScale: 0.5,
          child: Table(
            defaultColumnWidth: FixedColumnWidth(
                (MediaQuery.of(context).size.height - 56) / widget.rowCount),
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
      ),
    );
  }
}

class SquareWidget extends StatefulWidget {
  SquareWidget(this.data, {this.onTap, this.onLongPress});

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
            //margin: EdgeInsets.all(2),
            color: (widget.data.isCovered) ? Colors.green : Colors.grey,
            child: Center(
              child: Icon(widget.data.isCovered
                  ? (widget.data.isFlagged
                      ? Icons.outlined_flag
                      : Icons.crop_square)
                  : (widget.data.isMine
                      ? Icons.flare
                      : (adjacencyIcons[widget.data.adjacentMines]))),
            )),
        onTap: widget.onTap,
        onLongPress: widget.onLongPress,
      ),
    );
  }
}
