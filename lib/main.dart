import 'dart:math';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: "Minesweeper",
      home: BoardActivity(),
      //home: MyHomePage(title: 'Flutter Demo Home Page'),
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

class BoardActivity extends StatefulWidget {
  @override
  _BoardActivityState createState() => _BoardActivityState(7, 20, 20);
}

class _BoardActivityState extends State<BoardActivity> {
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

  _BoardActivityState(this.columnCount, this.rowCount, this.mineCount) {
    this.coveredCount = columnCount * rowCount;
    this.flaggedCount = 0;
    grid = List.generate(columnCount, (i) {
      return List.generate(rowCount, (j) {
        return Square(null, true, false, 0, 0);
      }, growable: false);
    }, growable: false);
  }

  final List<IconData> adjacencyIcons = [
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
    return Container(
      child: Center(
        child: InteractiveViewer(
          maxScale: 10,
          minScale: 0.5,
          child: Table(
            defaultColumnWidth:
                FixedColumnWidth(MediaQuery.of(context).size.height / rowCount),
            children: List.generate(
              rowCount,
              (row) => TableRow(
                children: List.generate(
                  columnCount,
                  (column) => AspectRatio(
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
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class MyHomePage extends StatefulWidget {
  MyHomePage({Key key, this.title}) : super(key: key);

  // This widget is the home page of your application. It is stateful, meaning
  // that it has a State object (defined below) that contains fields that affect
  // how it looks.

  // This class is the configuration for the state. It holds the values (in this
  // case the title) provided by the parent (in this case the App widget) and
  // used by the build method of the State. Fields in a Widget subclass are
  // always marked "final".

  final String title;

  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  int _counter = 0;

  void _incrementCounter() {
    setState(() {
      // This call to setState tells the Flutter framework that something has
      // changed in this State, which causes it to rerun the build method below
      // so that the display can reflect the updated values. If we changed
      // _counter without calling setState(), then the build method would not be
      // called again, and so nothing would appear to happen.
      _counter++;
    });
  }

  @override
  Widget build(BuildContext context) {
    // This method is rerun every time setState is called, for instance as done
    // by the _incrementCounter method above.
    //
    // The Flutter framework has been optimized to make rerunning build methods
    // fast, so that you can just rebuild anything that needs updating rather
    // than having to individually change instances of widgets.
    return Scaffold(
      appBar: AppBar(
        // Here we take the value from the MyHomePage object that was created by
        // the App.build method, and use it to set our appbar title.
        title: Text(widget.title),
      ),
      body: Center(
        // Center is a layout widget. It takes a single child and positions it
        // in the middle of the parent.
        child: Column(
          // Column is also a layout widget. It takes a list of children and
          // arranges them vertically. By default, it sizes itself to fit its
          // children horizontally, and tries to be as tall as its parent.
          //
          // Invoke "debug painting" (press "p" in the console, choose the
          // "Toggle Debug Paint" action from the Flutter Inspector in Android
          // Studio, or the "Toggle Debug Paint" command in Visual Studio Code)
          // to see the wireframe for each widget.
          //
          // Column has various properties to control how it sizes itself and
          // how it positions its children. Here we use mainAxisAlignment to
          // center the children vertically; the main axis here is the vertical
          // axis because Columns are vertical (the cross axis would be
          // horizontal).
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Text(
              'You have pushed the button this many times:',
            ),
            Text(
              '$_counter',
              style: Theme.of(context).textTheme.headline4,
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _incrementCounter,
        tooltip: 'Increment',
        child: Icon(Icons.add),
      ), // This trailing comma makes auto-formatting nicer for build methods.
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
