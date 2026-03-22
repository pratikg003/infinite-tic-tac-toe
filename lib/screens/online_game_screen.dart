import 'package:flutter/material.dart';
import 'dart:collection';
import '../service/game_service.dart';

class OnlineGameScreen extends StatefulWidget {
  final String roomCode;
  final String mySymbol; // 'X' or 'O'

  const OnlineGameScreen({
    super.key,
    required this.roomCode,
    required this.mySymbol,
  });

  @override
  State<OnlineGameScreen> createState() => _OnlineGameScreenState();
}

class _OnlineGameScreenState extends State<OnlineGameScreen> {
  final _service = GameService();

  // _gameState holds the latest snapshot from Firebase.
  // Every time Firebase pushes an update, we rebuild the UI from this.
  Map<String, dynamic>? _gameState;

  @override
  void initState() {
    super.initState();

    _service.registerDisconnectHandler(widget.roomCode);

    _service.watchRoom(widget.roomCode).listen((event) {
      if (!mounted) return;
      if (event.snapshot.exists) {
        setState(() {
          _gameState = Map<String, dynamic>.from(event.snapshot.value as Map);
        });
      }
    });
  }

  @override
  void dispose() {
    _service.leaveRoom(widget.roomCode);
    super.dispose();
  }

  // Helpers to read cleanly from _gameState
  bool get _isMyTurn => _gameState?['turn'] == widget.mySymbol;

  List<String> get _board {
    if (_gameState == null) return List.filled(9, '');
    final raw = _gameState!['board'];
    if (raw == null) return List.filled(9, '');
    return List<dynamic>.from(raw as List).map((e) => e.toString()).toList();
  }

  Queue<int> _getQueue(String symbol) {
    final key = symbol == 'X' ? 'xQueue' : 'oQueue';
    // Firebase returns null for empty arrays — treat null as empty
    final raw = _gameState![key];
    if (raw == null) return Queue<int>();
    return Queue<int>.from(
      List<dynamic>.from(raw as List).map((e) => e as int),
    );
  }

  int? get _indexToBeRemoved {
    if (_gameState == null) return null;
    if (!_isMyTurn) return null;

    final queue = _getQueue(widget.mySymbol);
    if (queue.length < 3) return null;

    return queue.first;
  }

  Future<void> _handleTap(int index) async {
    // Guard clauses — bail out if the tap is invalid

    if (_gameState == null) return;
    if (!_isMyTurn) return;
    if (_gameState!['status'] != 'live') return;
    if (_board[index] != '') return;

    // print('>> passed all guards, making move...');

    final symbol = widget.mySymbol;
    final opponent = symbol == 'X' ? 'O' : 'X';
    final queueKey = symbol == 'X' ? 'xQueue' : 'oQueue';

    // Work on a local copy — don't mutate _gameState directly
    final board = _board;
    final queue = _getQueue(symbol);

    // FIFO rule: remove oldest mark when player already has 3
    if (queue.length == 3) {
      board[queue.removeFirst()] = '';
    }

    board[index] = symbol;
    queue.add(index);

    // Check win on the updated board
    final winner = _checkWinner(board, symbol) ? symbol : null;

    // One atomic write to Firebase — both devices react to this
    await _service.makeMove(
      roomCode: widget.roomCode,
      board: board,
      queueKey: queueKey,
      queue: queue.toList(),
      nextTurn: opponent,
      winner: winner,
    );
  }

  bool _checkWinner(List<String> board, String symbol) {
    const patterns = [
      [0, 1, 2],
      [3, 4, 5],
      [6, 7, 8],
      [0, 3, 6],
      [1, 4, 7],
      [2, 5, 8],
      [0, 4, 8],
      [2, 4, 6],
    ];
    return patterns.any(
      (p) =>
          board[p[0]] == symbol &&
          board[p[1]] == symbol &&
          board[p[2]] == symbol,
    );
  }

  @override
  Widget build(BuildContext context) {
    // Show spinner until first Firebase snapshot arrives
    if (_gameState == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final status = _gameState!['status'];

    // Waiting screen — shown to the room creator until opponent joins
    if (status == 'waiting') {
      return Scaffold(
        appBar: AppBar(title: Text('Room: ${widget.roomCode}')),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const CircularProgressIndicator(),
              const SizedBox(height: 24),
              Text(
                'You are ${widget.mySymbol}',
                style: const TextStyle(fontSize: 18),
              ),
              const SizedBox(height: 8),
              Text(
                widget.roomCode,
                style: const TextStyle(
                  fontSize: 48,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 8,
                ),
              ),
              const SizedBox(height: 8),
              const Text('Share this code with your opponent'),
            ],
          ),
        ),
      );
    }

    //abandoned
    if (status == 'abandoned') {
      return Scaffold(
        appBar: AppBar(title: Text('Room: ${widget.roomCode}')),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.wifi_off, size: 64, color: Colors.grey),
              const SizedBox(height: 24),
              const Text(
                'Opponent disconnected',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Back to Menu'),
              ),
            ],
          ),
        ),
      );
    }

    // Game screen
    final winner = _gameState!['winner'];
    final board = _board;

    final statusText = winner != null
        ? (winner == widget.mySymbol ? '🎉 You win!' : '😔 You lose!')
        : (_isMyTurn ? 'Your turn (${widget.mySymbol})' : "Opponent's turn");

    return Scaffold(
      appBar: AppBar(title: Text('Room: ${widget.roomCode}')),
      body: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            statusText,
            style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 24),
          Padding(
            padding: const EdgeInsets.all(16),
            child: AspectRatio(
              aspectRatio: 1,
              child: GridView.builder(
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3,
                ),
                itemCount: 9,
                itemBuilder: (context, index) {
                  final cellValue = board[index];
                  final isDoomed = index == _indexToBeRemoved;

                  // Decide cell border style
                  final border = isDoomed
                      ? Border.all(color: Colors.orange, width: 2)
                      : Border.all(color: Colors.black);

                  // Decide text color and opacity
                  Color symbolColor;
                  if (cellValue == widget.mySymbol) {
                    symbolColor = Colors.blue;
                  } else {
                    symbolColor = Colors.red;
                  }
                  return GestureDetector(
                    onTap: winner == null ? () => _handleTap(index) : null,
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      decoration: BoxDecoration(
                        border: border,
                        // Subtle warm tint on the doomed cell
                        color: isDoomed
                            ? Colors.orange.withValues(alpha: 0.08)
                            : Colors.transparent,
                      ),
                      child: Center(
                        child: AnimatedOpacity(
                          duration: const Duration(milliseconds: 300),
                          // Dim the doomed mark to 35% opacity
                          opacity: isDoomed ? 0.35 : 1.0,
                          child: Text(
                            cellValue,
                            style: TextStyle(
                              fontSize: 40,
                              fontWeight: FontWeight.bold,
                              color: symbolColor,
                            ),
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
          if (winner != null) ...[
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => _service.resetRoom(widget.roomCode),
              child: const Text('Play Again'),
            ),
          ],
        ],
      ),
    );
  }
}
