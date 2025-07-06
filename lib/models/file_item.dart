class FileItem {
  final String id;
  final String name;
  final int size;
  final DateTime uploadDate;
  final String mimeType;
  final String blockchainHash;
  final String? folderId; // null means file is in root directory
  final String? userEmail;

  FileItem({
    required this.id,
    required this.name,
    required this.size,
    required this.uploadDate,
    required this.mimeType,
    required this.blockchainHash,
    this.folderId,
    this.userEmail,
  });

  String get formattedSize {
    if (size < 1024) return '$size B';
    if (size < 1024 * 1024) return '${(size / 1024).toStringAsFixed(1)} KB';
    if (size < 1024 * 1024 * 1024) return '${(size / (1024 * 1024)).toStringAsFixed(1)} MB';
    return '${(size / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
  }

  String get fileExtension {
    final parts = name.split('.');
    return parts.length > 1 ? parts.last.toLowerCase() : '';
  }

  bool get isImage => ['jpg', 'jpeg', 'png', 'gif', 'bmp', 'webp'].contains(fileExtension);
  bool get isDocument => ['pdf', 'doc', 'docx', 'txt', 'rtf'].contains(fileExtension);
  bool get isVideo => ['mp4', 'avi', 'mov', 'wmv', 'flv', 'webm'].contains(fileExtension);
  bool get isAudio => ['mp3', 'wav', 'flac', 'aac', 'ogg'].contains(fileExtension);

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'size': size,
      'uploadDate': uploadDate.toIso8601String(),
      'mimeType': mimeType,
      'blockchainHash': blockchainHash,
      'folderId': folderId,
      'userEmail': userEmail,
    };
  }

  factory FileItem.fromJson(Map<String, dynamic> json) {
    String? dateStr = json['uploadDate']?.toString();
    DateTime uploadDate;
    if (dateStr != null && dateStr.isNotEmpty) {
      try {
        uploadDate = DateTime.parse(dateStr);
      } catch (e) {
        uploadDate = DateTime.now();
      }
    } else {
      uploadDate = DateTime.now();
    }

    return FileItem(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      size: (json['size'] as num?)?.toInt() ?? 0,
      uploadDate: uploadDate,
      mimeType: json['mimeType']?.toString() ?? '',
      blockchainHash: json['blockchainHash']?.toString() ?? '',
      folderId: json['folderId']?.toString(),
      userEmail: json['userEmail']?.toString(),
    );
  }
}
