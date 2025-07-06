class SharedFileItem {
  final String id;
  final String fileId;
  final String ownerEmail;
  final String sharedWithEmail;
  final DateTime sharedAt;

  SharedFileItem({
    required this.id,
    required this.fileId,
    required this.ownerEmail,
    required this.sharedWithEmail,
    required this.sharedAt,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'fileId': fileId,
      'ownerEmail': ownerEmail,
      'sharedWithEmail': sharedWithEmail,
      'sharedAt': sharedAt.toIso8601String(),
    };
  }

  factory SharedFileItem.fromJson(Map<String, dynamic> json) {
    return SharedFileItem(
      id: json['id']?.toString() ?? '',
      fileId: json['fileId']?.toString() ?? '',
      ownerEmail: json['ownerEmail']?.toString() ?? '',
      sharedWithEmail: json['sharedWithEmail']?.toString() ?? '',
      sharedAt: DateTime.parse(json['sharedAt'] ?? DateTime.now().toIso8601String()),
    );
  }
}
