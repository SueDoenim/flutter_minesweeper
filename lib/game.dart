import 'package:flutter/widgets.dart';

import 'layout.dart';

class Square {
  Square(
    this.isMine,
    this.isCovered,
    this.isFlagged,
    this.adjacentMines,
    this.adjacentFlags,
  );
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

class GameWidget extends StatefulWidget {
  GameWidget({
    required this.rowCount,
    required this.columnCount,
    required this.mineCount,
  });

  final int rowCount;
  final int columnCount;
  final int mineCount;

  @override
  _GameWidgetState createState() => _GameWidgetState();
}

class _GameWidgetState extends State<GameWidget> {
  late int _coveredCount;
  late int _flaggedCount;
  late List<List<Square>> _grid;
  bool? _gameWon;

  bool get _gridIsInitialized => _grid[0][0].isMine != null;

  @override
  void initState() {
    super.initState();
    _initializeGame();
  }

  void _initializeGame() {
    _coveredCount = widget.rowCount * widget.columnCount;
    _flaggedCount = 0;
    _grid = List.generate(widget.rowCount, (r) {
      return List.generate(widget.columnCount, (c) {
        return Square(null, true, false, 0, 0);
      });
    });
    _gameWon = null;
  }

  void _initializeGrid(int row, int column) {
    // Use shuffled lists to randomly place mines anywhere but where the player
    // clicked. If there are few enough mines, leave the adjacent spaces free of
    // mines as well.
    final int squareCount = widget.rowCount * widget.columnCount;
    final int adjacentCount = _getAdjacentSquares(row, column).length;
    // List<int> randomList = List.generate(squareCount - 1, (i) => i)..shuffle();
    List<int> randomList =
        List.generate(squareCount - adjacentCount - 1, (i) => i)..shuffle();

    List<int> adjacentRandomList =
        List.generate(adjacentCount, (i) => squareCount - 9 + i)..shuffle();

    // List<List<bool?>> mineGrid = List.generate(widget.rowCount, (r) {
    //   return List.generate(widget.columnCount, (c) => null);
    // });

    _grid[row][column].isMine = false;

    _getAdjacentSquares(row, column).forEach((position) {
      if (adjacentRandomList.removeLast() < widget.mineCount) {
        _grid[position.row][position.column].isMine = true;
        _getAdjacentSquares(position.row, position.column).forEach((position) {
          _grid[position.row][position.column].adjacentMines++;
        });
      } else {
        _grid[position.row][position.column].isMine = false;
      }
    });

    for (int r = 0; r < widget.rowCount; r++) {
      for (int c = 0; c < widget.columnCount; c++) {
        if (_grid[r][c].isMine == null) {
          if (randomList.removeLast() < widget.mineCount) {
            _grid[r][c].isMine = true;
            _getAdjacentSquares(r, c).forEach((position) {
              _grid[position.row][position.column].adjacentMines++;
            });
          } else {
            _grid[r][c].isMine = false;
          }
        }
      }
    }

    // randomList.insert(row * widget.columnCount + column, squareCount - 1);

    // for (int r = 0; r < widget.rowCount; r++) {
    //   for (int c = 0; c < widget.columnCount; c++) {
    //     if (randomList[r * widget.columnCount + c] < widget.mineCount) {
    //       _grid[r][c].isMine = true;
    //       _getAdjacentSquares(r, c).forEach((position) {
    //         _grid[position.row][position.column].adjacentMines++;
    //       });
    //     } else {
    //       _grid[r][c].isMine = false;
    //     }
    //   }
    // }
  }

  List<BoardPosition> _getAdjacentSquares(int row, int column) {
    List<BoardPosition> adjacentSquares = [];
    // Return every square around the given square, but don't return the given
    // square or squares that don't exist in the grid.
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

  void _handleTap(int row, int column) {
    if (_grid[row][column].isCovered == true &&
        _grid[row][column].isFlagged == false) {
      return _uncoverSquare(row, column);
    }
    if (_grid[row][column].isCovered == false) {
      if (_grid[row][column].adjacentFlags ==
          _grid[row][column].adjacentMines) {
        _getAdjacentSquares(row, column).forEach((position) {
          if (_grid[position.row][position.column].isFlagged == false) {
            _uncoverSquare(position.row, position.column);
          }
        });
      }
    }
  }

  void _handleLongPress(int row, int column) {
    _flagSquare(row, column);
  }

  void _uncoverSquare(int row, int column) {
    if (_grid[row][column].isCovered == false) {
      return;
    }
    setState(() {
      if (!_gridIsInitialized) {
        _initializeGrid(row, column);
      }
      _grid[row][column].isCovered = false;
      _coveredCount--;
      if (_grid[row][column].isMine == true) {
        return _handleLose();
      }
      if (_grid[row][column].adjacentMines == 0) {
        _getAdjacentSquares(row, column).forEach((position) {
          if (_grid[position.row][position.column].isCovered == true &&
              _grid[position.row][position.column].isFlagged == false) {
            _uncoverSquare(position.row, position.column);
          }
        });
      }
      if (_coveredCount == widget.mineCount) {
        return _handleWin();
      }
    });
  }

  void _flagSquare(int row, int column) {
    if (_grid[row][column].isCovered) {
      setState(() {
        if (_grid[row][column].isFlagged == false) {
          _grid[row][column].isFlagged = true;
          _flaggedCount++;
          _getAdjacentSquares(row, column).forEach((position) =>
              _grid[position.row][position.column].adjacentFlags++);
        } else {
          _grid[row][column].isFlagged = false;
          _flaggedCount--;
          _getAdjacentSquares(row, column).forEach((position) =>
              _grid[position.row][position.column].adjacentFlags--);
        }
      });
    }
  }

  void _handleWin() {
    setState(() => _gameWon = true);
  }

  void _handleLose() {
    setState(() => _gameWon = false);
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Column(
        children: [
          PanelWidget(
            mineCount: widget.mineCount,
            flaggedCount: _flaggedCount,
            restart: () => setState(() => _initializeGame()),
            gameWon: _gameWon,
          ),
          Expanded(
            child: BoardWidget(
              _grid,
              (_gameWon == null) ? _handleTap : null,
              (_gameWon == null) ? _handleLongPress : null,
            ),
          ),
        ],
      ),
    );
  }
}
