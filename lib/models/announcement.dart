class Announcement {
  final String announcementId;
  final String title;
  final String content;
  final String userId;
  final DateTime createdAt;

  Announcement({
    required this.announcementId,
    required this.title,
    required this.content,
    required this.userId,
    required this.createdAt,
  });

  factory Announcement.fromJson(Map<String, dynamic> json) {
    return Announcement(
      announcementId: json['announcement_id'] ?? '',
      title: json['title'] ?? 'No Title',
      content: json['content'] ?? 'No Content',
      userId: json['user_id'] ?? '',
      createdAt: DateTime.parse(json['created_at']),
    );
  }
}