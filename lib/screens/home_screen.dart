import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:heroicons/heroicons.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/file_item.dart';
import '../services/storage_service.dart';
import '../services/user_service.dart';
import '../widgets/file_card.dart';
import '../widgets/upload_zone.dart';
import '../widgets/empty_state.dart';
import '../widgets/storage_stats_widget.dart';
import '../widgets/info_dialog.dart';
import '../widgets/share_file_dialog.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final StorageService _storageService = StorageService();
  List<FileItem> _files = [];
  List<FileItem> _sharedFiles = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadFiles();
  }

  Future<void> _loadFiles() async {
    setState(() => _isLoading = true);
    try {
      final files = await _storageService.getFiles(UserService.userEmail);
      final sharedFiles = await _storageService.getSharedWithMe(UserService.userEmail);
      setState(() {
        _files = files;
        _sharedFiles = sharedFiles;
      });
    } catch (e) {
      _showErrorSnackBar('Failed to load files: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _pickAndUploadFile() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        allowMultiple: true,
        type: FileType.any,
      );

      if (result != null) {
        setState(() => _isLoading = true);
        
        for (var file in result.files) {
          if (file.bytes != null) {
            await _storageService.uploadFile(
              UserService.userEmail,
              file.name,
              file.bytes!,
              file.size,
            );
          }
        }
        
        await _loadFiles();
        _showSuccessSnackBar('${result.files.length} file(s) uploaded successfully');
      }
    } catch (e) {
      _showErrorSnackBar('Failed to upload file: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _deleteFile(String fileId, String cid) async {
    try {
      setState(() => _isLoading = true);
      await _storageService.deleteFile(UserService.userEmail, fileId, cid: cid);
      await _loadFiles();
      _showSuccessSnackBar('File deleted successfully');
    } catch (e) {
      _showErrorSnackBar('Failed to delete file: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _renameFile(String fileId, String newName) async {
    try {
      setState(() => _isLoading = true);
      await _storageService.renameFile(UserService.userEmail, fileId, newName);
      await _loadFiles();
      _showSuccessSnackBar('File renamed successfully');
    } catch (e) {
      _showErrorSnackBar('Failed to rename file: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _downloadFile(FileItem file) async {
    try {
      // Construct IPFS gateway URL for the file
      final String downloadUrl = 'https://gateway.pinata.cloud/ipfs/${file.blockchainHash}';
      
      // Launch the URL in the browser to download the file
      final Uri uri = Uri.parse(downloadUrl);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
        _showSuccessSnackBar('Download started for ${file.name}');
      } else {
        throw Exception('Could not launch download URL');
      }
    } catch (e) {
      _showErrorSnackBar('Failed to download file: $e');
    }
  }

  Future<void> _shareFile(FileItem file) async {
    await showDialog(
      context: context,
      builder: (context) => ShareFileDialog(file: file),
    );
    // Refresh files after sharing
    await _loadFiles();
  }

  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _showInfoDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => const InfoDialog(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        backgroundColor: Colors.white,
        automaticallyImplyLeading: false,
        title: Row(
          children: [
            Image.asset(
              'assets/images/fylez.png',
              width: 44,
              height: 44,
            ),
            const SizedBox(width: 8),
            const Text(
              'Fylez',
              style: TextStyle(
                fontWeight: FontWeight.w900,
                fontSize: 28,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            onPressed: () => _showInfoDialog(context),
            icon: const HeroIcon(
              HeroIcons.informationCircle,
              size: 24,
            ),
            tooltip: 'How it works',
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadFiles,
              child: (_files.isEmpty && _sharedFiles.isEmpty)
                  ? EmptyState(onUpload: _pickAndUploadFile)
                  : CustomScrollView(
                      slivers: [
                        SliverToBoxAdapter(
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: UploadZone(onTap: _pickAndUploadFile),
                          ),
                        ),
                        SliverToBoxAdapter(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            child: StorageStatsWidget(files: _files),
                          ),
                        ),
                        const SliverToBoxAdapter(child: SizedBox(height: 16)),
                        
                        // Files Shared with You section
                        if (_sharedFiles.isNotEmpty) ...[
                          SliverToBoxAdapter(
                            child: Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                              child: Row(
                                children: [
                                  const HeroIcon(HeroIcons.share, size: 20),
                                  const SizedBox(width: 8),
                                  Text(
                                    'Files Shared with You',
                                    style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                                  ),
                                  const SizedBox(width: 8),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: Colors.blue.shade100,
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Text(
                                      '${_sharedFiles.length}',
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.blue.shade700,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          SliverPadding(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            sliver: SliverGrid(
                              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: 2,
                                mainAxisSpacing: 16,
                                crossAxisSpacing: 16,
                                childAspectRatio: 1.2,
                              ),
                              delegate: SliverChildBuilderDelegate(
                                (context, index) {
                                  final file = _sharedFiles[index];
                                  return FileCard(
                                    file: file,
                                    isSharedFile: true,
                                    onDelete: () {}, // Shared files can't be deleted by non-owners
                                    onRename: (newName) {}, // Shared files can't be renamed by non-owners
                                    onDownload: () => _downloadFile(file),
                                    // No move, copy, or share options for shared files
                                  );
                                },
                                childCount: _sharedFiles.length,
                              ),
                            ),
                          ),
                          const SliverToBoxAdapter(child: SizedBox(height: 24)),
                        ],
                        
                        // Recent Uploads section
                        if (_files.isNotEmpty) ...[
                          SliverToBoxAdapter(
                            child: Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                              child: Row(
                                children: [
                                  const HeroIcon(HeroIcons.folder, size: 20),
                                  const SizedBox(width: 8),
                                  Text(
                                    _sharedFiles.isNotEmpty ? 'My Recent Uploads' : 'Recent Uploads',
                                    style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          SliverPadding(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            sliver: SliverGrid(
                              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: 2,
                                mainAxisSpacing: 16,
                                crossAxisSpacing: 16,
                                childAspectRatio: 1.2,
                              ),
                              delegate: SliverChildBuilderDelegate(
                                (context, index) {
                                  final file = _files[index];
                                  return FileCard(
                                    file: file,
                                    onDelete: () => _deleteFile(file.id, file.blockchainHash),
                                    onRename: (newName) => _renameFile(file.id, newName),
                                    onDownload: () => _downloadFile(file),
                                    onShare: () => _shareFile(file),
                                  );
                                },
                                childCount: _files.length,
                              ),
                            ),
                          ),
                        ],
                        
                        const SliverToBoxAdapter(child: SizedBox(height: 32)),
                      ],
                    ),
            ),
    );
  }
}
