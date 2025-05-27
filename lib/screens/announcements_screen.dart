import 'package:flutter/material.dart';
import '../services/announcement_service.dart';

class AnnouncementsScreen extends StatefulWidget {
  const AnnouncementsScreen({super.key});

  @override
  State<AnnouncementsScreen> createState() => _AnnouncementsScreenState();
}

class _AnnouncementsScreenState extends State<AnnouncementsScreen> {
  List<dynamic> _announcements = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _fetchAnnouncements();
  }

  Future<void> _fetchAnnouncements() async {
    final announcements = await AnnouncementService.getAnnouncements();
    setState(() {
      _announcements = announcements;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Pengumuman'),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView.builder(
        itemCount: _announcements.length,
        itemBuilder: (context, index) {
          final item = _announcements[index];
          return ListTile(
            title: Text(item['title']),
            subtitle: Text(item['message']),
            trailing: Text(
              item['createdAt']?.split('T').first ?? '',
              style: const TextStyle(fontSize: 12, color: Colors.grey),
            ),
          );
        },
      ),
    );
  }
}