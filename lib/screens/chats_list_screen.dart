import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:async';
import '../services/auth_service.dart';
import 'chat_screen.dart';
import 'users_selection_screen.dart';
import 'calls_screen.dart';
import 'settings_screen.dart';

class ChatsListScreen extends StatefulWidget {
  const ChatsListScreen({super.key});

  @override
  State<ChatsListScreen> createState() => _ChatsListScreenState();
}

class _ChatsListScreenState extends State<ChatsListScreen> {
  // Services & Controllers
  late final AuthService _auth;
  late final Stream<List<Map<String, dynamic>>> _conversationsStream;
  final TextEditingController _searchController = TextEditingController();
  final Map<String, bool> _onlineByUserId = {};
  final List<StreamSubscription<QuerySnapshot<Map<String, dynamic>>>>
      _presenceSubscriptions = [];
  Set<String> _presenceUserIds = {};

  // State Variables
  int _selectedIndex = 0;
  String _searchQuery = "";
  int _chatsBadgeCount = 0;
  final int _callsBadgeCount = 0; // Made final to fix the lint warning

  @override
  void initState() {
    super.initState();
    _auth = AuthService();
    _conversationsStream = _auth.getConversationsStream().asBroadcastStream();
    _listenToBadges();
  }

  @override
  void dispose() {
    _cancelPresenceSubscriptions();
    _searchController.dispose();
    super.dispose();
  }

  void _cancelPresenceSubscriptions() {
    for (final sub in _presenceSubscriptions) {
      sub.cancel();
    }
    _presenceSubscriptions.clear();
    _presenceUserIds = {};
  }

  void _syncPresenceSubscriptions(List<Map<String, dynamic>> conversations) {
    final userIds = conversations
        .map((chat) => chat['userId'] as String?)
        .whereType<String>()
        .where((id) => id.isNotEmpty)
        .toSet();

    if (_presenceUserIds.length == userIds.length &&
        _presenceUserIds.containsAll(userIds)) {
      return;
    }

    _cancelPresenceSubscriptions();
    _presenceUserIds = userIds;
    if (userIds.isEmpty) return;

    final idsList = userIds.toList();
    const chunkSize = 10;
    for (var i = 0; i < idsList.length; i += chunkSize) {
      final end = (i + chunkSize < idsList.length)
          ? i + chunkSize
          : idsList.length;
      final chunk = idsList.sublist(i, end);

      final sub = FirebaseFirestore.instance
          .collection('users')
          .where(FieldPath.documentId, whereIn: chunk)
          .snapshots()
          .listen((snapshot) {
            if (!mounted) return;
            setState(() {
              for (final doc in snapshot.docs) {
                _onlineByUserId[doc.id] = doc.data()['isOnline'] == true;
              }
            });
          });

      _presenceSubscriptions.add(sub);
    }
  }

  void _listenToBadges() {
    _conversationsStream.listen((conversations) {
      int totalUnread = 0;
      for (final chat in conversations) {
        final count = chat['unreadCount'];
        if (count is int) totalUnread += count;
      }
      if (mounted) {
        setState(() => _chatsBadgeCount = totalUnread);
      }
    });
  }

  String _formatTime(dynamic timestamp) {
    if (timestamp == null) return '';
    try {
      final dateTime = timestamp.toDate();
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      final yesterday = today.subtract(const Duration(days: 1));
      final msgDate = DateTime(dateTime.year, dateTime.month, dateTime.day);

      if (msgDate == today) {
        return '${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
      } else if (msgDate == yesterday) {
        return 'Yesterday';
      } else {
        return '${msgDate.day}/${msgDate.month}/${msgDate.year}';
      }
    } catch (e) {
      return '';
    }
  }

  Widget _buildMessageStatusIcon(String status) {
    switch (status) {
      case 'read':
        return const Icon(Icons.done_all, size: 16, color: Color(0xFF34B7F1));
      case 'delivered':
        return const Icon(Icons.done_all, size: 16, color: Color(0xFF9E9E9E));
      case 'sent':
      default:
        return const Icon(Icons.done, size: 16, color: Color(0xFF9E9E9E));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: _selectedIndex == 0 ? _buildModernAppBar() : null,
      drawer: _buildSideDrawer(),
      body: IndexedStack(
        index: _selectedIndex,
        children: [
          _buildChatsTabBody(),
          const CallsScreen(),
          const SettingsScreen(),
        ],
      ),
      bottomNavigationBar: _buildModernBottomNav(),
      floatingActionButton: _selectedIndex == 0 ? _buildFAB() : null,
    );
  }

  Widget _buildSideDrawer() {
    final user = _auth.getCurrentUser();
    return Drawer(
      child: Column(
        children: [
          UserAccountsDrawerHeader(
            // FIXED: backgroundColor parameter replaced with decoration
            decoration: const BoxDecoration(color: Color(0xFF075E54)),
            accountName: Text(user?.displayName ?? "Chat User"),
            accountEmail: Text(user?.email ?? ""),
            currentAccountPicture: CircleAvatar(
              backgroundColor: Colors.white,
              child: Text(
                (user?.email?[0] ?? "U").toUpperCase(),
                style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Color(0xFF075E54)),
              ),
            ),
          ),
          ListTile(
            leading: const Icon(Icons.group_outlined),
            title: const Text("New Group"),
            onTap: () => Navigator.pop(context),
          ),
          ListTile(
            leading: const Icon(Icons.star_outline),
            title: const Text("Starred Messages"),
            onTap: () => Navigator.pop(context),
          ),
          ListTile(
            leading: const Icon(Icons.settings_outlined),
            title: const Text("Settings"),
            onTap: () {
              Navigator.pop(context);
              setState(() => _selectedIndex = 2);
            },
          ),
          const Spacer(),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.logout, color: Colors.redAccent),
            title: const Text("Logout", style: TextStyle(color: Colors.redAccent)),
            onTap: () async {
              await _auth.logout();
            },
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  PreferredSizeWidget _buildModernAppBar() {
    return AppBar(
      backgroundColor: const Color(0xFF075E54),
      elevation: 0.5,
      centerTitle: true,
      leading: Builder(
        builder: (context) => IconButton(
          icon: const Icon(Icons.menu, color: Colors.white),
          onPressed: () => Scaffold.of(context).openDrawer(),
        ),
      ),
      title: const Text(
        "ChatApp",
        style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 22),
      ),
      actions: [
        IconButton(icon: const Icon(Icons.camera_alt_outlined, color: Colors.white), onPressed: () {}),
        PopupMenuButton<String>(
          icon: const Icon(Icons.more_vert, color: Colors.white),
          onSelected: (value) {
            if (value == 'Settings') setState(() => _selectedIndex = 2);
          },
          itemBuilder: (BuildContext context) {
            return {'New group', 'Starred messages', 'Settings'}.map((String choice) {
              return PopupMenuItem<String>(value: choice, child: Text(choice));
            }).toList();
          },
        ),
      ],
    );
  }

  Widget _buildChatsTabBody() {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              // FIXED: Changed withOpacity to withAlpha for modern Flutter
              border: Border.all(color: Colors.grey.withAlpha(51)), 
            ),
            child: TextField(
              controller: _searchController,
              onChanged: (value) => setState(() => _searchQuery = value.toLowerCase()),
              decoration: const InputDecoration(
                icon: Icon(Icons.search, color: Colors.grey),
                hintText: "Search conversations...",
                border: InputBorder.none,
                hintStyle: TextStyle(color: Colors.grey),
              ),
            ),
          ),
        ),
        Expanded(child: _buildChatsList()),
      ],
    );
  }

  Widget _buildModernBottomNav() {
    return NavigationBar(
      backgroundColor: Colors.white,
      elevation: 5,
      height: 70,
      selectedIndex: _selectedIndex,
      onDestinationSelected: (index) => setState(() => _selectedIndex = index),
      destinations: [
        NavigationDestination(
          icon: Badge(
            label: _chatsBadgeCount > 0 ? Text('$_chatsBadgeCount') : null,
            isLabelVisible: _chatsBadgeCount > 0,
            child: const Icon(Icons.chat_outlined),
          ),
          selectedIcon: Badge(
            label: _chatsBadgeCount > 0 ? Text('$_chatsBadgeCount') : null,
            isLabelVisible: _chatsBadgeCount > 0,
            child: const Icon(Icons.chat),
          ),
          label: 'Chats',
        ),
        NavigationDestination(
          icon: Badge(
            label: _callsBadgeCount > 0 ? Text('$_callsBadgeCount') : null,
            isLabelVisible: _callsBadgeCount > 0,
            child: const Icon(Icons.call_outlined),
          ),
          label: 'Calls',
        ),
        const NavigationDestination(
          icon: Icon(Icons.settings_outlined),
          label: 'Settings',
        ),
      ],
    );
  }

  Widget _buildFAB() {
    return FloatingActionButton(
      backgroundColor: const Color(0xFF25D366),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      onPressed: () async {
        final selectedUser = await Navigator.of(context).push(
          MaterialPageRoute(builder: (context) => const UsersSelectionScreen()),
        );
        if (selectedUser != null && mounted) {
          await Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) => ChatScreen(selectedUser: selectedUser),
            ),
          );
        }
      },
      child: const Icon(Icons.add_comment, color: Colors.white),
    );
  }

  Widget _buildChatsList() {
    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: _conversationsStream,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator(color: Color(0xFF25D366)));
        }

        var conversations = snapshot.data ?? [];
        if (_searchQuery.isNotEmpty) {
          conversations = conversations.where((chat) {
            final name = chat['username'].toString().toLowerCase();
            return name.contains(_searchQuery);
          }).toList();
        }

        _syncPresenceSubscriptions(conversations);

        if (conversations.isEmpty) {
          return const Center(child: Text("No conversations found"));
        }

        return ListView.builder(
          padding: const EdgeInsets.symmetric(horizontal: 14),
          itemCount: conversations.length,
          itemBuilder: (context, index) => _buildWhatsAppCard(conversations[index]),
        );
      },
    );
  }

  Widget _buildWhatsAppCard(Map<String, dynamic> chat) {
    final currentUserId = _auth.getCurrentUser()?.uid;
    final isMe = chat['lastMessageSenderId'] == currentUserId;
    final int unreadCount = chat['unreadCount'] ?? 0;
    final status = chat['lastMessageStatus'] ?? 'sent';
    final userId = chat['userId'] as String?;
    final isOnline = userId != null
        ? (_onlineByUserId[userId] ?? (chat['isOnline'] == true))
        : (chat['isOnline'] == true);

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 5),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        // FIXED: Replaced withOpacity
        border: Border.all(color: Colors.grey.withAlpha(25)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(5),
            blurRadius: 5,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ListTile(
        onTap: () async {
          await _auth.markMessagesAsRead(chat['chatId']);
          if (!mounted) return;
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) => ChatScreen(
                selectedUser: {
                  'uid': chat['userId'],
                  'username': chat['username'],
                  'chatId': chat['chatId'],
                  'profilePic': chat['profilePic'],
                },
              ),
            ),
          );
        },
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        leading: Stack(
          children: [
            CircleAvatar(
              radius: 26,
              backgroundColor: const Color(0xFF22C55E).withAlpha(25),
              backgroundImage: (chat['profilePic'] as String?)?.isNotEmpty == true
                  ? NetworkImage(chat['profilePic'] as String)
                  : null,
              child: ((chat['profilePic'] as String?)?.isNotEmpty == true)
                  ? null
                  : Text(
                      chat['username'][0].toUpperCase(),
                      style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF22C55E)),
                    ),
            ),
            if (isOnline)
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
        title: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Text(
                chat['username'],
                style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16, color: Colors.black87),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            Text(
              _formatTime(chat['lastMessageTime']),
              style: TextStyle(
                color: unreadCount > 0 ? const Color(0xFF25D366) : Colors.grey,
                fontSize: 11,
              ),
            ),
          ],
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 4),
          child: Row(
            children: [
              if (isMe) ...[
                _buildMessageStatusIcon(status),
                const SizedBox(width: 4),
              ],
              Expanded(
                child: Text(
                  chat['lastMessage'] ?? "",
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 13,
                    color: unreadCount > 0 ? Colors.black87 : Colors.black54,
                    fontWeight: unreadCount > 0 ? FontWeight.w500 : FontWeight.normal,
                  ),
                ),
              ),
              if (unreadCount > 0)
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: const BoxDecoration(color: Color(0xFF25D366), shape: BoxShape.circle),
                  child: Text(
                    '$unreadCount',
                    style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
