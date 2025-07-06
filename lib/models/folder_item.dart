class FolderItem {
  final String id;
  final String name;
  final DateTime createdDate;
  final String? parentFolderId; // null for root level folders
  final List<String> fileIds; // IDs of files in this folder
  final List<String> subFolderIds; // IDs of subfolders
  final String? userEmail;

  FolderItem({
    required this.id,
    required this.name,
    required this.createdDate,
    this.parentFolderId,
    this.fileIds = const [],
    this.subFolderIds = const [],
    this.userEmail,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'createdDate': createdDate.toIso8601String(),
      'parentFolderId': parentFolderId,
      'fileIds': fileIds,
      'subFolderIds': subFolderIds,
      'userEmail': userEmail,
    };
  }

  factory FolderItem.fromJson(Map<String, dynamic> json) {
    return FolderItem(
      id: json['id'],
      name: json['name'],
      createdDate: DateTime.parse(json['createdDate']),
      parentFolderId: json['parentFolderId'],
      fileIds: List<String>.from(json['fileIds'] ?? []),
      subFolderIds: List<String>.from(json['subFolderIds'] ?? []),
      userEmail: json['userEmail'],
    );
  }

  FolderItem copyWith({
    String? id,
    String? name,
    DateTime? createdDate,
    String? parentFolderId,
    List<String>? fileIds,
    List<String>? subFolderIds,
    String? userEmail,
  }) {
    return FolderItem(
      id: id ?? this.id,
      name: name ?? this.name,
      createdDate: createdDate ?? this.createdDate,
      parentFolderId: parentFolderId ?? this.parentFolderId,
      fileIds: fileIds ?? this.fileIds,
      subFolderIds: subFolderIds ?? this.subFolderIds,
      userEmail: userEmail ?? this.userEmail,
    );
  }
}
