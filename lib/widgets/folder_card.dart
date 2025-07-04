import 'package:flutter/material.dart';
import 'package:heroicons/heroicons.dart';
import '../models/folder_item.dart';

class FolderCard extends StatelessWidget {
  final FolderItem folder;
  final VoidCallback onTap;
  final VoidCallback onDelete;
  final ValueChanged<String> onRename;
  final int fileCount;

  const FolderCard({
    super.key,
    required this.folder,
    required this.onTap,
    required this.onDelete,
    required this.onRename,
    required this.fileCount,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: SizedBox(
        width: 150,
        height: 150,
        child: Card(
          elevation: 2,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.start,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const HeroIcon(
                      HeroIcons.folder,
                      size: 32,
                      color: Colors.amber,
                      style: HeroIconStyle.solid,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        folder.name,
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                        overflow: TextOverflow.ellipsis,
                        maxLines: 2,
                      ),
                    ),
                    PopupMenuButton<String>(
                      icon: const Icon(Icons.more_vert),
                      onSelected: (value) async {
                        if (value == 'rename') {
                          final newName = await _showRenameDialog(context, folder.name);
                          if (newName != null && newName.trim().isNotEmpty && newName != folder.name) {
                            onRename(newName.trim());
                          }
                        } else if (value == 'delete') {
                          onDelete();
                        }
                      },
                      itemBuilder: (context) => [
                        const PopupMenuItem(value: 'rename', child: Row(
                          children: [
                            Icon(Icons.edit, size: 16),
                            SizedBox(width: 8),
                            Text('Rename'),
                          ],
                        )),
                        const PopupMenuItem(value: 'delete', child: Row(
                          children: [
                            Icon(Icons.delete, size: 16, color: Colors.red),
                            SizedBox(width: 8),
                            Text('Delete', style: TextStyle(color: Colors.red)),
                          ],
                        )),
                      ],
                    ),
                  ],
                ),
                const Spacer(),
                Row(
                  children: [
                    Icon(Icons.description, size: 16, color: Colors.grey.shade600),
                    const SizedBox(width: 4),
                    Text(
                      '$fileCount file${fileCount == 1 ? '' : 's'}',
                      style: TextStyle(color: Colors.grey.shade700),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Icon(Icons.folder_outlined, size: 16, color: Colors.grey.shade600),
                    const SizedBox(width: 4),
                    Text(
                      '${folder.subFolderIds.length} subfolder${folder.subFolderIds.length == 1 ? '' : 's'}',
                      style: TextStyle(color: Colors.grey.shade700),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Icon(Icons.access_time, size: 16, color: Colors.grey.shade600),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        _formatDate(folder.createdDate),
                        style: TextStyle(fontSize: 12, color: Colors.grey.shade700),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<String?> _showRenameDialog(BuildContext context, String currentName) async {
    final controller = TextEditingController(text: currentName);
    return showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Rename Folder'),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(
            labelText: 'New folder name',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              final newName = controller.text.trim();
              Navigator.of(context).pop(newName.isNotEmpty ? newName : null);
            },
            child: const Text('Rename'),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);
    
    if (difference.inDays == 0) {
      return 'Today';
    } else if (difference.inDays == 1) {
      return 'Yesterday';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} days ago';
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
  }
}
