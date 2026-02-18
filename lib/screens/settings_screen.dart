import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';
import '../services/auth_service.dart';
import 'privacy_security_screen.dart';
import 'about_screen.dart';
import 'chats_list_screen.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  late final AuthService _auth;
  String? _username;
  String? _email;
  String? _profilePicUrl;
  File? _imageFile;
  Uint8List? _webImageBytes;
  bool _isLoading = false;
  bool _isUploadingPhoto = false;

  @override
  void initState() {
    super.initState();
    _auth = AuthService();
    _loadUserInfo();
  }

  Future<void> _loadUserInfo() async {
    final user = _auth.getCurrentUser();
    try {
      if (user == null) return;

      final doc = await _auth.getUserDocument(user.uid);
      if (mounted) {
        setState(() {
          _email = user.email;
          _username = doc?['username'] ?? 'User';
          _profilePicUrl = (doc?['profilePic'] as String?) ?? user.photoURL;
        });
      }
    } catch (e) {
      debugPrint('Error loading user info: $e');
    }
  }

  Future<void> _pickImage() async {
    final ImagePicker picker = ImagePicker();
    final XFile? pickedFile = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 75,
      maxWidth: 1080,
    );

    if (pickedFile == null) return;

    setState(() {
      _isUploadingPhoto = true;
    });

    try {
      String downloadUrl;
      if (kIsWeb) {
        final bytes = await pickedFile.readAsBytes();
        setState(() => _webImageBytes = bytes); // local preview while uploading
        downloadUrl = await _auth.updateProfilePhoto(fileBytes: bytes);
      } else {
        setState(() => _imageFile = File(pickedFile.path)); // local preview
        downloadUrl = await _auth.updateProfilePhoto(filePath: pickedFile.path);
      }
      if (!mounted) return;

      setState(() {
        _profilePicUrl = downloadUrl;
        _imageFile = null; // switch to remote persisted image
        _webImageBytes = null; // switch to remote persisted image
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Profile picture updated successfully!')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to upload profile picture: $e')),
      );
    } finally {
      if (mounted) {
        setState(() => _isUploadingPhoto = false);
      }
    }
  }

  void _editUsername() {
    final controller = TextEditingController(text: _username);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text(
          'Edit Username',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        content: TextField(
          controller: controller,
          decoration: InputDecoration(
            labelText: 'New Username',
            hintText: 'Enter your name',
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF075E54),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            onPressed: () async {
              if (controller.text.isNotEmpty) {
                try {
                  await _auth.updateUsername(controller.text);
                  if (mounted) {
                    setState(() => _username = controller.text);
                    Navigator.of(this.context).pop();
                    ScaffoldMessenger.of(this.context).showSnackBar(
                      const SnackBar(
                        content: Text('Username updated successfully!'),
                      ),
                    );
                  }
                } catch (e) {
                  if (mounted) {
                    Navigator.of(this.context).pop();
                    ScaffoldMessenger.of(this.context).showSnackBar(
                      SnackBar(content: Text('Error: $e')),
                    );
                  }
                }
              }
            },
            child: const Text('Save', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Future<void> _logout() async {
    setState(() => _isLoading = true);
    try {
      await _auth.logout();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF0F2F5),
      // Inafanya body ianze kuanzia juu kabisa ya kioo (chini ya status bar)
      extendBodyBehindAppBar: true,
      appBar: AppBar(
       backgroundColor: const Color(0xFF075E54), // AppBar haina rangi
        elevation: 0, // Inatoa kivuli
        centerTitle: true,
        title: const Text(
          'Settings',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
        leading: Padding(
          padding: const EdgeInsets.all(8.0),
          child: IconButton(
            icon: const Icon(
              Icons.arrow_back_ios_new_rounded,
              color: Colors.white,
              size: 18,
            ),
            onPressed: () {
              if (Navigator.canPop(context)) {
                Navigator.pop(context);
              } else {
                Navigator.of(context).pushReplacement(
                  MaterialPageRoute(
                    builder: (_) => const ChatsListScreen(),
                  ),
                );
              }
            },
          ),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: IconButton(
              icon: const Icon(Icons.more_vert, color: Colors.white),
              onPressed: () {},
            ),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: Color(0xFF128C7E)),
            )
          : SizedBox(
              // Unaweza kuongeza gradient hapa kama unataka background ifanane zaidi na Security screen
              width: double.infinity,
              height: double.infinity,
              child: ListView(
                // SafeArea inahakikisha kadi ya kwanza haijifichi nyuma ya AppBar
                padding: EdgeInsets.only(
                  top: MediaQuery.of(context).padding.top + 70,
                  left: 16,
                  right: 16,
                  bottom: 20,
                ),
                children: [
                  /// PROFILE CARD
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.06),
                          blurRadius: 20,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        Stack(
                          alignment: Alignment.center,
                          children: [
                            Container(
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: const Color(0xFF25D366),
                                  width: 3,
                                ),
                              ),
                              child: CircleAvatar(
                                radius: 55,
                                backgroundColor: const Color(0xFF128C7E),
                                backgroundImage: _webImageBytes != null
                                    ? MemoryImage(_webImageBytes!)
                                    : _imageFile != null
                                    ? FileImage(_imageFile!)
                                    : (_profilePicUrl != null
                                          ? NetworkImage(_profilePicUrl!)
                                          : null),
                                child: (_imageFile == null &&
                                        _webImageBytes == null &&
                                        _profilePicUrl == null)
                                    ? Text(
                                        (_username?.isNotEmpty == true
                                                ? _username![0]
                                                : 'U')
                                            .toUpperCase(),
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 40,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      )
                                    : null,
                              ),
                            ),
                            if (_isUploadingPhoto)
                              Container(
                                width: 110,
                                height: 110,
                                decoration: BoxDecoration(
                                  color: Colors.black.withAlpha(90),
                                  shape: BoxShape.circle,
                                ),
                                child: const Center(
                                  child: CircularProgressIndicator(
                                    color: Colors.white,
                                    strokeWidth: 2.5,
                                  ),
                                ),
                              ),
                            Positioned(
                              bottom: 0,
                              right: 4,
                              child: GestureDetector(
                                onTap: _pickImage,
                                child: Container(
                                  padding: const EdgeInsets.all(10),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF075E54),
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: Colors.white,
                                      width: 3,
                                    ),
                                  ),
                                  child: const Icon(
                                    Icons.camera_alt,
                                    size: 20,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              _username ?? 'User',
                              style: const TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF075E54),
                              ),
                            ),
                            IconButton(
                              icon: const Icon(
                                Icons.edit_square,
                                size: 20,
                                color: Color(0xFF25D366),
                              ),
                              onPressed: _editUsername,
                            ),
                          ],
                        ),
                        Text(
                          _email ?? '',
                          style: TextStyle(
                            fontSize: 15,
                            color: Colors.grey.shade600,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 25),

                  /// SETTINGS OPTIONS
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.04),
                          blurRadius: 15,
                          offset: const Offset(0, 5),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        _buildListTile(
                          Icons.notifications_active_rounded,
                          const Color(0xFFFFEFEF),
                          const Color(0xFFFF5252),
                          'Notifications',
                          onTap: () {},
                        ),
                        const Divider(height: 1, indent: 70),
                        _buildListTile(
                          Icons.security_rounded,
                          const Color(0xFFE8F5E9),
                          const Color(0xFF4CAF50),
                          'Privacy & Security',
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) =>
                                    const PrivacySecurityScreen(),
                              ),
                            );
                          },
                        ),
                        const Divider(height: 1, indent: 70),
                        _buildListTile(
                          Icons.info_outline_rounded,
                          const Color(0xFFE3F2FD),
                          const Color(0xFF2196F3),
                          'About',
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const AboutScreen(),
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 30),

                  /// LOGOUT BUTTON
                  ElevatedButton.icon(
                    onPressed: _isLoading ? null : _logout,
                    icon: const Icon(Icons.logout_rounded, color: Colors.white),
                    label: const Text(
                      'Logout Account',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red.shade600,
                      minimumSize: const Size(double.infinity, 55),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(18),
                      ),
                      elevation: 2,
                    ),
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
    );
  }

  /// WIDGET ILIYOBORESHWA YA LIST TILE
  Widget _buildListTile(
    IconData icon,
    Color bgColor,
    Color iconColor,
    String title, {
    VoidCallback? onTap,
  }) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 5),
      leading: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(icon, color: iconColor, size: 24),
      ),
      title: Text(
        title,
        style: const TextStyle(
          color: Colors.black87,
          fontWeight: FontWeight.w600,
          fontSize: 16,
        ),
      ),
      trailing: const Icon(
        Icons.arrow_forward_ios_rounded,
        color: Colors.grey,
        size: 16,
      ),
      onTap: onTap,
    );
  }
}
