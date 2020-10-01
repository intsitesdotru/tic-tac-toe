import 'package:flutter/material.dart';

void main() {
  runApp(
    TicTacToeApp(),
  );
}

class TicTacToeApp extends StatelessWidget {
  const TicTacToeApp({
    Key key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Tic Tac Toe(Flutter)',
      home: Scaffold(
        appBar: AppBar(
          title: Text('Tic Tac Toe - Flutter Client'),
        ),
        body: GameScreen(),
      ),
    );
  }
}

class GameScreen extends StatelessWidget {
  const GameScreen({
    Key key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column();
  }
}
