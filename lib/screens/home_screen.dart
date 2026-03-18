import 'package:flutter/material.dart';
import 'dart:collection';

import 'package:infinite_tictactoe/screens/online_menu_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  List<String> board = List.filled(9, '');
  bool isXTurn = true;

  Queue<int> xMoves = Queue();
  Queue<int> oMoves = Queue();

  bool checkWinner(String symbol) {
    const winningPatterns = [
      [0, 1, 2],
      [3, 4, 5],
      [6, 7, 8],
      [0, 3, 6],
      [1, 4, 7],
      [2, 4, 8],
      [0, 4, 8],
      [2, 4, 6],
    ];

    for (var pattern in winningPatterns) {
      if (board[pattern[0]] == symbol &&
          board[pattern[1]] == symbol &&
          board[pattern[2]] == symbol) {
        return true;
      }
    }
    return false;
  }

  void resetGame() {
    setState(() {
      board = List.filled(9, '');
      xMoves.clear();
      oMoves.clear();
      isXTurn = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Infinite TicTacToe'), centerTitle: true),
      body: Center(
        child: Column(
          children: [
            ElevatedButton(
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const OnlineMenuScreen()),
              ),
              child: const Text('Play Online'),
            ),
            AspectRatio(
              aspectRatio: 1,
              child: GridView.builder(
                physics: NeverScrollableScrollPhysics(),
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3,
                ),
                itemCount: 9,
                itemBuilder: (context, index) {
                  return GestureDetector(
                    onTap: () {
                      if (board[index] != '') return;
                      setState(() {
                        final currentQueue = isXTurn ? xMoves : oMoves;
                        final symbol = isXTurn ? 'X' : 'O';

                        if (currentQueue.length == 3) {
                          final oldestIndex = currentQueue.removeFirst();
                          board[oldestIndex] = '';
                        }

                        board[index] = symbol;
                        currentQueue.add(index);

                        if (checkWinner(symbol)) {
                          showWinnerDialog(symbol);
                          return;
                        }

                        isXTurn = !isXTurn;
                      });
                    },
                    child: Container(
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.black),
                      ),
                      child: Center(
                        child: Text(
                          board[index],
                          style: TextStyle(
                            fontSize: 40,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  void showWinnerDialog(String winner) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) {
        return AlertDialog(
          title: const Text("Game Over"),
          content: Text("$winner wins!"),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                resetGame();
              },
              child: const Text("Play Again"),
            ),
          ],
        );
      },
    );
  }
}
