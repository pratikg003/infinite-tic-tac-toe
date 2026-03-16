import 'dart:math';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';

class GameService {
  final _db = FirebaseDatabase.instance.ref();
  final _auth = FirebaseAuth.instance;

  // Generates "ABCD"-style room codes
  String _generateCode() {
    const chars = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';
    final rand = Random();
    return List.generate(4, (_) => chars[rand.nextInt(chars.length)]).join();
  }

  Future<String> createRoom() async {
    // Sign in anonymously — no login screen needed
    await _auth.signInAnonymously();
    final uid = _auth.currentUser!.uid;

    final code = _generateCode();
    await _db.child('games/$code').set({
      'roomCode': code,
      'status': 'waiting',
      'turn': 'X',
      'winner': null,
      'board': List.filled(9, ''),
      'xQueue': [],
      'oQueue': [],
      'players': {'x': uid, 'o': null},
    });

    return code; // Return code so UI can display it
  }

  Future<bool> joinRoom(String code) async {
    await _auth.signInAnonymously();
    final uid = _auth.currentUser!.uid;

    final snapshot = await _db.child('games/$code').get();
    if (!snapshot.exists) return false;

    final data = Map<String, dynamic>.from(snapshot.value as Map);
    if (data['status'] != 'waiting') return false;
    if (data['players']['o'] != null) return false; // Room full

    // Claim the 'O' slot and flip status to live
    await _db.child('games/$code').update({
      'players/o': uid,
      'status': 'live',
    });

    return true;
  }
}