class FileItem {
  final String id;
  final String name;
  final int size;
  final DateTime uploadDate;
  final String mimeType;
  final String blockchainHash;

  FileItem({
    required this.id,
    required this.name,
    required this.size,
    required this.uploadDate,
    required this.mimeType,
    required this.blockchainHash,
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
    };
  }

  factory FileItem.fromJson(Map<String, dynamic> json) {
    String? dateStr = json['uploadDate']?.toString();
    DateTime uploadDate;
    try {
      uploadDate = dateStr != null ? DateTime.parse(dateStr) : DateTime.now();
    } catch (_) {
      uploadDate = DateTime.now();
    }
    return FileItem(
      id: json['id'],
      name: json['name'],
      size: json['size'],
      uploadDate: uploadDate,
      mimeType: json['mimeType'],
      blockchainHash: json['blockchainHash'],
    );
  }
}
