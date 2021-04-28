import 'package:flutter/widgets.dart';
import 'main.dart';

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

  @override
  void initState() {
    super.initState();
    _coveredCount = widget.rowCount * widget.columnCount;
    _flaggedCount = 0;
    _grid = List.generate(widget.rowCount, (r) {
      return List.generate(widget.columnCount, (c) {
        return Square(null, true, false, 0, 0);
      });
    });
  }

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
    if (_grid[row][column].isMine == null) {
      _initializeGrid(row, column);
    }
    if (_grid[row][column].isCovered == true &&
        _grid[row][column].isFlagged == false) {
      _uncoverSquare(row, column);
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
      _grid[row][column].isCovered = false;
      _coveredCount--;
      if (_grid[row][column].isMine == true) {
        _handleLose();
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
        _handleWin();
      }
    });
  }

  void _flagSquare(int row, int column) {
    setState(() {
      if (_grid[row][column].isFlagged == false) {
        _grid[row][column].isFlagged = true;
        _flaggedCount++;
        _getAdjacentSquares(row, column).forEach(
            (position) => _grid[position.row][position.column].adjacentFlags++);
      } else {
        _grid[row][column].isFlagged = false;
        _flaggedCount--;
        _getAdjacentSquares(row, column).forEach(
            (position) => _grid[position.row][position.column].adjacentFlags--);
      }
    });
  }

  void _handleWin() {
    print('yay.');
  }

  void _handleLose() {
    print('u lose haha lozer');
  }

  @override
  Widget build(BuildContext context) {
    return GameData(
      grid: _grid,
      coveredCount: _coveredCount,
      flaggedCount: _flaggedCount,
      handleTap: _handleTap,
      handleLongPress: _handleLongPress,
      child: SafeArea(child: BoardWidget(_grid)),
    );
  }
}

class GameData extends InheritedModel<String> {
  GameData({
    required this.grid,
    required this.coveredCount,
    required this.flaggedCount,
    required this.handleTap,
    required this.handleLongPress,
    required Widget child,
  }) : super(child: child);

  final List<List<Square>> grid;
  final int coveredCount;
  final int flaggedCount;
  final void Function(int, int) handleTap;
  final void Function(int, int) handleLongPress;

  static GameData of(BuildContext context) {
    return context.dependOnInheritedWidgetOfExactType<GameData>()!;
  }

  @override
  bool updateShouldNotify(covariant InheritedWidget oldWidget) {
    return this != oldWidget;
  }

  @override
  bool updateShouldNotifyDependent(
      covariant InheritedModel<String> oldWidget, Set<String> dependencies) {
    return dependencies.contains('grid') ||
        dependencies.contains('coveredCount') ||
        dependencies.contains('flaggedCount');
  }
}
