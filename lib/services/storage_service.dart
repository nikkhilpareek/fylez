import 'dart:typed_data';
import 'dart:convert';
import 'dart:math';
import 'package:http/http.dart' as http;
import '../models/file_item.dart';
import '../models/folder_item.dart';
import '../models/shared_file_item.dart';

class StorageService {
  static const String _backendUrl = 'http://localhost:5000/upload'; // Change if backend is remote
  static const String _deleteUrl = 'http://localhost:5000/delete'; // Backend delete endpoint
  static const String _filesListUrl = 'http://localhost:5000/files';
  static const String _fileMetaUrl = 'http://localhost:5000/file-meta';
  static const String _foldersUrl = 'http://localhost:5000/folders';
  static const String _shareFileUrl = 'http://localhost:5000/share-file';
  static const String _revokeAccessUrl = 'http://localhost:5000/revoke-access';
  static const String _sharedWithMeUrl = 'http://localhost:5000/shared-with-me';
  static const String _fileSharesUrl = 'http://localhost:5000/file-shares';
  static int maxStorageBytes = 200 * 1024 * 1024; // 200MB
  static int maxFileSizeBytes = 50 * 1024 * 1024; // 50MB

  // Simulate blockchain storage with mock implementation
  Future<List<FileItem>> getFiles(String userEmail) async {
    final resp = await http.get(Uri.parse('$_filesListUrl?userEmail=$userEmail'));
    if (resp.statusCode == 200) {
      final List<dynamic> list = jsonDecode(resp.body);
      return list.map((json) => FileItem.fromJson(json)).toList()
        ..sort((a, b) => b.uploadDate.compareTo(a.uploadDate));
    }
    throw Exception('Failed to fetch files from cloud');
  }

  Future<void> uploadFile(String userEmail, String fileName, Uint8List fileBytes, int fileSize) async {
    if (fileSize > maxFileSizeBytes) {
      throw Exception('File size exceeds 50MB limit.');
    }
    final files = await getFiles(userEmail);
    final int usedBytes = files.fold(0, (sum, f) => sum + f.size);
    if (usedBytes + fileSize > maxStorageBytes) {
      throw Exception('Storage limit exceeded. Max 200MB allowed.');
    }
    final request = http.MultipartRequest('POST', Uri.parse(_backendUrl));
    request.fields['userEmail'] = userEmail;
    request.files.add(
      http.MultipartFile.fromBytes('file', fileBytes, filename: fileName),
    );
    final response = await request.send();
    if (response.statusCode != 200) {
      throw Exception('Failed to upload file to backend');
    }
    final respStr = await response.stream.bytesToString();
    final respJson = jsonDecode(respStr);
    final cid = respJson['cid'] as String?;
    if (cid == null) {
      throw Exception('No CID returned from backend');
    }
    final fileItem = FileItem(
      id: _generateId(),
      name: fileName,
      size: fileSize,
      uploadDate: DateTime.now(),
      mimeType: _getMimeType(fileName),
      blockchainHash: cid, // Use Pinata CID as blockchainHash
      userEmail: userEmail,
    );
    // Save to backend DB
    final metaResp = await http.post(
      Uri.parse(_fileMetaUrl),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(fileItem.toJson()),
    );
    if (metaResp.statusCode != 200) {
      throw Exception('Failed to save file metadata to cloud');
    }
  }

  Future<void> deleteFile(String userEmail, String fileId, {String? cid}) async {
    final resp = await http.delete(
      Uri.parse('$_deleteUrl/$fileId?userEmail=$userEmail'),
      headers: {'Content-Type': 'application/json'},
    );
    if (resp.statusCode != 200) {
      throw Exception('Failed to delete file');
    }
  }

  Future<void> deleteFileFromPinata(String cid) async {
    // Call backend to delete from Pinata
    final resp = await http.post(
      Uri.parse(_deleteUrl),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'cid': cid}),
    );
    if (resp.statusCode != 200) {
      throw Exception('Failed to delete file from Pinata');
    }
  }

  Future<List<FolderItem>> getFolders(String userEmail) async {
    final resp = await http.get(
      Uri.parse('$_foldersUrl?userEmail=$userEmail'),
      headers: {
        'Content-Type': 'application/json',
        'Access-Control-Allow-Origin': '*',
      },
    );
    if (resp.statusCode == 200) {
      final List<dynamic> list = jsonDecode(resp.body);
      final folders = list.map((json) => FolderItem.fromJson(json)).toList()
        ..sort((a, b) => b.createdDate.compareTo(a.createdDate));
      return folders;
    }
    return [];
  }

  Future<void> createFolder(String userEmail, String folderName, {String? parentFolderId}) async {
    final folder = FolderItem(
      id: _generateId(),
      name: folderName,
      createdDate: DateTime.now(),
      parentFolderId: parentFolderId,
      fileIds: const [],
      subFolderIds: const [],
      userEmail: userEmail,
    );
    final resp = await http.post(
      Uri.parse(_foldersUrl),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(folder.toJson()),
    );
    if (resp.statusCode != 200) {
      throw Exception('Failed to create folder');
    }
  }

  Future<void> deleteFolder(String userEmail, String folderId) async {
    final resp = await http.delete(
      Uri.parse('$_foldersUrl/$folderId?userEmail=$userEmail'),
      headers: {'Content-Type': 'application/json'},
    );
    if (resp.statusCode != 200) {
      throw Exception('Failed to delete folder');
    }
  }

  Future<void> renameFile(String userEmail, String fileId, String newName) async {
    // Simulate blockchain rename process
    await Future.delayed(const Duration(milliseconds: 600));
    final files = await getFiles(userEmail);
    for (var file in files) {
      if (file.id == fileId) {
        final updatedFile = FileItem(
          id: file.id,
          name: newName,
          size: file.size,
          uploadDate: file.uploadDate,
          mimeType: file.mimeType,
          blockchainHash: file.blockchainHash,
          userEmail: userEmail,
        );
        // Update file metadata on backend
        final metaResp = await http.post(
          Uri.parse(_fileMetaUrl),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode(updatedFile.toJson()),
        );
        if (metaResp.statusCode != 200) {
          throw Exception('Failed to update file metadata on cloud');
        }
        break;
      }
    }
  }

  Future<void> renameFolder(String userEmail, String folderId, String newName) async {
    final folders = await getFolders(userEmail);
    final folder = folders.firstWhere((f) => f.id == folderId);
    final updatedFolder = folder.copyWith(name: newName);
    final resp = await http.put(
      Uri.parse('$_foldersUrl/$folderId'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(updatedFolder.toJson()),
    );
    if (resp.statusCode != 200) {
      throw Exception('Failed to rename folder');
    }
  }

  Future<void> moveFileToFolder(String userEmail, String fileId, String? folderId) async {
    final files = await getFiles(userEmail);
    final file = files.firstWhere((f) => f.id == fileId);
    final updatedFile = FileItem(
      id: file.id,
      name: file.name,
      size: file.size,
      uploadDate: file.uploadDate,
      mimeType: file.mimeType,
      blockchainHash: file.blockchainHash,
      folderId: folderId,
      userEmail: userEmail,
    );
    final resp = await http.put(
      Uri.parse('$_fileMetaUrl/$fileId'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(updatedFile.toJson()),
    );
    if (resp.statusCode != 200) {
      throw Exception('Failed to move file');
    }
  }

  Future<void> copyFileToFolder(String userEmail, String fileId, String? folderId) async {
    final files = await getFiles(userEmail);
    final file = files.firstWhere((f) => f.id == fileId);
    final copiedFile = FileItem(
      id: _generateId(),
      name: 'Copy of ${file.name}',
      size: file.size,
      uploadDate: DateTime.now(),
      mimeType: file.mimeType,
      blockchainHash: file.blockchainHash,
      folderId: folderId,
      userEmail: userEmail,
    );
    final resp = await http.post(
      Uri.parse(_fileMetaUrl),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(copiedFile.toJson()),
    );
    if (resp.statusCode != 200) {
      throw Exception('Failed to copy file');
    }
  }

  // File sharing methods
  Future<void> shareFile(String ownerEmail, String fileId, String sharedWithEmail) async {
    final resp = await http.post(
      Uri.parse(_shareFileUrl),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'fileId': fileId,
        'ownerEmail': ownerEmail,
        'sharedWithEmail': sharedWithEmail,
      }),
    );
    if (resp.statusCode != 200) {
      try {
        final error = jsonDecode(resp.body)['error'] ?? 'Failed to share file';
        throw Exception(error);
      } catch (e) {
        // If JSON parsing fails, it might be an HTML error page
        throw Exception('Failed to share file: ${resp.statusCode}');
      }
    }
  }

  Future<void> revokeFileAccess(String ownerEmail, String fileId, String sharedWithEmail) async {
    final resp = await http.delete(
      Uri.parse('$_revokeAccessUrl/$fileId/$sharedWithEmail?ownerEmail=$ownerEmail'),
      headers: {'Content-Type': 'application/json'},
    );
    if (resp.statusCode != 200) {
      try {
        final error = jsonDecode(resp.body)['error'] ?? 'Failed to revoke access';
        throw Exception(error);
      } catch (e) {
        // If JSON parsing fails, it might be an HTML error page
        throw Exception('Failed to revoke access: ${resp.statusCode}');
      }
    }
  }

  Future<List<FileItem>> getSharedWithMe(String userEmail) async {
    final resp = await http.get(
      Uri.parse('$_sharedWithMeUrl?userEmail=$userEmail'),
      headers: {'Content-Type': 'application/json'},
    );
    if (resp.statusCode == 200) {
      final List<dynamic> list = jsonDecode(resp.body);
      return list.map((json) => FileItem.fromJson(json)).toList()
        ..sort((a, b) => b.uploadDate.compareTo(a.uploadDate));
    }
    return [];
  }

  Future<List<SharedFileItem>> getFileShares(String ownerEmail, String fileId) async {
    final resp = await http.get(
      Uri.parse('$_fileSharesUrl/$fileId?ownerEmail=$ownerEmail'),
      headers: {'Content-Type': 'application/json'},
    );
    if (resp.statusCode == 200) {
      final List<dynamic> list = jsonDecode(resp.body);
      return list.map((json) => SharedFileItem.fromJson(json)).toList();
    }
    return [];
  }

  List<FileItem> getFilesInFolder(List<FileItem> allFiles, String? folderId) {
    return allFiles.where((file) => file.folderId == folderId).toList();
  }

  List<FolderItem> getSubFolders(List<FolderItem> allFolders, String? parentFolderId) {
    return allFolders.where((folder) => folder.parentFolderId == parentFolderId).toList();
  }

  String _generateId() {
    return DateTime.now().millisecondsSinceEpoch.toString() + 
           Random().nextInt(1000).toString();
  }

  String _getMimeType(String fileName) {
    final extension = fileName.split('.').last.toLowerCase();
    switch (extension) {
      case 'jpg':
      case 'jpeg':
        return 'image/jpeg';
      case 'png':
        return 'image/png';
      case 'gif':
        return 'image/gif';
      case 'pdf':
        return 'application/pdf';
      case 'doc':
        return 'application/msword';
      case 'docx':
        return 'application/vnd.openxmlformats-officedocument.wordprocessingml.document';
      case 'txt':
        return 'text/plain';
      case 'mp4':
        return 'video/mp4';
      case 'mp3':
        return 'audio/mpeg';
      default:
        return 'application/octet-stream';
    }
  }
}
