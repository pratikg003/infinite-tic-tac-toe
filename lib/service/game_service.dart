import 'dart:math';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_database/firebase_database.dart';

class GameService {
  // Single reference to the root of your RTDB
  final _db = FirebaseDatabase.instanceFor(
    app: Firebase.app(),
    databaseURL:
        'https://infinite-tictactoe-abbe2-default-rtdb.asia-southeast1.firebasedatabase.app',
  ).ref();
  final _auth = FirebaseAuth.instance;

  // Exposes the current user's UID so the game screen
  // can know "am I X or O?"
  String? get currentUid => _auth.currentUser?.uid;

  String _generateCode() {
    // Removed easily confused chars like 0/O and 1/I
    const chars = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';
    final rand = Random();
    return List.generate(4, (_) => chars[rand.nextInt(chars.length)]).join();
  }

  Future<String> createRoom() async {
    // Anonymous auth = no login screen, but each device
    // still gets a unique UID we can use to identify players
    await _auth.signInAnonymously();
    final uid = _auth.currentUser!.uid;
    final code = _generateCode();

    await _db.child('games/$code').set({
      'roomCode': code,
      'status': 'waiting', // waiting → live → finished
      'turn': 'X',
      'winner': null,
      'board': List.filled(9, ''),
      'xQueue': [],
      'oQueue': [],
      'players': {'x': uid, 'o': null},
    });

    return code;
  }

  Future<String?> joinRoom(String code) async {
    await _auth.signInAnonymously();
    final uid = _auth.currentUser!.uid;

    final snapshot = await _db.child('games/$code').get();

    // Validate before writing anything
    if (!snapshot.exists) return 'Room not found.';
    final data = Map<String, dynamic>.from(snapshot.value as Map);
    if (data['status'] != 'waiting') return 'Game already started.';
    if (data['players']['o'] != null) return 'Room is full.';

    // Claim the O slot and flip status to live in one atomic update
    await _db.child('games/$code').update({'players/o': uid, 'status': 'live'});

    return null; // null means success
  }

  // Streams the entire game node in real time.
  // The game screen will subscribe to this.
  Stream<DatabaseEvent> watchRoom(String code) {
    return _db.child('games/$code').onValue;
  }

  // Called every time a player taps a cell.
  // Writes the new board, queue, and turn atomically to Firebase.
  Future<void> makeMove({
    required String roomCode,
    required List<String> board,
    required String queueKey, // 'xQueue' or 'oQueue'
    required List<int> queue, // the updated queue as a plain list
    required String nextTurn, // whose turn is next
    String? winner, // null if no winner yet
  }) async {
    final data = {'board': board, queueKey: queue, 'turn': nextTurn};

    if (winner != null) {
      data['winner'] = winner;
      data['status'] = 'finished';
    }

    // update() only changes the keys we specify — it won't
    // wipe out players, roomCode, or other fields
    await _db.child('games/$roomCode').update(data);
  }

  // Resets the board for a rematch without deleting the room
  Future<void> resetRoom(String roomCode) async {
    await _db.child('games/$roomCode').update({
      'board': List.filled(9, ''),
      'xQueue': [],
      'oQueue': [],
      'turn': 'X',
      'winner': null,
      'status': 'live',
    });
  }
}
