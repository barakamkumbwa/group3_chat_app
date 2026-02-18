import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:async';
import '../services/auth_service.dart';
import 'register_screen.dart';

class UsersSelectionScreen extends StatefulWidget {
  const UsersSelectionScreen({super.key});

  @override
  State<UsersSelectionScreen> createState() => _UsersSelectionScreenState();
}

class _UsersSelectionScreenState extends State<UsersSelectionScreen> {
  late final AuthService _auth;
  final ScrollController _scrollController = ScrollController();
  final List<Map<String, dynamic>> _users = [];
  final List<StreamSubscription<QuerySnapshot<Map<String, dynamic>>>>
      _presenceSubscriptions = [];

  DocumentSnapshot<Map<String, dynamic>>? _lastDocument;
  bool _isInitialLoading = true;
  bool _isLoadingMore = false;
  bool _hasMore = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _auth = AuthService();
    _loadInitialUsers();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _cancelPresenceSubscriptions();
    _scrollController.dispose();
    super.dispose();
  }

  void _cancelPresenceSubscriptions() {
    for (final sub in _presenceSubscriptions) {
      sub.cancel();
    }
    _presenceSubscriptions.clear();
  }

  void _subscribeToPresenceUpdates() {
    _cancelPresenceSubscriptions();

    final userIds = _users
        .map((user) => user['uid'] as String?)
        .whereType<String>()
        .where((id) => id.isNotEmpty)
        .toSet()
        .toList();

    if (userIds.isEmpty) return;

    const chunkSize = 10;
    for (var i = 0; i < userIds.length; i += chunkSize) {
      final end = (i + chunkSize < userIds.length)
          ? i + chunkSize
          : userIds.length;
      final chunk = userIds.sublist(i, end);

      final sub = FirebaseFirestore.instance
          .collection('users')
          .where(FieldPath.documentId, whereIn: chunk)
          .snapshots()
          .listen((snapshot) {
            if (!mounted) return;
            setState(() {
              for (final doc in snapshot.docs) {
                final index = _users.indexWhere((u) => u['uid'] == doc.id);
                if (index == -1) continue;
                _users[index]['isOnline'] = doc.data()['isOnline'] == true;
              }
            });
          });

      _presenceSubscriptions.add(sub);
    }
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      _loadMoreUsers();
    }
  }

  Future<void> _loadInitialUsers() async {
    setState(() {
      _isInitialLoading = true;
      _error = null;
      _users.clear();
      _lastDocument = null;
      _hasMore = true;
    });

    try {
      final page = await _auth.getUsersPage(limit: 20);
      if (!mounted) return;
      setState(() {
        _users.addAll(page.users);
        _lastDocument = page.lastDocument;
        _hasMore = page.hasMore;
      });
      _subscribeToPresenceUpdates();
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = e.toString());
    } finally {
      if (mounted) {
        setState(() => _isInitialLoading = false);
      }
    }
  }

  Future<void> _loadMoreUsers() async {
    if (_isLoadingMore || !_hasMore) return;

    setState(() => _isLoadingMore = true);
    try {
      final page = await _auth.getUsersPage(
        limit: 20,
        lastDocument: _lastDocument,
      );
      if (!mounted) return;
      setState(() {
        _users.addAll(page.users);
        _lastDocument = page.lastDocument;
        _hasMore = page.hasMore;
      });
      _subscribeToPresenceUpdates();
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = e.toString());
    } finally {
      if (mounted) {
        setState(() => _isLoadingMore = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC), // Rangi ya background tulivu (Light)
      appBar: AppBar(
        backgroundColor: const Color(0xFF075E54),
        elevation: 0.5, // Shadow kidogo kwa ajili ya kutofautisha
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'New Chat',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white),
            onPressed: _loadInitialUsers,
          ),
        ],
      ),
      body: _isInitialLoading
          ? const Center(
              child: CircularProgressIndicator(color: Color(0xFF22C55E)),
            )
          : _error != null
              ? _buildErrorState()
              : _users.isEmpty
                  ? _buildEmptyState()
                  : _buildUsersList(),
    );
  }

  Widget _buildUsersList() {
    return RefreshIndicator(
      onRefresh: _loadInitialUsers,
      color: const Color(0xFF22C55E),
      child: ListView.builder(
        controller: _scrollController,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        itemCount: _users.length + 2,
        itemBuilder: (context, index) {
          if (index == 0) {
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 8),
              child: Text(
                "CONTACTS ON APP (${_users.length})",
                style: TextStyle(
                  color: Colors.grey[600],
                  fontSize: 11,
                  letterSpacing: 1.2,
                  fontWeight: FontWeight.bold,
                ),
              ),
            );
          }

          if (index == _users.length + 1) {
            if (_isLoadingMore) {
              return const Padding(
                padding: EdgeInsets.symmetric(vertical: 14),
                child: Center(
                  child: CircularProgressIndicator(
                    color: Color(0xFF22C55E),
                    strokeWidth: 2.5,
                  ),
                ),
              );
            }
            if (!_hasMore) {
              return const SizedBox(height: 12);
            }
            return const SizedBox.shrink();
          }

          final user = _users[index - 1];
          return Container(
            margin: const EdgeInsets.symmetric(vertical: 4),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey.withAlpha(25)),
            ),
            child: ListTile(
              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  leading: Stack(
                    children: [
                      CircleAvatar(
                        radius: 24,
                        backgroundColor: const Color(0xFF22C55E).withAlpha(25),
                        backgroundImage: (user['profilePic'] as String?)?.isNotEmpty == true
                            ? NetworkImage(user['profilePic'] as String)
                            : null,
                        child: ((user['profilePic'] as String?)?.isNotEmpty == true)
                            ? null
                            : Text(
                                user['username'].toString().substring(0, 1).toUpperCase(),
                                style: const TextStyle(color: Color(0xFF22C55E), fontWeight: FontWeight.bold),
                              ),
                      ),
                  if (user['isOnline'] == true)
                    Positioned(
                      right: 0,
                      bottom: 0,
                      child: Container(
                        width: 12,
                        height: 12,
                        decoration: BoxDecoration(
                          color: const Color(0xFF22C55E),
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 2),
                        ),
                      ),
                    ),
                ],
              ),
              title: Text(
                user['username'] ?? 'Unknown User',
                style: const TextStyle(color: Colors.black87, fontWeight: FontWeight.w600, fontSize: 16),
              ),
              subtitle: Text(
                user['isOnline'] == true ? 'Online' : (user['email'] ?? ''),
                style: const TextStyle(color: Colors.black54, fontSize: 13),
                overflow: TextOverflow.ellipsis,
              ),
              trailing: const Icon(Icons.chevron_right, color: Colors.grey, size: 20),
              onTap: () => Navigator.of(context).pop(user),
            ),
          );
        },
      ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.cloud_off, size: 60, color: Colors.redAccent),
          const SizedBox(height: 16),
          const Text('Failed to load users', style: TextStyle(color: Colors.black87, fontSize: 16)),
          TextButton(
            onPressed: _loadInitialUsers,
            child: const Text("Try Again", style: TextStyle(color: Color(0xFF22C55E))),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(30.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.person_add_outlined, size: 80, color: Colors.grey[300]),
            const SizedBox(height: 20),
            const Text(
              'No other users found',
              style: TextStyle(color: Colors.black87, fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            const Text(
              'Create a second account to start a conversation.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.black54, fontSize: 14),
            ),
            const SizedBox(height: 25),
          ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF22C55E),
                elevation: 0,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 12),
              ),
              onPressed: () async {
                await Navigator.of(context).push(MaterialPageRoute(builder: (context) => const RegisterScreen()));
              },
              child: const Text('Register new user', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            ),
          ],
        
        ),
      ),
    );
  }
}