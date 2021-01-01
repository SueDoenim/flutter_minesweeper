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
      home: BoardWidget(),
    );
  }
}

class Square {
  bool isMine;
  bool isCovered;
  bool isFlagged;
  int adjacentMines;
  int adjacentFlags;

  Square(this.isMine, this.isCovered, this.isFlagged, this.adjacentMines,
      this.adjacentFlags);
}

class BoardPosition {
  int row;
  int column;
  BoardPosition(this.row, this.column);
}

class BoardWidget extends StatefulWidget {
  @override
  _BoardWidgetState createState() => _BoardWidgetState(20, 7, 20);
}

class _BoardWidgetState extends State<BoardWidget> {
  final int rowCount;
  final int columnCount;
  final int mineCount;
  int coveredCount;
  int flaggedCount;
  List<List<Square>> grid;

  List<BoardPosition> _getAdjacentSquares(int row, int column) {
    List<BoardPosition> adjacentSquares = [];
    if (row - 1 >= 0 && column - 1 >= 0) {
      adjacentSquares.add(BoardPosition(row - 1, column - 1));
    }
    if (row - 1 >= 0) {
      adjacentSquares.add(BoardPosition(row - 1, column));
    }
    if (row - 1 >= 0 && column + 1 < columnCount) {
      adjacentSquares.add(BoardPosition(row - 1, column + 1));
    }
    if (column - 1 >= 0) {
      adjacentSquares.add(BoardPosition(row, column - 1));
    }
    if (column + 1 < columnCount) {
      adjacentSquares.add(BoardPosition(row, column + 1));
    }
    if (row + 1 < rowCount && column - 1 >= 0) {
      adjacentSquares.add(BoardPosition(row + 1, column - 1));
    }
    if (row + 1 < rowCount) {
      adjacentSquares.add(BoardPosition(row + 1, column));
    }
    if (row + 1 < rowCount && column + 1 < columnCount) {
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

  _initializeGrid(row, column) {
    Random random = Random();
    for (int i = 0; i < mineCount; i++) {
      int mineRow, mineColumn;
      do {
        mineRow = random.nextInt(rowCount);
        mineColumn = random.nextInt(columnCount);
      } while ((mineRow == row && mineColumn == column) ||
          (grid[mineRow][mineColumn].isMine == true));
      grid[mineRow][mineColumn].isMine = true;
    }
    for (int i = 0; i < rowCount; i++) {
      for (int j = 0; j < columnCount; j++) {
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
    setState(() {});
  }

  _uncoverSquare(int row, int column) {
    if (grid[row][column].isCovered == false) {
      return;
    }
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
    setState(() {});
    if (coveredCount == mineCount) {
      _handleWin();
    }
  }

  _flagSquare(int row, int column) {
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
    setState(() {});
  }

  _handleWin() {
    print("yay.");
  }

  _handleLose() {
    print("u lose haha lozer");
  }

  _BoardWidgetState(this.rowCount, this.columnCount, this.mineCount) {
    this.coveredCount = rowCount * columnCount;
    this.flaggedCount = 0;
    grid = List.generate(rowCount, (i) {
      return List.generate(columnCount, (j) {
        return Square(null, true, false, 0, 0);
      }, growable: false);
    }, growable: false);
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
                (MediaQuery.of(context).size.height - 56) / rowCount),
            children: List.generate(
              rowCount,
              (row) => TableRow(
                children: List.generate(
                    columnCount,
                    (column) => SquareWidget(
                          grid[row][column],
                          onTap: () => _handleTap(row, column),
                          onLongPress: () => _handleLongPress(row, column),
                        ) /*AspectRatio(
                    aspectRatio: 1,
                    child: GestureDetector(
                      child: Container(
                          //margin: EdgeInsets.all(2),
                          color: (grid[row][column].isCovered)
                              ? Colors.green
                              : Colors.grey,
                          child: Center(
                            child: Icon(grid[row][column].isCovered
                                ? (grid[row][column].isFlagged
                                    ? Icons.outlined_flag
                                    : Icons.crop_square)
                                : (grid[row][column].isMine
                                    ? Icons.flare
                                    : (adjacencyIcons[
                                        grid[row][column].adjacentMines]))),
                          )),
                      onTap: () => _handleTap(row, column),
                      onLongPress: () => _handleLongPress(row, column),
                    ),
                  ),*/
                    ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

typedef GestureHandlerFunction = void Function(int row, int column);

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

//In case I decide to go back to grid
/*
        child: GridView.builder(
          scrollDirection: Axis.horizontal,
          physics: NeverScrollableScrollPhysics(),
          itemCount: columnCount * rowCount,
          shrinkWrap: false,
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: rowCount,
          ),
          itemBuilder: (context, position) => GestureDetector(
            child: Container(
                margin: EdgeInsets.all(2),
                color: (grid[position % columnCount][position ~/ columnCount]
                        .isCovered)
                    ? Colors.green
                    : Colors.grey,
                child: Center(
                  child: Icon(grid[position % columnCount]
                              [position ~/ columnCount]
                          .isCovered
                      ? (grid[position % columnCount][position ~/ columnCount]
                              .isFlagged
                          ? Icons.outlined_flag
                          : Icons.crop_square)
                      : (grid[position % columnCount][position ~/ columnCount]
                              .isMine
                          ? Icons.flare
                          : (adjacencyIcons[grid[position % columnCount]
                                  [position ~/ columnCount]
                              .adjacentMines]))),
                )),
            onTap: () =>
                _handleTap(position % columnCount, position ~/ columnCount),
            onLongPress: () => _handleLongPress(
                position % columnCount, position ~/ columnCount),
          ),
        ),*/
