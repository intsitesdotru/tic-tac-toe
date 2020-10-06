import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:state_provider/models/board.dart';

void main() {
  runApp(
    ChangeNotifierProvider(create: (context) => Board(), child: TicTacToeApp()),
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
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        children: [
          _Message(),
          _BoardView(),
        ],
      ),
    );
  }
}

class _Message extends StatelessWidget {
  const _Message({
    Key key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Text(
      context.select<Board, String>((state) => state.message),
      style: Theme.of(context).textTheme.headline3,
      textAlign: TextAlign.center,
    );
  }
}

class _BoardView extends StatelessWidget {
  const _BoardView({
    Key key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Flexible(
      child: Consumer<Board>(
        builder: (context, boardState, child) {
          return Opacity(
            opacity: boardState.myTurn ? 1.0 : 0.5,
            child: Container(
              width: 600,
              child: GridView.count(
                primary: false,
                padding: const EdgeInsets.all(20),
                crossAxisSpacing: 10,
                mainAxisSpacing: 10,
                crossAxisCount: 3,
                children: boardState.cells
                    .map((item) => _BoardCellView(item: item))
                    .toList(),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _BoardCellView extends StatelessWidget {
  final BoardCell item;
  const _BoardCellView({
    this.item,
    Key key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    bool myTurn = context.select<Board, bool>((state) => state.myTurn);
    return RaisedButton(
      onPressed: myTurn
          ? () {
              Board boardState = context.read<Board>();
              boardState.makeMove(item);
            }
          : null,
      child: Text(
        item.symbol,
        style: Theme.of(context).textTheme.headline2,
      ),
      disabledColor: Colors.grey[200],
    );
  }
}
