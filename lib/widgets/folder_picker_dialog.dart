import 'package:flutter/material.dart';
import 'package:heroicons/heroicons.dart';
import '../models/folder_item.dart';
import '../services/storage_service.dart';
import '../services/user_service.dart';

class FolderPickerDialog extends StatefulWidget {
  final String? currentFolderId;
  final String title;

  const FolderPickerDialog({
    super.key,
    this.currentFolderId,
    this.title = 'Select Folder',
  });

  @override
  State<FolderPickerDialog> createState() => _FolderPickerDialogState();
}

class _FolderPickerDialogState extends State<FolderPickerDialog> {
  final StorageService _storageService = StorageService();
  List<FolderItem> _folders = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadFolders();
  }

  Future<void> _loadFolders() async {
    try {
      print('FolderPickerDialog: Loading folders...');
      final folders = await _storageService.getFolders(UserService.userEmail);
      print('FolderPickerDialog: Loaded \\${folders.length} folders');
      for (final folder in folders) {
        print('FolderPickerDialog: Folder: \\${folder.name} (ID: \\${folder.id})');
      }
      setState(() {
        _folders = folders;
        _isLoading = false;
        _error = null;
      });
    } catch (e) {
      print('FolderPickerDialog: Error loading folders: $e');
      setState(() {
        _isLoading = false;
        _error = e.toString();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    // Filter out the current folder and its subfolders to avoid circular references
    // For now, let's simplify and show all folders to debug the issue
    final availableFolders = _folders.toList();

    print('FolderPickerDialog: Build called. Total folders: ${_folders.length}, Available folders: ${availableFolders.length}');
    print('FolderPickerDialog: Current folder ID: ${widget.currentFolderId}');
    print('FolderPickerDialog: Is loading: $_isLoading');
    print('FolderPickerDialog: Folder names: ${_folders.map((f) => f.name).join(', ')}');

    return AlertDialog(
      title: Text(widget.title),
      content: SizedBox(
        width: double.maxFinite,
        height: 300,
        child: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
            ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.error, color: Colors.red, size: 48),
                    const SizedBox(height: 16),
                    Text('Error loading folders:', style: TextStyle(color: Colors.red)),
                    const SizedBox(height: 8),
                    Text(_error!, style: TextStyle(color: Colors.grey, fontSize: 12)),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: () {
                        setState(() {
                          _isLoading = true;
                          _error = null;
                        });
                        _loadFolders();
                      },
                      child: const Text('Retry'),
                    ),
                  ],
                ),
              )
          : Column(
            children: [
              // Option to move to root directory
              ListTile(
                leading: const HeroIcon(
                  HeroIcons.home,
                  size: 24,
                  color: Colors.blue,
                ),
                title: const Text('Root Directory'),
                subtitle: const Text('Move to the main folder'),
                onTap: () => Navigator.of(context).pop(null),
              ),
              const Divider(),
              
              // List of available folders
              if (availableFolders.isEmpty)
                const Expanded(
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        HeroIcon(HeroIcons.folderOpen, size: 48, color: Colors.grey),
                        SizedBox(height: 16),
                        Text(
                          'No folders available',
                          style: TextStyle(color: Colors.grey),
                        ),
                      ],
                    ),
                  ),
                )
              else
                Expanded(
                  child: ListView.builder(
                    itemCount: availableFolders.length,
                    itemBuilder: (context, index) {
                      final folder = availableFolders[index];
                      return ListTile(
                        leading: const HeroIcon(
                          HeroIcons.folder,
                          size: 24,
                          color: Colors.amber,
                          style: HeroIconStyle.solid,
                        ),
                        title: Text(folder.name),
                        subtitle: Text(_formatDate(folder.createdDate)),
                        onTap: () => Navigator.of(context).pop(folder.id),
                      );
                    },
                  ),
                ),
            ],
          ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop('CANCELLED'),
          child: const Text('Cancel'),
        ),
      ],
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);
    
    if (difference.inDays == 0) {
      return 'Created today';
    } else if (difference.inDays == 1) {
      return 'Created yesterday';
    } else if (difference.inDays < 7) {
      return 'Created ${difference.inDays} days ago';
    } else {
      return 'Created ${date.day}/${date.month}/${date.year}';
    }
  }
}
