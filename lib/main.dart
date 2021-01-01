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
      home: MinesweeperBoard(),
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
  int column;
  int row;
  BoardPosition(this.column, this.row);
}

class MinesweeperBoard extends StatefulWidget {
  @override
  _MinesweeperBoardState createState() => _MinesweeperBoardState(7, 20, 20);
}

class _MinesweeperBoardState extends State<MinesweeperBoard> {
  final int columnCount;
  final int rowCount;
  final int mineCount;
  int coveredCount;
  int flaggedCount;
  List<List<Square>> grid;

  List<BoardPosition> _getAdjacentSquares(int column, int row) {
    List<BoardPosition> adjacentSquares = [];
    if (column - 1 >= 0 && row - 1 >= 0) {
      adjacentSquares.add(BoardPosition(column - 1, row - 1));
    }
    if (row - 1 >= 0) {
      adjacentSquares.add(BoardPosition(column, row - 1));
    }
    if (column + 1 < columnCount && row - 1 >= 0) {
      adjacentSquares.add(BoardPosition(column + 1, row - 1));
    }
    if (column - 1 >= 0) {
      adjacentSquares.add(BoardPosition(column - 1, row));
    }
    if (column + 1 < columnCount) {
      adjacentSquares.add(BoardPosition(column + 1, row));
    }
    if (column - 1 >= 0 && row + 1 < rowCount) {
      adjacentSquares.add(BoardPosition(column - 1, row + 1));
    }
    if (row + 1 < rowCount) {
      adjacentSquares.add(BoardPosition(column, row + 1));
    }
    if (column + 1 < columnCount && row + 1 < rowCount) {
      adjacentSquares.add(BoardPosition(column + 1, row + 1));
    }
    return adjacentSquares;
  }

  _handleTap(int column, int row) {
    if (grid[column][row].isMine == null) {
      _initializeGrid(column, row);
    }
    if (grid[column][row].isCovered == true &&
        grid[column][row].isFlagged == false) {
      _uncoverSquare(column, row);
    }
    if (grid[column][row].isCovered == false) {
      if (grid[column][row].adjacentFlags == grid[column][row].adjacentMines) {
        _getAdjacentSquares(column, row).forEach((position) {
          if (grid[position.column][position.row].isFlagged == false) {
            _uncoverSquare(position.column, position.row);
          }
        });
      }
    }
  }

  _handleLongPress(int column, int row) {
    _flagSquare(column, row);
  }

  _initializeGrid(column, row) {
    Random random = Random();
    for (int i = 0; i < mineCount; i++) {
      int mineColumn, mineRow;
      do {
        mineColumn = random.nextInt(columnCount);
        mineRow = random.nextInt(rowCount);
      } while ((mineColumn == column && mineRow == row) ||
          (grid[mineColumn][mineRow].isMine == true));
      grid[mineColumn][mineRow].isMine = true;
    }
    for (int i = 0; i < columnCount; i++) {
      for (int j = 0; j < rowCount; j++) {
        if (grid[i][j].isMine == null) {
          grid[i][j].isMine = false;
        }
        _getAdjacentSquares(i, j).forEach((position) {
          if (grid[position.column][position.row].isMine == true) {
            grid[i][j].adjacentMines++;
          }
        });
      }
    }
    setState(() {});
  }

  _uncoverSquare(int column, int row) {
    if (grid[column][row].isCovered == false) {
      return;
    }
    grid[column][row].isCovered = false;
    coveredCount--;
    if (grid[column][row].isMine == true) {
      _handleLose();
    }
    if (grid[column][row].adjacentMines == 0) {
      _getAdjacentSquares(column, row).forEach((position) {
        if (grid[position.column][position.row].isCovered == true &&
            grid[position.column][position.row].isFlagged == false) {
          _uncoverSquare(position.column, position.row);
        }
      });
    }
    setState(() {});
    if (coveredCount == mineCount) {
      _handleWin();
    }
  }

  _flagSquare(int column, int row) {
    if (grid[column][row].isFlagged == false) {
      grid[column][row].isFlagged = true;
      flaggedCount++;
      _getAdjacentSquares(column, row).forEach(
          (position) => grid[position.column][position.row].adjacentFlags++);
    } else {
      grid[column][row].isFlagged = false;
      flaggedCount--;
      _getAdjacentSquares(column, row).forEach(
          (position) => grid[position.column][position.row].adjacentFlags--);
    }
    setState(() {});
  }

  _handleWin() {
    print("yay.");
  }

  _handleLose() {
    print("u lose haha lozer");
  }

  _MinesweeperBoardState(this.columnCount, this.rowCount, this.mineCount) {
    this.coveredCount = columnCount * rowCount;
    this.flaggedCount = 0;
    grid = List.generate(columnCount, (i) {
      return List.generate(rowCount, (j) {
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
                    (column) => BoardSquare(
                          grid[column][row],
                          onTap: () => _handleTap(column, row),
                          onLongPress: () => _handleLongPress(column, row),
                        ) /*AspectRatio(
                    aspectRatio: 1,
                    child: GestureDetector(
                      child: Container(
                          //margin: EdgeInsets.all(2),
                          color: (grid[column][row].isCovered)
                              ? Colors.green
                              : Colors.grey,
                          child: Center(
                            child: Icon(grid[column][row].isCovered
                                ? (grid[column][row].isFlagged
                                    ? Icons.outlined_flag
                                    : Icons.crop_square)
                                : (grid[column][row].isMine
                                    ? Icons.flare
                                    : (adjacencyIcons[
                                        grid[column][row].adjacentMines]))),
                          )),
                      onTap: () => _handleTap(column, row),
                      onLongPress: () => _handleLongPress(column, row),
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

typedef GestureHandlerFunction = void Function(int column, int row);

class BoardSquare extends StatefulWidget {
  BoardSquare(this.data, {this.onTap, this.onLongPress});

  final Square data;
  final Function onTap;
  final Function onLongPress;

  @override
  _BoardSquareState createState() => _BoardSquareState();
}

class _BoardSquareState extends State<BoardSquare> {
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
