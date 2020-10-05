import 'package:flutter/material.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;

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

class GameScreen extends StatefulWidget {
  GameScreen({
    Key key,
  }) : super(key: key);

  final IO.Socket socket = IO.io('http://localhost:8080', <String, dynamic>{
    'transports': ['websocket'],
  });

  @override
  _GameScreenState createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> {
  String _message = 'Waiting for an opponent...';
  List<BoardCell> _boardCells = new List<BoardCell>.generate(9, (int index) {
    String position = 'r' +
        (index ~/ 3).toString() +
        'c' +
        (index - 3 * (index ~/ 3)).toString();
    return new BoardCell(position: position, symbol: '');
  });
  bool myTurn = false;
  String symbol = '';

  @override
  void initState() {
    // Bind event on players move
    widget.socket.on('move.made', (data) {
      BoardCell current = _boardCells
          .singleWhere((element) => element.position == data['position']);

      setState(() {
        current.symbol = data['symbol']; // Render move
      });

      // If the symbol of the last move was the same as the current player
      // means that now is opponent's turn
      setState(() {
        myTurn = data['symbol'] != symbol;
      });

      if (!isGameOver()) {
        // If game isn't over show who's turn is this
        renderTurnMessage();
      } else {
        // Else show win/lose message
        setState(() {
          _message = myTurn ? 'You lost.' : 'You won!';
          myTurn = false; // Disable board
        });
      }
    });

    widget.socket.on('game.begin', (data) {
      setState(() {
        symbol = data['symbol']; // The server is assigning the symbol
        myTurn = symbol == 'X'; // 'X' starts first
      });
      renderTurnMessage();
    });

    // Bind on event for opponent leaving the game
    widget.socket.on('opponent.left', (_) {
      setState(() {
        _message = 'Your opponent left the game.';
        myTurn = false;
      });
    });

    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        children: [
          Text(
            _message,
            style: Theme.of(context).textTheme.headline3,
            textAlign: TextAlign.center,
          ),
          Flexible(
            child: Opacity(
              opacity: myTurn ? 1.0 : 0.5,
              child: Container(
                width: 600,
                child: GridView.count(
                  primary: false,
                  padding: const EdgeInsets.all(20),
                  crossAxisSpacing: 10,
                  mainAxisSpacing: 10,
                  crossAxisCount: 3,
                  children: _boardCells
                      .map((item) => RaisedButton(
                            onPressed: myTurn
                                ? () {
                                    _makeMove(item);
                                  }
                                : null,
                            child: Text(
                              item.symbol,
                              style: Theme.of(context).textTheme.headline2,
                            ),
                            disabledColor: Colors.grey[200],
                          ))
                      .toList(),
                ),
              ),
            ),
          )
        ],
      ),
    );
  }

  bool isGameOver() {
    final List<String> matches = [
      'XXX',
      'OOO'
    ]; // This are the string we will be looking for to declare the match over

    // We are creating a string for each possible winning combination of the cells
    final List<String> rows = [
      '${_boardCells[0].symbol}${_boardCells[1].symbol}${_boardCells[2].symbol}', // 1st line
      '${_boardCells[3].symbol}${_boardCells[4].symbol}${_boardCells[5].symbol}', // 2nd line
      '${_boardCells[6].symbol}${_boardCells[7].symbol}${_boardCells[8].symbol}', // 3rd line
      '${_boardCells[0].symbol}${_boardCells[3].symbol}${_boardCells[6].symbol}', // 1st column
      '${_boardCells[1].symbol}${_boardCells[4].symbol}${_boardCells[7].symbol}', // 2nd column
      '${_boardCells[2].symbol}${_boardCells[5].symbol}${_boardCells[8].symbol}', // 3rd column
      '${_boardCells[0].symbol}${_boardCells[4].symbol}${_boardCells[8].symbol}', // Primary diagonal
      '${_boardCells[2].symbol}${_boardCells[4].symbol}${_boardCells[6].symbol}' // Secondary diagonal
    ];

    // Loop through all the rows looking for a match
    for (int i = 0; i < rows.length; i++) {
      if (rows[i] == matches[0] || rows[i] == matches[1]) {
        return true;
      }
    }

    return false;
  }

  void renderTurnMessage() {
    setState(() {
      _message = myTurn ? 'Your turn' : 'Your opponent\'s turn';
    });
  }

  void _makeMove(BoardCell cell) {
    if (cell.symbol.isNotEmpty) {
      return; // If cell is already checked
    }

    widget.socket.emit('make.move', {
      // Valid move (on client side) -> emit to server
      'symbol': symbol,
      'position': cell.position
    });
  }
}

class BoardCell {
  String position;
  String symbol;

  BoardCell({this.position, this.symbol});
}
