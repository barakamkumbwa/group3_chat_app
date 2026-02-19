import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';
import '../services/auth_service.dart'; // Hakikisha path ni sahihi

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final AuthService _auth = AuthService();
  bool _isUploading = false;
  String? _localImagePath;
  Uint8List? _localImageBytes;
  Map<String, dynamic>? _userData;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  /// Inapakua data za user (Username, Email, Profile Pic) kutoka Firestore
  Future<void> _loadUserData() async {
    final user = _auth.getCurrentUser();
    if (user != null) {
      final data = await _auth.getUserDocument(user.uid);
      setState(() {
        _userData = data;
      });
    }
  }

  /// Function ya kuchagua picha na kui-upload
  Future<void> _updateImage() async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 70,
    );

    if (image != null) {
      setState(() {
        _isUploading = true;
      });

      try {
        if (kIsWeb) {
          final bytes = await image.readAsBytes();
          setState(() => _localImageBytes = bytes);
          await _auth.updateProfilePhoto(fileBytes: bytes);
        } else {
          setState(() => _localImagePath = image.path);
          await _auth.updateProfilePhoto(filePath: image.path);
        }
        await _loadUserData();

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Profile photo updated successfully!")),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("Failed to update: $e"), backgroundColor: Colors.red),
          );
        }
      } finally {
        if (mounted) {
          setState(() {
            _isUploading = false;
            _localImageBytes = null;
          });
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: const Color(0xFF075E54),
        elevation: 0,
        title: const Text("Profile", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Column(
        children: [
          // SEHEMU YA JUU (HEADER)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.only(bottom: 30),
            decoration: const BoxDecoration(
              color: Color(0xFF075E54),
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(40),
                bottomRight: Radius.circular(40),
              ),
            ),
            child: Column(
              children: [
                const SizedBox(height: 20),
                _buildProfileAvatar(),
                const SizedBox(height: 15),
                Text(
                  _userData?['username'] ?? "Loading...",
                  style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold),
                ),
                Text(
                  _userData?['email'] ?? "",
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.8),
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 30),

          // SEHEMU YA CHINI (DETAILS)
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: ListView(
                children: [
                  _buildInfoTile(Icons.person_outline, "Username", _userData?['username'] ?? ""),
                  _buildInfoTile(Icons.email_outlined, "Email Address", _userData?['email'] ?? ""),
                  _buildInfoTile(Icons.calendar_today_outlined, "Joined", "Member since 2024"),
                  const SizedBox(height: 40),
                  
                  // Kitufe cha kuedit jina au mambo mengine
                  ElevatedButton.icon(
                    onPressed: () {
                      // Logic ya kuedit profile
                    },
                    icon: const Icon(Icons.edit_note_rounded),
                    label: const Text("Edit Profile Details"),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF075E54),
                      foregroundColor: Colors.white,
                      minimumSize: const Size(double.infinity, 50),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Avatar Widget yenye uwezo wa kuedit picha
  Widget _buildProfileAvatar() {
    return Center(
      child: Stack(
        children: [
          Container(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white, width: 4),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.2),
                  blurRadius: 15,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: CircleAvatar(
              radius: 65,
              backgroundColor: Colors.grey.shade200,
              backgroundImage: _localImageBytes != null
                  ? MemoryImage(_localImageBytes!)
                  : _localImagePath != null
                  ? FileImage(File(_localImagePath!))
                  : (_userData?['profilePic'] != null 
                      ? NetworkImage(_userData?['profilePic']) 
                      : const AssetImage('assets/images/default_avatar.png')) as ImageProvider,
              child: _isUploading
                  ? const CircularProgressIndicator(color: Color(0xFF075E54))
                  : null,
            ),
          ),
          Positioned(
            bottom: 2,
            right: 2,
            child: GestureDetector(
              onTap: _isUploading ? null : _updateImage,
              child: Container(
                padding: const EdgeInsets.all(10),
                decoration: const BoxDecoration(
                  color: Color(0xFF25D366), // WhatsApp light green color
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.camera_alt_rounded, color: Colors.white, size: 20),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// ListTile ya taarifa za mtumiaji
  Widget _buildInfoTile(IconData icon, String label, String value) {
    return Container(
      margin: const EdgeInsets.only(bottom: 15),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Icon(icon, color: const Color(0xFF075E54), size: 24),
          const SizedBox(width: 15),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: const TextStyle(color: Colors.grey, fontSize: 12)),
              Text(value, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            ],
          ),
        ],
      ),
    );
  }
}
