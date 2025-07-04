import 'package:flutter/material.dart';
import 'package:heroicons/heroicons.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/file_item.dart';
import '../models/folder_item.dart';
import '../services/storage_service.dart';
import '../widgets/file_card.dart';
import '../widgets/folder_card.dart';
import '../widgets/folder_picker_dialog.dart';
import '../widgets/storage_stats_widget.dart';

enum SortBy { name, size, date, type }
enum SortOrder { ascending, descending }

class FilesScreen extends StatefulWidget {
  const FilesScreen({super.key});

  @override
  State<FilesScreen> createState() => _FilesScreenState();
}

class _FilesScreenState extends State<FilesScreen> {
  final StorageService _storageService = StorageService();
  List<FileItem> _files = [];
  List<FolderItem> _folders = [];
  bool _isLoading = false;
  SortBy _sortBy = SortBy.date;
  SortOrder _sortOrder = SortOrder.descending;
  String? _currentFolderId; // null means we're in root directory
  final List<String> _navigationStack = []; // For breadcrumb navigation

  @override
  void initState() {
    super.initState();
    _loadFiles();
  }

  Future<void> _loadFiles() async {
    setState(() => _isLoading = true);
    try {
      final files = await _storageService.getFiles();
      final folders = await _storageService.getFolders();
      setState(() {
        _files = _sortFiles(files);
        _folders = folders;
      });
    } catch (e) {
      _showErrorSnackBar('Failed to load files: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  List<FileItem> _sortFiles(List<FileItem> files) {
    final sortedFiles = List<FileItem>.from(files);
    
    switch (_sortBy) {
      case SortBy.name:
        sortedFiles.sort((a, b) => a.name.compareTo(b.name));
        break;
      case SortBy.size:
        sortedFiles.sort((a, b) => a.size.compareTo(b.size));
        break;
      case SortBy.date:
        sortedFiles.sort((a, b) => a.uploadDate.compareTo(b.uploadDate));
        break;
      case SortBy.type:
        sortedFiles.sort((a, b) => a.fileExtension.compareTo(b.fileExtension));
        break;
    }
    
    if (_sortOrder == SortOrder.descending) {
      return sortedFiles.reversed.toList();
    }
    return sortedFiles;
  }

  void _changeSortBy(SortBy newSortBy) {
    setState(() {
      if (_sortBy == newSortBy) {
        _sortOrder = _sortOrder == SortOrder.ascending 
            ? SortOrder.descending 
            : SortOrder.ascending;
      } else {
        _sortBy = newSortBy;
        _sortOrder = SortOrder.ascending;
      }
      _files = _sortFiles(_files);
    });
  }

  Future<void> _deleteFile(String fileId, String cid) async {
    try {
      setState(() => _isLoading = true);
      await _storageService.deleteFile(fileId, cid: cid);
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
      await _storageService.renameFile(fileId, newName);
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

  Future<void> _showCreateFolderDialog() async {
    final controller = TextEditingController();
    final folderName = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Create New Folder'),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(
            labelText: 'Folder name',
            hintText: 'Enter folder name',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              final name = controller.text.trim();
              Navigator.of(context).pop(name.isNotEmpty ? name : null);
            },
            child: const Text('Create'),
          ),
        ],
      ),
    );

    if (folderName != null) {
      try {
        setState(() => _isLoading = true);
        await _storageService.createFolder(folderName, parentFolderId: _currentFolderId);
        await _loadFiles();
        _showSuccessSnackBar('Folder created successfully');
      } catch (e) {
        _showErrorSnackBar('Failed to create folder: $e');
      } finally {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _deleteFolder(String folderId) async {
    // Find the folder to get information about its contents
    final folder = _folders.firstWhere((f) => f.id == folderId);
    final filesInFolder = _files.where((f) => f.folderId == folderId).length;
    final subFoldersCount = folder.subFolderIds.length;
    
    // Show confirmation dialog
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.warning, color: Colors.orange),
            SizedBox(width: 8),
            Text('Delete Folder?'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Are you sure you want to delete "${folder.name}"?'),
            SizedBox(height: 16),
            if (filesInFolder > 0 || subFoldersCount > 0) ...[
              Text(
                'This action will permanently delete:',
                style: TextStyle(fontWeight: FontWeight.bold, color: Colors.red),
              ),
              SizedBox(height: 8),
              if (filesInFolder > 0)
                Row(
                  children: [
                    Icon(Icons.description, size: 16, color: Colors.red),
                    SizedBox(width: 4),
                    Text('$filesInFolder file${filesInFolder == 1 ? '' : 's'}'),
                  ],
                ),
              if (subFoldersCount > 0)
                Row(
                  children: [
                    Icon(Icons.folder, size: 16, color: Colors.red),
                    SizedBox(width: 4),
                    Text('$subFoldersCount subfolder${subFoldersCount == 1 ? '' : 's'} (and their contents)'),
                  ],
                ),
              SizedBox(height: 12),
              Container(
                padding: EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.red.shade200),
                ),
                child: Row(
                  children: [
                    Icon(Icons.info, color: Colors.red),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'This action cannot be undone!',
                        style: TextStyle(
                          color: Colors.red.shade700,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ] else ...[
              Text('This folder is empty and can be safely deleted.'),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: Text('Delete Forever'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        setState(() => _isLoading = true);
        await _storageService.deleteFolder(folderId);
        await _loadFiles();
        _showSuccessSnackBar('Folder deleted successfully');
      } catch (e) {
        _showErrorSnackBar('Failed to delete folder: $e');
      } finally {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _renameFolder(String folderId, String newName) async {
    try {
      setState(() => _isLoading = true);
      await _storageService.renameFolder(folderId, newName);
      await _loadFiles();
      _showSuccessSnackBar('Folder renamed successfully');
    } catch (e) {
      _showErrorSnackBar('Failed to rename folder: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _enterFolder(String folderId, String folderName) {
    setState(() {
      _navigationStack.add(_currentFolderId ?? '');
      _currentFolderId = folderId;
    });
  }

  void _goBack() {
    if (_navigationStack.isNotEmpty) {
      setState(() {
        _currentFolderId = _navigationStack.removeLast();
        if (_currentFolderId!.isEmpty) {
          _currentFolderId = null;
        }
      });
    }
  }

  List<FileItem> get _currentFiles {
    return _storageService.getFilesInFolder(_files, _currentFolderId);
  }

  List<FolderItem> get _currentFolders {
    return _storageService.getSubFolders(_folders, _currentFolderId);
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

  Future<void> _moveFile(String fileId) async {
    final targetFolderId = await showDialog<String?>(
      context: context,
      builder: (context) => FolderPickerDialog(
        currentFolderId: _currentFolderId,
        title: 'Move File To Folder',
      ),
    );

    // Only proceed if user didn't cancel (targetFolderId will be a special value, not null when cancelled)
    if (targetFolderId != 'CANCELLED') { 
      try {
        setState(() => _isLoading = true);
        await _storageService.moveFileToFolder(fileId, targetFolderId);
        await _loadFiles();
        _showSuccessSnackBar(targetFolderId == null 
          ? 'File moved to root directory' 
          : 'File moved to folder successfully');
      } catch (e) {
        _showErrorSnackBar('Failed to move file: $e');
      } finally {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _copyFile(String fileId) async {
    final targetFolderId = await showDialog<String?>(
      context: context,
      builder: (context) => FolderPickerDialog(
        currentFolderId: _currentFolderId,
        title: 'Copy File To Folder',
      ),
    );

    // Only proceed if user didn't cancel (targetFolderId will be a special value, not null when cancelled)
    if (targetFolderId != 'CANCELLED') { 
      try {
        setState(() => _isLoading = true);
        await _storageService.copyFileToFolder(fileId, targetFolderId);
        await _loadFiles();
        _showSuccessSnackBar(targetFolderId == null 
          ? 'File copied to root directory' 
          : 'File copied to folder successfully');
      } catch (e) {
        _showErrorSnackBar('Failed to copy file: $e');
      } finally {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        backgroundColor: Colors.white,
        leading: _currentFolderId != null 
          ? IconButton(
              onPressed: _goBack,
              icon: const HeroIcon(HeroIcons.arrowLeft),
              tooltip: 'Go Back',
            )
          : null,
        title: Text(
          _currentFolderId != null ? 'Folder Contents' : 'My Files',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            onPressed: _showCreateFolderDialog,
            icon: const HeroIcon(HeroIcons.folderPlus),
            tooltip: 'Create Folder',
          ),
          PopupMenuButton<SortBy>(
            icon: const HeroIcon(HeroIcons.funnel),
            tooltip: 'Sort files',
            onSelected: _changeSortBy,
            itemBuilder: (context) => [
              PopupMenuItem(
                value: SortBy.name,
                child: Row(
                  children: [
                    const HeroIcon(HeroIcons.tag, size: 16),
                    const SizedBox(width: 8),
                    const Text('Name'),
                    if (_sortBy == SortBy.name) ...[
                      const Spacer(),
                      HeroIcon(
                        _sortOrder == SortOrder.ascending 
                            ? HeroIcons.arrowUp 
                            : HeroIcons.arrowDown,
                        size: 12,
                      ),
                    ],
                  ],
                ),
              ),
              PopupMenuItem(
                value: SortBy.size,
                child: Row(
                  children: [
                    const HeroIcon(HeroIcons.scale, size: 16),
                    const SizedBox(width: 8),
                    const Text('Size'),
                    if (_sortBy == SortBy.size) ...[
                      const Spacer(),
                      HeroIcon(
                        _sortOrder == SortOrder.ascending 
                            ? HeroIcons.arrowUp 
                            : HeroIcons.arrowDown,
                        size: 12,
                      ),
                    ],
                  ],
                ),
              ),
              PopupMenuItem(
                value: SortBy.date,
                child: Row(
                  children: [
                    const HeroIcon(HeroIcons.calendar, size: 16),
                    const SizedBox(width: 8),
                    const Text('Date'),
                    if (_sortBy == SortBy.date) ...[
                      const Spacer(),
                      HeroIcon(
                        _sortOrder == SortOrder.ascending 
                            ? HeroIcons.arrowUp 
                            : HeroIcons.arrowDown,
                        size: 12,
                      ),
                    ],
                  ],
                ),
              ),
              PopupMenuItem(
                value: SortBy.type,
                child: Row(
                  children: [
                    const HeroIcon(HeroIcons.documentText, size: 16),
                    const SizedBox(width: 8),
                    const Text('Type'),
                    if (_sortBy == SortBy.type) ...[
                      const Spacer(),
                      HeroIcon(
                        _sortOrder == SortOrder.ascending 
                            ? HeroIcons.arrowUp 
                            : HeroIcons.arrowDown,
                        size: 12,
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadFiles,
              child: CustomScrollView(
                slivers: [
                  // Storage stats card at the top (simple version without pie chart)
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: StorageStatsWidget(
                        files: _files, // Always show total storage stats
                        showDetailedStats: false, // Only show storage bar
                      ),
                    ),
                  ),
                  
                  if (_currentFiles.isEmpty && _currentFolders.isEmpty)
                    const SliverFillRemaining(
                      child: Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            HeroIcon(HeroIcons.folderOpen, size: 64, color: Colors.grey),
                            SizedBox(height: 16),
                            Text(
                              'No files or folders here yet',
                              style: TextStyle(
                                fontSize: 18,
                                color: Colors.grey,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            SizedBox(height: 8),
                            Text(
                              'Create a folder or upload files to get started',
                              style: TextStyle(color: Colors.grey),
                            ),
                          ],
                        ),
                      ),
                    )
                  else
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
                            if (index < _currentFolders.length) {
                              // Show folder
                              final folder = _currentFolders[index];
                              final filesInFolder = _storageService.getFilesInFolder(_files, folder.id);
                              return FolderCard(
                                folder: folder,
                                fileCount: filesInFolder.length,
                                onTap: () => _enterFolder(folder.id, folder.name),
                                onDelete: () => _deleteFolder(folder.id),
                                onRename: (newName) => _renameFolder(folder.id, newName),
                              );
                            } else {
                              // Show file
                              final fileIndex = index - _currentFolders.length;
                              final file = _currentFiles[fileIndex];
                              return FileCard(
                                file: file,
                                onDelete: () => _deleteFile(file.id, file.blockchainHash),
                                onRename: (newName) => _renameFile(file.id, newName),
                                onDownload: () => _downloadFile(file),
                                onMove: () => _moveFile(file.id),
                                onCopy: () => _copyFile(file.id),
                              );
                            }
                          },
                          childCount: _currentFolders.length + _currentFiles.length,
                        ),
                      ),
                    ),
                  
                  const SliverToBoxAdapter(child: SizedBox(height: 32)),
                ],
              ),
            ),
    );
  }
}
