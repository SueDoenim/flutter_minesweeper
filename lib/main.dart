import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import 'package:universal_html/html.dart';

import 'game.dart';

void main() {
  // Disable right click context menu.
  window.onContextMenu.listen((MouseEvent e) => e.preventDefault());
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
