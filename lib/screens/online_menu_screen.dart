import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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

  Future<void> _handleCreate() async {
    setState(() => _isLoading = true);
    final code = await _service.createRoom();
    setState(() {
      _createdCode = code;
      _isLoading = false;
    });
  }

  Future<void> _handleJoin() async {
    final code = _codeController.text.trim().toUpperCase();
    if (code.length != 4) return;

    setState(() => _isLoading = true);
    final success = await _service.joinRoom(code);
    setState(() => _isLoading = false);

    if (!success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Room not found or already full.')),
      );
    }
    // TODO next step: navigate to the online game screen on success
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Play Online')),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  ElevatedButton(
                    onPressed: _handleCreate,
                    child: const Text('Create Room'),
                  ),
                  if (_createdCode != null) ...[
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          'Code: $_createdCode',
                          style: Theme.of(context).textTheme.headlineMedium,
                        ),
                        IconButton(
                          icon: const Icon(Icons.copy),
                          onPressed: () => Clipboard.setData(
                            ClipboardData(text: _createdCode!),
                          ),
                        ),
                      ],
                    ),
                    const Text(
                      'Waiting for opponent...',
                      textAlign: TextAlign.center,
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