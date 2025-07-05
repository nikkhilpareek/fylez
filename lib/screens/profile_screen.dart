import 'package:flutter/material.dart';
import 'package:heroicons/heroicons.dart';
import 'auth_welcome_screen.dart';
import 'edit_profile_screen.dart';
import '../services/storage_service.dart';
import '../services/user_service.dart';
import '../models/file_item.dart';
import '../models/folder_item.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final StorageService _storageService = StorageService();
  bool _notificationsEnabled = true;
  bool _autoBackup = false;
  bool _isLoading = true;
  
  // Dynamic data
  List<FileItem> _files = [];
  List<FolderItem> _folders = [];
  int _totalStorageBytes = StorageService.maxStorageBytes; // 200MB
  int _usedStorageBytes = 0;
  int _sharedFilesCount = 0;

  @override
  void initState() {
    super.initState();
    _initializeAndLoadData();
  }

  Future<void> _initializeAndLoadData() async {
    await UserService.initialize();
    await _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final files = await _storageService.getFiles();
      final folders = await _storageService.getFolders();
      
      // Calculate used storage
      int totalUsed = 0;
      for (var file in files) {
        totalUsed += file.size;
      }
      
      // Calculate shared files (mock logic - files in folders are considered "shared")
      int sharedCount = files.where((file) => file.folderId != null).length;
      
      setState(() {
        _files = files;
        _folders = folders;
        _usedStorageBytes = totalUsed;
        _sharedFilesCount = sharedCount;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to load data: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  String get _formatStorageSize {
    if (_usedStorageBytes < 1024) return '$_usedStorageBytes B';
    if (_usedStorageBytes < 1024 * 1024) return '${(_usedStorageBytes / 1024).toStringAsFixed(1)} KB';
    return '${(_usedStorageBytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  String get _formatTotalStorageSize {
    if (_totalStorageBytes < 1024 * 1024) return '${(_totalStorageBytes / 1024).toStringAsFixed(0)} KB';
    return '${(_totalStorageBytes / (1024 * 1024)).toStringAsFixed(0)} MB';
  }

  double get _storageUsagePercentage {
    if (_totalStorageBytes == 0) return 0.0;
    return _usedStorageBytes / _totalStorageBytes;
  }

  String get _formatRemainingStorage {
    int remainingBytes = _totalStorageBytes - _usedStorageBytes;
    if (remainingBytes < 1024) return '$remainingBytes B';
    if (remainingBytes < 1024 * 1024) return '${(remainingBytes / 1024).toStringAsFixed(1)} KB';
    return '${(remainingBytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  Map<String, int> get _fileTypeBreakdown {
    Map<String, int> breakdown = {};
    for (var file in _files) {
      String extension = file.fileExtension.toLowerCase();
      if (extension.isEmpty) extension = 'other';
      breakdown[extension] = (breakdown[extension] ?? 0) + 1;
    }
    return breakdown;
  }

  int get _totalFilesSize {
    return _files.fold(0, (sum, file) => sum + file.size);
  }

  Future<void> _handleLogout(BuildContext context) async {
    // Show confirmation dialog
    final shouldLogout = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Logout'),
        content: const Text('Are you sure you want to logout?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(
              foregroundColor: Colors.red,
            ),
            child: const Text('Logout'),
          ),
        ],
      ),
    );

    if (shouldLogout == true && context.mounted) {
      // Clear user data on logout
      await UserService.clearUserData();
      
      // Navigate back to auth welcome screen
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(
          builder: (context) => const AuthWelcomeScreen(),
        ),
        (route) => false, // Remove all previous routes
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        backgroundColor: Colors.white,
        automaticallyImplyLeading: false,
        title: const Text(
          'Profile',
          style: TextStyle(
            fontWeight: FontWeight.w900,
            fontSize: 28,
          ),
        ),
        actions: [
          IconButton(
            onPressed: _loadData,
            icon: const HeroIcon(
              HeroIcons.arrowPath,
              size: 24,
            ),
            tooltip: 'Refresh',
          ),
          IconButton(
            onPressed: () => _showEditProfileDialog(context),
            icon: const HeroIcon(
              HeroIcons.pencilSquare,
              size: 24,
            ),
            tooltip: 'Edit Profile',
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: _isLoading 
        ? const Center(child: CircularProgressIndicator())
        : RefreshIndicator(
            onRefresh: _loadData,
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(24),
              child: Column(
          children: [
            // Profile Header
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                children: [
                  // Profile Picture
                  Stack(
                    children: [
                      Container(
                        width: 100,
                        height: 100,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(50),
                          border: Border.all(
                            color: const Color(0xFF2563EB),
                            width: 3,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.1),
                              blurRadius: 15,
                              offset: const Offset(0, 5),
                            ),
                          ],
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(47),
                          child: UserService.profileImageBytes != null
                              ? Image.memory(
                                  UserService.profileImageBytes!,
                                  fit: BoxFit.cover,
                                  width: 94,
                                  height: 94,
                                )
                              : Container(
                                  color: const Color(0xFF2563EB).withOpacity(0.1),
                                  child: const HeroIcon(
                                    HeroIcons.user,
                                    size: 50,
                                    color: Color(0xFF2563EB),
                                  ),
                                ),
                        ),
                      ),
                      Positioned(
                        bottom: 0,
                        right: 0,
                        child: Container(
                          width: 32,
                          height: 32,
                          decoration: BoxDecoration(
                            color: const Color(0xFF2563EB),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: Colors.white, width: 2),
                          ),
                          child: const HeroIcon(
                            HeroIcons.camera,
                            size: 16,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: 16),
                  
                  Text(
                    UserService.userName,
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  
                  const SizedBox(height: 4),
                  
                  Text(
                    UserService.userEmail,
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey.shade600,
                    ),
                  ),
                  
                  const SizedBox(height: 16),
                  
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: UserService.isPremiumUser 
                          ? const Color(0xFF059669).withOpacity(0.1)
                          : const Color(0xFF2563EB).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      UserService.membershipStatus,
                      style: TextStyle(
                        color: UserService.isPremiumUser 
                            ? const Color(0xFF059669)
                            : const Color(0xFF2563EB),
                        fontWeight: FontWeight.w600,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 24),
            
            // Storage Stats
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const HeroIcon(
                        HeroIcons.cloudArrowUp,
                        size: 20,
                        color: Color(0xFF2563EB),
                      ),
                      const SizedBox(width: 8),
                      const Text(
                        'Storage Usage',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Colors.black87,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '$_formatStorageSize used',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey.shade600,
                        ),
                      ),
                      Text(
                        'of $_formatTotalStorageSize',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '${(_storageUsagePercentage * 100).toStringAsFixed(1)}% used',
                        style: TextStyle(
                          fontSize: 12,
                          color: _storageUsagePercentage > 0.8 
                              ? Colors.red.shade600
                              : Colors.grey.shade500,
                          fontWeight: _storageUsagePercentage > 0.8 
                              ? FontWeight.w600 
                              : FontWeight.normal,
                        ),
                      ),
                      Text(
                        '$_formatRemainingStorage remaining',
                        style: TextStyle(
                          fontSize: 12,
                          color: _storageUsagePercentage > 0.8 
                              ? Colors.red.shade600
                              : Colors.grey.shade500,
                          fontWeight: _storageUsagePercentage > 0.8 
                              ? FontWeight.w600 
                              : FontWeight.normal,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  LinearProgressIndicator(
                    value: _storageUsagePercentage,
                    backgroundColor: Colors.grey.shade200,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      _storageUsagePercentage > 0.8 
                          ? Colors.red.shade600
                          : _storageUsagePercentage > 0.6
                              ? Colors.orange.shade600  
                              : const Color(0xFF2563EB),
                    ),
                  ),
                  if (_storageUsagePercentage > 0.8) ...[
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.red.shade50,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.red.shade200),
                      ),
                      child: Row(
                        children: [
                          HeroIcon(
                            HeroIcons.exclamationTriangle,
                            size: 16,
                            color: Colors.red.shade600,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              _storageUsagePercentage > 0.95 
                                  ? 'Storage almost full! Delete some files to free up space.'
                                  : 'Storage is getting full. Consider deleting unused files.',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.red.shade700,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
            
            const SizedBox(height: 24),
            
            // Quick Stats Row
            Row(
              children: [
                Expanded(
                  child: _buildStatCard(
                    title: 'Files',
                    value: '${_files.length}',
                    icon: HeroIcons.document,
                    color: const Color(0xFF059669),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildStatCard(
                    title: 'Folders',
                    value: '${_folders.length}',
                    icon: HeroIcons.folder,
                    color: const Color(0xFFDC2626),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildStatCard(
                    title: 'Shared',
                    value: '$_sharedFilesCount',
                    icon: HeroIcons.share,
                    color: const Color(0xFF7C3AED),
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 24),
            
            // Settings Section
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                children: [
                  _buildSettingsTile(
                    icon: HeroIcons.bell,
                    title: 'Notifications',
                    subtitle: 'Get notified about uploads and sync',
                    trailing: Switch(
                      value: _notificationsEnabled,
                      onChanged: (value) {
                        setState(() => _notificationsEnabled = value);
                      },
                      activeColor: const Color(0xFF2563EB),
                    ),
                  ),
                  _buildDivider(),
                  _buildSettingsTile(
                    icon: HeroIcons.arrowPath,
                    title: 'Auto Backup',
                    subtitle: 'Automatically backup new files',
                    trailing: Switch(
                      value: _autoBackup,
                      onChanged: (value) {
                        setState(() => _autoBackup = value);
                      },
                      activeColor: const Color(0xFF2563EB),
                    ),
                  ),
                  _buildDivider(),
                  _buildSettingsTile(
                    icon: HeroIcons.shieldCheck,
                    title: 'Security',
                    subtitle: 'Manage your account security',
                    trailing: const HeroIcon(
                      HeroIcons.chevronRight,
                      size: 16,
                      color: Colors.grey,
                    ),
                    onTap: () => _showSecurityDialog(context),
                  ),
                  _buildDivider(),
                  _buildSettingsTile(
                    icon: HeroIcons.questionMarkCircle,
                    title: 'Help & Support',
                    subtitle: 'Get help or contact support',
                    trailing: const HeroIcon(
                      HeroIcons.chevronRight,
                      size: 16,
                      color: Colors.grey,
                    ),
                    onTap: () => _showHelpDialog(context),
                  ),
                  _buildDivider(),
                  _buildSettingsTile(
                    icon: HeroIcons.informationCircle,
                    title: 'About Fylez',
                    subtitle: 'Version 1.0.0',
                    trailing: const HeroIcon(
                      HeroIcons.chevronRight,
                      size: 16,
                      color: Colors.grey,
                    ),
                    onTap: () => _showAboutDialog(context),
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 32),
            
            // Logout button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => _handleLogout(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red.shade600,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    HeroIcon(
                      HeroIcons.arrowRightOnRectangle,
                      size: 20,
                      color: Colors.white,
                    ),
                    SizedBox(width: 8),
                    Text(
                      'Logout',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: 20),
          ],
        ),
      ),
    ),
    );
  }

  Widget _buildStatCard({
    required String title,
    required String value,
    required HeroIcons icon,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: HeroIcon(
              icon,
              size: 20,
              color: color,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          Text(
            title,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey.shade600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSettingsTile({
    required HeroIcons icon,
    required String title,
    required String subtitle,
    required Widget trailing,
    VoidCallback? onTap,
  }) {
    return ListTile(
      onTap: onTap,
      leading: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: const Color(0xFF2563EB).withOpacity(0.1),
          borderRadius: BorderRadius.circular(10),
        ),
        child: HeroIcon(
          icon,
          size: 20,
          color: const Color(0xFF2563EB),
        ),
      ),
      title: Text(
        title,
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          color: Colors.black87,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: TextStyle(
          fontSize: 14,
          color: Colors.grey.shade600,
        ),
      ),
      trailing: trailing,
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
    );
  }

  Widget _buildDivider() {
    return Divider(
      height: 1,
      thickness: 1,
      color: Colors.grey.shade100,
      indent: 72,
      endIndent: 20,
    );
  }

  void _showEditProfileDialog(BuildContext context) async {
    final result = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (context) => const EditProfileScreen(),
      ),
    );

    // If profile was updated, refresh the data
    if (result == true && mounted) {
      await _initializeAndLoadData();
    }
  }

  void _showSecurityDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Security Settings'),
          content: const Text('Security features coming soon!\n\n• Two-factor authentication\n• Password management\n• Login history'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('OK'),
            ),
          ],
        );
      },
    );
  }

  void _showHelpDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Help & Support'),
          content: const Text('Need help?\n\n• Check our FAQ section\n• Contact support: support@fylez.io\n• Join our community forum'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('OK'),
            ),
          ],
        );
      },
    );
  }

  void _showAboutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('About Fylez'),
          content: const Text('Fylez v1.0.0\n\nYour secure, decentralized file storage solution built on blockchain technology.\n\n© 2025 Fylez Inc.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('OK'),
            ),
          ],
        );
      },
    );
  }
}
