import 'dart:math';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_core/firebase_core.dart';

class GameService {
  // Single reference to the root of your RTDB
  final _db = FirebaseDatabase.instanceFor(
    app: Firebase.app(),
    databaseURL: 'https://infinite-tictactoe-abbe2-default-rtdb.asia-southeast1.firebasedatabase.app',
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
  print('>>> Step 1: signing in anonymously');
  await _auth.signInAnonymously();
  print('>>> Step 2: signed in, uid = ${_auth.currentUser?.uid}');
  
  final code = _generateCode();
  print('>>> Step 3: generated code = $code');

  print('>>> Step 4: writing to database...');
  await _db.child('games/$code').set({
    'roomCode': code,
    'status': 'waiting',
    'turn': 'X',
    'winner': null,
    'board': List.filled(9, ''),
    'xQueue': [],
    'oQueue': [],
    'players': {'x': _auth.currentUser!.uid, 'o': null},
  });
  print('>>> Step 5: write complete!');

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
    await _db.child('games/$code').update({
      'players/o': uid,
      'status': 'live',
    });

    return null; // null means success
  }

  // Streams the entire game node in real time.
  // The game screen will subscribe to this.
  Stream<DatabaseEvent> watchRoom(String code) {
    return _db.child('games/$code').onValue;
  }
}