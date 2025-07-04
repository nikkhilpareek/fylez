import 'dart:typed_data';
import 'dart:convert';
import 'dart:math';
import 'package:http/http.dart' as http;
import '../models/file_item.dart';

class StorageService {
  static const String _backendUrl = 'http://localhost:5000/upload'; // Change if backend is remote
  static const String _deleteUrl = 'http://localhost:5000/delete'; // Backend delete endpoint
  static const String _filesListUrl = 'http://localhost:5000/files';
  static const String _fileMetaUrl = 'http://localhost:5000/file-meta';
  static const String _deleteMetaUrl = 'http://localhost:5000/delete-meta';
  static const int maxStorageBytes = 200 * 1024 * 1024; // 200MB
  static const int maxFileSizeBytes = 50 * 1024 * 1024; // 50MB

  // Simulate blockchain storage with mock implementation
  Future<List<FileItem>> getFiles() async {
    final resp = await http.get(Uri.parse(_filesListUrl));
    if (resp.statusCode == 200) {
      final List<dynamic> list = jsonDecode(resp.body);
      return list.map((json) => FileItem.fromJson(json)).toList()
        ..sort((a, b) => b.uploadDate.compareTo(a.uploadDate));
    }
    throw Exception('Failed to fetch files from cloud');
  }

  Future<void> uploadFile(String fileName, Uint8List fileBytes, int fileSize) async {
    if (fileSize > maxFileSizeBytes) {
      throw Exception('File size exceeds 50MB limit.');
    }
    final files = await getFiles();
    final int usedBytes = files.fold(0, (sum, f) => sum + f.size);
    if (usedBytes + fileSize > maxStorageBytes) {
      throw Exception('Storage limit exceeded. Max 200MB allowed.');
    }
    final request = http.MultipartRequest('POST', Uri.parse(_backendUrl));
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

  Future<void> deleteFile(String fileId, {String? cid}) async {
    if (cid != null && cid.isNotEmpty) {
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
    // Remove from backend DB
    final metaResp = await http.post(
      Uri.parse(_deleteMetaUrl),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'id': fileId}),
    );
    if (metaResp.statusCode != 200) {
      throw Exception('Failed to remove file metadata from cloud');
    }
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

  Future<void> renameFile(String fileId, String newName) async {
    // Simulate blockchain rename process
    await Future.delayed(const Duration(milliseconds: 600));
    
    final files = await getFiles();
    for (var file in files) {
      if (file.id == fileId) {
        final updatedFile = FileItem(
          id: file.id,
          name: newName,
          size: file.size,
          uploadDate: file.uploadDate,
          mimeType: file.mimeType,
          blockchainHash: file.blockchainHash,
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
}
