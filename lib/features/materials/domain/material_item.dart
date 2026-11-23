class MaterialItem {
  const MaterialItem({
    required this.id,
    required this.title,
    required this.description,
    required this.subject,
    required this.fileName,
    required this.fileType,
    required this.fileSize,
    required this.fileUrl,
    required this.uploadedBy,
    required this.isBookmarked,
    required this.createdAt,
  });

  final String id;
  final String title;
  final String description;
  final String subject;
  final String fileName;
  final String fileType;
  final int fileSize;
  final String fileUrl;
  final String uploadedBy;
  final bool isBookmarked;
  final DateTime createdAt;
}

class MaterialFailure implements Exception {
  const MaterialFailure(this.message);

  final String message;

  @override
  String toString() => message;
}
