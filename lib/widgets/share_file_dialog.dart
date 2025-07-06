import 'package:flutter/material.dart';
import 'package:heroicons/heroicons.dart';
import '../models/file_item.dart';
import '../models/shared_file_item.dart';
import '../services/storage_service.dart';
import '../services/user_service.dart';

class ShareFileDialog extends StatefulWidget {
  final FileItem file;

  const ShareFileDialog({
    super.key,
    required this.file,
  });

  @override
  State<ShareFileDialog> createState() => _ShareFileDialogState();
}

class _ShareFileDialogState extends State<ShareFileDialog> {
  final StorageService _storageService = StorageService();
  final _emailController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;
  List<SharedFileItem> _currentShares = [];

  @override
  void initState() {
    super.initState();
    _loadCurrentShares();
  }

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _loadCurrentShares() async {
    try {
      final shares = await _storageService.getFileShares(UserService.userEmail, widget.file.id);
      setState(() => _currentShares = shares);
    } catch (e) {
      // Handle error silently or show a snackbar
    }
  }

  Future<void> _shareFile() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);
    try {
      await _storageService.shareFile(
        UserService.userEmail,
        widget.file.id,
        _emailController.text.trim(),
      );
      
      _emailController.clear();
      await _loadCurrentShares();
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('File shared successfully!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString().replaceFirst('Exception: ', '')),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _revokeAccess(SharedFileItem share) async {
    try {
      await _storageService.revokeFileAccess(
        UserService.userEmail,
        widget.file.id,
        share.sharedWithEmail,
      );
      
      await _loadCurrentShares();
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Access revoked successfully!'),
            backgroundColor: Colors.orange,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to revoke access: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: Container(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.8,
          maxWidth: 400, // Fixed max width instead of percentage
        ),
        padding: const EdgeInsets.all(20),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
            Row(
              children: [
                const HeroIcon(HeroIcons.share, size: 24),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Share "${widget.file.name}"',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                    overflow: TextOverflow.ellipsis,
                    maxLines: 2,
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const HeroIcon(HeroIcons.xMark),
                ),
              ],
            ),
            
            const SizedBox(height: 24),
            
            // Share with new user
            Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Share with someone new:',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Column(
                    children: [
                      TextFormField(
                        controller: _emailController,
                        keyboardType: TextInputType.emailAddress,
                        decoration: const InputDecoration(
                          labelText: 'Email address',
                          hintText: 'Enter email to share with',
                          prefixIcon: HeroIcon(HeroIcons.envelope),
                          border: OutlineInputBorder(),
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Please enter an email address';
                          }
                          if (!RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(value.trim())) {
                            return 'Please enter a valid email address';
                          }
                          if (value.trim() == UserService.userEmail) {
                            return 'You cannot share with yourself';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 12),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: _isLoading ? null : _shareFile,
                          child: _isLoading 
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(strokeWidth: 2),
                              )
                            : const Text('Share'),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 32),
            
            // Current shares
            const Text(
              'Currently shared with:',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 12),
            
            if (_currentShares.isEmpty)
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Row(
                  children: [
                    HeroIcon(HeroIcons.informationCircle, color: Colors.grey),
                    SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'This file is not shared with anyone yet.',
                        style: TextStyle(color: Colors.grey),
                      ),
                    ),
                  ],
                ),
              )
            else
              Container(
                constraints: const BoxConstraints(maxHeight: 200),
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: _currentShares.length,
                  itemBuilder: (context, index) {
                    final share = _currentShares[index];
                    return Card(
                      margin: const EdgeInsets.only(bottom: 8),
                      child: ListTile(
                        leading: const CircleAvatar(
                          child: HeroIcon(HeroIcons.user, size: 20),
                        ),
                        title: Text(share.sharedWithEmail),
                        subtitle: Text(
                          'Shared on ${share.sharedAt.toLocal().toString().split(' ')[0]}',
                          style: TextStyle(color: Colors.grey.shade600),
                        ),
                        trailing: IconButton(
                          onPressed: () => _revokeAccess(share),
                          icon: const HeroIcon(
                            HeroIcons.trash,
                            color: Colors.red,
                            size: 20,
                          ),
                          tooltip: 'Revoke access',
                        ),
                      ),
                    );
                  },
                ),
              ),
            
            const SizedBox(height: 24),
            
            // Close button
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Close'),
                ),
              ],
            ),            ],
          ),
        ),
      ),
    );
  }
}
