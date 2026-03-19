import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:infinite_tictactoe/screens/online_game_screen.dart';
import 'package:infinite_tictactoe/service/game_service.dart';

class OnlineMenuScreen extends StatefulWidget {
  const OnlineMenuScreen({super.key});

  @override
  State<OnlineMenuScreen> createState() => _OnlineMenuScreenState();
}

class _OnlineMenuScreenState extends State<OnlineMenuScreen> {
  final _service = GameService();
  final _codeController = TextEditingController();
  bool _isLoading = false;
  String? _createdCode;

  @override
  void dispose() {
    _codeController.dispose();
    super.dispose();
  }


Future<void> _handleCreate() async {
  setState(() => _isLoading = true);
  final code = await _service.createRoom();
  if (!mounted) return;

  // Creator is always X — navigate immediately,
  // game screen shows "waiting" until opponent joins
  Navigator.push(
    context,
    MaterialPageRoute(
      builder: (_) => OnlineGameScreen(
        roomCode: code,
        mySymbol: 'X',
      ),
    ),
  );

  setState(() => _isLoading = false);
}

Future<void> _handleJoin() async {
  final code = _codeController.text.trim().toUpperCase();
  if (code.length != 4) {
    _showMessage('Please enter a 4-letter code.');
    return;
  }

  setState(() => _isLoading = true);
  final error = await _service.joinRoom(code);
  setState(() => _isLoading = false);

  if (error != null) {
    _showMessage(error);
  } else {
    if (!mounted) return;
    // Joiner is always O
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => OnlineGameScreen(
          roomCode: code,
          mySymbol: 'O',
        ),
      ),
    );
  }
}

  void _showMessage(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(msg)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Play Online')),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  ElevatedButton(
                    onPressed: _handleCreate,
                    child: const Text('Create Room'),
                  ),
                  if (_createdCode != null) ...[
                    const SizedBox(height: 20),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          'Code: $_createdCode',
                          style: Theme.of(context).textTheme.headlineMedium,
                        ),
                        IconButton(
                          icon: const Icon(Icons.copy),
                          onPressed: () {
                            Clipboard.setData(
                              ClipboardData(text: _createdCode!),
                            );
                            _showMessage('Code copied!');
                          },
                        ),
                      ],
                    ),
                    const Text(
                      'Waiting for opponent to join...',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.grey),
                    ),
                  ],
                  const SizedBox(height: 40),
                  const Divider(),
                  const SizedBox(height: 24),
                  TextField(
                    controller: _codeController,
                    decoration: const InputDecoration(
                      labelText: 'Enter room code',
                      border: OutlineInputBorder(),
                    ),
                    textCapitalization: TextCapitalization.characters,
                    maxLength: 4,
                  ),
                  const SizedBox(height: 8),
                  ElevatedButton(
                    onPressed: _handleJoin,
                    child: const Text('Join Room'),
                  ),
                ],
              ),
            ),
    );
  }
}