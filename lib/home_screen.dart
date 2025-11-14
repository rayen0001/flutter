import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:http/http.dart' as http;

import 'login_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  // Android Firebase Realtime Database
  late DatabaseReference _postsRef;

  // For web → REST API polling
  Timer? _pollTimer;
  final String _firebaseDbUrl =
      "https://mizania-7f7c0-default-rtdb.firebaseio.com/posts.json";

  List<Map<dynamic, dynamic>> _posts = [];

  bool _isDialogOpen = false;

  @override
  void initState() {
    super.initState();
    if (kIsWeb) {
      _startPolling();
    } else {
      _initializeRTDB();
    }
  }

  // ------------------------------
  // ANDROID → Realtime listener
  // ------------------------------
  void _initializeRTDB() {
    _postsRef = FirebaseDatabase.instance.ref().child("posts");
    _postsRef.onValue.listen((event) {
      final data = event.snapshot.value;
      if (!mounted) return;

      if (data != null && data is Map) {
        final List<Map> loaded = [];
        data.forEach((k, v) {
          if (v is Map) loaded.add({"key": k, ...v});
        });
        loaded.sort((a, b) =>
            (b["timestamp"] ?? 0).compareTo(a["timestamp"] ?? 0));
        setState(() => _posts = loaded);
      } else {
        setState(() => _posts = []);
      }
    });
  }

  // ------------------------------
  // WEB → REST polling (every 2s)
  // ------------------------------
  void _startPolling() {
    _pollTimer = Timer.periodic(const Duration(seconds: 2), (_) async {
      try {
        final res = await http.get(Uri.parse(_firebaseDbUrl));
        if (res.statusCode == 200) {
          final data = json.decode(res.body);
          if (data == null) {
            if (mounted) setState(() => _posts = []);
            return;
          }

          final List<Map> loaded = [];
          data.forEach((k, v) {
            if (v is Map) loaded.add({"key": k, ...v});
          });

          loaded.sort((a, b) =>
              (b["timestamp"] ?? 0).compareTo(a["timestamp"] ?? 0));

          if (mounted) setState(() => _posts = loaded);
        }
      } catch (_) {}
    });
  }

  // ------------------------------
  // CREATE POST
  // ------------------------------
  Future<void> _addPost() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    if (_isDialogOpen) return;
    _isDialogOpen = true;

    final controller = TextEditingController();

    await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Create Post"),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            hintText: "What's on your mind?",
            border: OutlineInputBorder(),
          ),
          maxLines: 3,
        ),
        actions: [
          TextButton(
            onPressed: () {
              controller.dispose();
              Navigator.pop(ctx);
            },
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF1BA57B),
            ),
            onPressed: () async {
              final text = controller.text.trim();
              if (text.isEmpty) return;

              Navigator.pop(ctx);
              controller.dispose();

              if (kIsWeb) {
                // REST POST
                await http.post(
                  Uri.parse(_firebaseDbUrl),
                  body: json.encode({
                    "content": text,
                    "author": user.email ?? "Anonymous",
                    "authorId": user.uid,
                    "timestamp": DateTime.now().millisecondsSinceEpoch,
                  }),
                );
              } else {
                // Native RTDB
                await _postsRef.push().set({
                  "content": text,
                  "author": user.email ?? "Anonymous",
                  "authorId": user.uid,
                  "timestamp": ServerValue.timestamp,
                });
              }
            },
            child: const Text("Post", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    _isDialogOpen = false;
  }

  // ------------------------------
  // DELETE POST
  // ------------------------------
  Future<void> _deletePost(String key) async {
    if (kIsWeb) {
      await http.delete(
        Uri.parse(
            "https://mizania-7f7c0-default-rtdb.firebaseio.com/posts/$key.json"),
      );
    } else {
      await _postsRef.child(key).remove();
    }
  }

  // ------------------------------
  // LOGOUT
  // ------------------------------
  Future<void> _logout() async {
    await FirebaseAuth.instance.signOut();
    if (!mounted) return;
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const LoginScreen()),
    );
  }

  // ------------------------------
  // FORMAT TIMESTAMP
  // ------------------------------
  String _formatTimestamp(dynamic timestamp) {
    if (timestamp == null) return 'Just now';
    final dt = DateTime.fromMillisecondsSinceEpoch(timestamp);
    final diff = DateTime.now().difference(dt);
    if (diff.inDays > 0) return '${diff.inDays}d ago';
    if (diff.inHours > 0) return '${diff.inHours}h ago';
    if (diff.inMinutes > 0) return '${diff.inMinutes}m ago';
    return 'Just now';
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      appBar: AppBar(
        title: const Text("Home", style: TextStyle(color: Colors.white)),
        backgroundColor: const Color(0xFF1BA57B),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.white),
            onPressed: _logout,
          ),
        ],
      ),

      body: Column(
        children: [
          // ----- HEADER -----
          Container(
            padding: const EdgeInsets.all(16),
            color: const Color(0xFF1BA57B).withOpacity(0.1),
            child: Row(
              children: [
                CircleAvatar(
                  backgroundColor: const Color(0xFF1BA57B),
                  child: Text(
                    user?.email?.isNotEmpty == true
                        ? user!.email![0].toUpperCase()
                        : 'U',
                    style: const TextStyle(color: Colors.white),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Welcome back!',
                        style: TextStyle(
                            fontSize: 14, color: Colors.grey[600]),
                      ),
                      Text(
                        user?.email ?? 'User',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // ----- POSTS -----
          Expanded(
            child: _posts.isEmpty
                ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.post_add, size: 64, color: Colors.grey[400]),
                  const SizedBox(height: 16),
                  Text(
                    'No posts yet',
                    style: TextStyle(
                        fontSize: 18, color: Colors.grey[600]),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Tap the + button to create your first post',
                    style: TextStyle(color: Colors.grey[500]),
                  ),
                ],
              ),
            )
                : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _posts.length,
              itemBuilder: (_, i) {
                final post = _posts[i];
                final isMyPost = post["authorId"] == user?.uid;

                return Card(
                  margin: const EdgeInsets.only(bottom: 16),
                  elevation: 2,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            CircleAvatar(
                              radius: 20,
                              backgroundColor: const Color(0xFF1BA57B),
                              child: Text(
                                (post['author'] ?? 'A')
                                    .toString()
                                    .substring(0, 1)
                                    .toUpperCase(),
                                style: const TextStyle(color: Colors.white),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment:
                                CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    post['author'] ?? 'Anonymous',
                                    style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 16),
                                  ),
                                  Text(
                                    _formatTimestamp(post['timestamp']),
                                    style: TextStyle(
                                        color: Colors.grey[600],
                                        fontSize: 12),
                                  ),
                                ],
                              ),
                            ),
                            if (isMyPost)
                              IconButton(
                                icon: const Icon(Icons.delete_outline,
                                    color: Colors.red),
                                onPressed: () =>
                                    _deletePost(post['key']),
                              ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Text(
                          post['content'] ?? '',
                          style: const TextStyle(fontSize: 16),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),

      floatingActionButton: FloatingActionButton(
        backgroundColor: const Color(0xFF1BA57B),
        onPressed: _addPost,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }
}
