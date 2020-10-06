import 'package:flutter/foundation.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;

class Board extends ChangeNotifier {
  String _message = 'Waiting for an opponent...';
  List<BoardCell> _cells;
  bool _myTurn = false;
  String _symbol = '';
  final IO.Socket _socket = IO.io('http://localhost:8080', <String, dynamic>{
    'transports': ['websocket'],
  });

  String get message => _message;
  List<BoardCell> get cells => _cells;
  bool get myTurn => _myTurn;

  void _init() {
    _socket.on('move.made', (data) {
      Map<String, String> dataMap = Map.from(data);
      BoardCell movedCell = BoardCell.fromJson(dataMap);

      int movedIndex =
          cells.indexWhere((element) => element.position == movedCell.position);

      cells.replaceRange(movedIndex, movedIndex + 1, [movedCell]);

      // If the symbol of the last move was the same as the current player
      // means that now is opponent's turn
      _myTurn = movedCell.symbol != _symbol;

      if (!_isGameOver()) {
        // If game isn't over show who's turn is this
        _setTurnMessage();
      } else {
        // Else show win/lose message
        _message = myTurn ? 'You lost.' : 'You won!';
        _myTurn = false; // Disable board
      }

      notifyListeners();
    });

    _socket.on('game.begin', (data) {
      Map<String, String> dataMap = Map.from(data);
      _symbol = BoardCell.fromJson(dataMap)
          .symbol; // The server is assigning the symbol
      _myTurn = _symbol == 'X'; // 'X' starts first
      _setTurnMessage();

      notifyListeners();
    });

    // Bind on event for opponent leaving the game
    _socket.on('opponent.left', (_) {
      _message = 'Your opponent left the game.';
      _myTurn = false;

      notifyListeners();
    });
  }

  String _generateId(int index) {
    String id = 'r' +
        (index ~/ 3).toString() +
        'c' +
        (index - 3 * (index ~/ 3)).toString();
    return id;
  }

  bool _isGameOver() {
    final List<String> matches = [
      'XXX',
      'OOO'
    ]; // This are the string we will be looking for to declare the match over

    // We are creating a string for each possible winning combination of the cells
    final List<String> rows = [
      '${cells[0].symbol}${cells[1].symbol}${cells[2].symbol}', // 1st line
      '${cells[3].symbol}${cells[4].symbol}${cells[5].symbol}', // 2nd line
      '${cells[6].symbol}${cells[7].symbol}${cells[8].symbol}', // 3rd line
      '${cells[0].symbol}${cells[3].symbol}${cells[6].symbol}', // 1st column
      '${cells[1].symbol}${cells[4].symbol}${cells[7].symbol}', // 2nd column
      '${cells[2].symbol}${cells[5].symbol}${cells[8].symbol}', // 3rd column
      '${cells[0].symbol}${cells[4].symbol}${cells[8].symbol}', // Primary diagonal
      '${cells[2].symbol}${cells[4].symbol}${cells[6].symbol}' // Secondary diagonal
    ];

    // Loop through all the rows looking for a match
    for (int i = 0; i < rows.length; i++) {
      if (rows[i] == matches[0] || rows[i] == matches[1]) {
        return true;
      }
    }

    return false;
  }

  void _setTurnMessage() {
    _message = myTurn ? 'Your turn' : 'Your opponent\'s turn';

    notifyListeners();
  }

  void makeMove(BoardCell cell) {
    if (cell.symbol.isNotEmpty) {
      return; // If cell is already checked
    }

    _socket.emit(
      'make.move',
      BoardCell(
        symbol: _symbol,
        position: cell.position,
      ),
    );
  }

  Board() {
    _cells = new List<BoardCell>.generate(9, (int index) {
      return new BoardCell(position: _generateId(index), symbol: '');
    });
    _init();
  }
}

@immutable
class BoardCell {
  final String position;
  final String symbol;

  BoardCell({this.position, this.symbol});

  BoardCell.fromJson(Map<String, String> json)
      : symbol = json['symbol'],
        position = json['position'];

  Map<String, dynamic> toJson() => {
        'symbol': symbol,
        'position': position,
      };
}
