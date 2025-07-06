import 'package:flutter/material.dart';
import '../models/file_item.dart';

// File type color constants for use across widgets
const kImageFileColor = Color(0xFFFFA726); // orange
const kDocumentFileColor = Color(0xFF42A5F5); // blue
const kVideoFileColor = Color(0xFFEF5350); // red
const kAudioFileColor = Color(0xFFAB47BC); // purple
const kDefaultFileColor = null;

class FileCard extends StatelessWidget {
  final FileItem file;
  final VoidCallback onDelete;
  final ValueChanged<String> onRename;
  final VoidCallback onDownload;
  final VoidCallback? onMove; // Move file callback
  final VoidCallback? onCopy; // Copy file callback
  final VoidCallback? onShare; // Share file callback
  final bool isSharedFile; // Whether this file is shared with the current user

  const FileCard({
    super.key,
    required this.file,
    required this.onDelete,
    required this.onRename,
    required this.onDownload,
    this.onMove,
    this.onCopy,
    this.onShare,
    this.isSharedFile = false,
  });

  @override
  Widget build(BuildContext context) {
    IconData fileIcon;
    Color? iconColor;
    if (file.isImage) {
      fileIcon = Icons.image;
      iconColor = kImageFileColor;
    } else if (file.isDocument) {
      fileIcon = Icons.description;
      iconColor = kDocumentFileColor;
    } else if (file.isVideo) {
      fileIcon = Icons.videocam;
      iconColor = kVideoFileColor;
    } else if (file.isAudio) {
      fileIcon = Icons.audiotrack;
      iconColor = kAudioFileColor;
    } else {
      fileIcon = Icons.insert_drive_file;
      iconColor = Theme.of(context).colorScheme.primary;
    }
    
    return GestureDetector(
      onTap: () => _showFilePreview(context),
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
                    Stack(
                      children: [
                        Icon(fileIcon, size: 32, color: iconColor),
                        if (isSharedFile)
                          Positioned(
                            right: -2,
                            top: -2,
                            child: Container(
                              padding: const EdgeInsets.all(2),
                              decoration: const BoxDecoration(
                                color: Colors.blue,
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.share,
                                size: 12,
                                color: Colors.white,
                              ),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            file.name,
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                            overflow: TextOverflow.ellipsis,
                            maxLines: 2,
                          ),
                          if (isSharedFile && file.userEmail != null)
                            Text(
                              'Shared by ${file.userEmail}',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.blue.shade600,
                                fontWeight: FontWeight.w500,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                        ],
                      ),
                    ),
                    PopupMenuButton<String>(
                      icon: const Icon(Icons.more_vert),
                      onSelected: (value) async {
                        if (value == 'rename') {
                          final newName = await _showRenameDialog(context, file.name);
                          if (newName != null && newName.trim().isNotEmpty && newName != file.name) {
                            onRename(newName.trim());
                          }
                        } else if (value == 'delete') {
                          onDelete();
                        } else if (value == 'download') {
                          onDownload();
                        } else if (value == 'move' && onMove != null) {
                          onMove!();
                        } else if (value == 'copy' && onCopy != null) {
                          onCopy!();
                        } else if (value == 'share' && onShare != null) {
                          onShare!();
                        }
                      },
                      itemBuilder: (context) => [
                        const PopupMenuItem(value: 'download', child: Row(
                          children: [
                            Icon(Icons.download, size: 16),
                            SizedBox(width: 8),
                            Text('Download'),
                          ],
                        )),
                        if (onMove != null)
                          const PopupMenuItem(value: 'move', child: Row(
                            children: [
                              Icon(Icons.drive_file_move, size: 16),
                              SizedBox(width: 8),
                              Text('Move to Folder'),
                            ],
                          )),
                        if (onCopy != null)
                          const PopupMenuItem(value: 'copy', child: Row(
                            children: [
                              Icon(Icons.copy, size: 16),
                              SizedBox(width: 8),
                              Text('Copy to Folder'),
                            ],
                          )),
                        if (onShare != null)
                          const PopupMenuItem(value: 'share', child: Row(
                            children: [
                              Icon(Icons.share, size: 16),
                              SizedBox(width: 8),
                              Text('Share'),
                            ],
                          )),
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
                    Icon(Icons.storage, size: 16, color: Colors.grey.shade600),
                    const SizedBox(width: 4),
                    Flexible(
                      child: Text(
                        file.formattedSize,
                        style: TextStyle(color: Colors.grey.shade700),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.verified_user, size: 16, color: Colors.green.shade700),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        file.blockchainHash,
                        style: TextStyle(fontSize: 12, color: Colors.green.shade700),
                        overflow: TextOverflow.ellipsis,
                        maxLines: 1,
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
    final String originalExtension = currentName.contains('.') ? '.${currentName.split('.').last}' : '';
    return showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Rename File'),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: InputDecoration(
            labelText: 'New file name',
            helperText: originalExtension.isNotEmpty
                ? 'File type will remain $originalExtension'
                : null,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              String newName = controller.text.trim();
              if (originalExtension.isNotEmpty && !newName.endsWith(originalExtension)) {
                newName += originalExtension;
              }
              Navigator.of(context).pop(newName);
            },
            child: const Text('Rename'),
          ),
        ],
      ),
    );
  }

  void _showFilePreview(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) {
        if (file.isImage) {
          final String cid = file.blockchainHash;
          final String imageUrl = 'https://gateway.pinata.cloud/ipfs/$cid';
          return Dialog(
            child: InteractiveViewer(
              child: Image.network(
                imageUrl,
                fit: BoxFit.contain,
                errorBuilder: (context, error, stackTrace) => const Padding(
                  padding: EdgeInsets.all(24),
                  child: Text('Could not load image.'),
                ),
              ),
            ),
          );
        } else if (file.isDocument) {
          return const Dialog(
            child: Padding(
              padding: EdgeInsets.all(24),
              child: Text('Document preview not supported. Download to view.'),
            ),
          );
        } else if (file.isVideo) {
          return const Dialog(
            child: Padding(
              padding: EdgeInsets.all(24),
              child: Text('Video preview not supported. Download to view.'),
            ),
          );
        } else if (file.isAudio) {
          return const Dialog(
            child: Padding(
              padding: EdgeInsets.all(24),
              child: Text('Audio preview not supported. Download to listen.'),
            ),
          );
        } else if (file.size > 10 * 1024 * 1024) {
          return const Dialog(
            child: Padding(
              padding: EdgeInsets.all(24),
              child: Text('File too large to preview.'),
            ),
          );
        } else {
          return const Dialog(
            child: Padding(
              padding: EdgeInsets.all(24),
              child: Text('Preview not available for this file type.'),
            ),
          );
        }
      },
    );
  }
}
