import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../providers/theme_notifier.dart';
import '../services/announcement_fetch_service.dart';
import '../services/announcement_manage_service.dart';
import '../models/announcement.dart';

class AnnouncementsScreen extends StatefulWidget {
  const AnnouncementsScreen({super.key});

  @override
  State<AnnouncementsScreen> createState() => _AnnouncementsScreenState();
}

class _AnnouncementsScreenState extends State<AnnouncementsScreen> {
  late Future<List<Announcement>> _announcementsFuture;
  final _fetchService = AnnouncementFetchService();
  final _manageService = AnnouncementManageService();

  @override
  void initState() {
    super.initState();
    _loadAnnouncements();
  }

  void _loadAnnouncements() {
    final newFuture = _fetchService.fetchAnnouncements();
    setState(() {
      _announcementsFuture = newFuture;
    });
  }

  void _deleteAnnouncement(String announcementId) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Konfirmasi Hapus'),
        content: const Text('Apakah Anda yakin ingin menghapus pengumuman ini?'),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(false), child: const Text('Batal')),
          TextButton(onPressed: () => Navigator.of(context).pop(true), child: const Text('Hapus')),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      final success = await _manageService.deleteAnnouncement(announcementId: announcementId);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(success ? 'Berhasil dihapus!' : 'Gagal menghapus.'),
            backgroundColor: success ? Colors.green : Colors.red,
          ),
        );
        if (success) _loadAnnouncements();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: ${e.toString()}'), backgroundColor: Colors.red),
        );
      }
    }
  }

  void _editAnnouncement(Announcement announcement) async {
    final result = await Navigator.of(context).pushNamed(
      '/edit-announcement',
      arguments: announcement,
    );
    if (result == true) _loadAnnouncements();
  }

  @override
  Widget build(BuildContext context) {
    final themeNotifier = Provider.of<ThemeNotifier>(context);
    bool isEffectivelyDark = themeNotifier.themeMode == ThemeMode.dark ||
        (themeNotifier.themeMode == ThemeMode.system && MediaQuery.platformBrightnessOf(context) == Brightness.dark);

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(icon: const Icon(Icons.arrow_back), onPressed: () => Navigator.of(context).pop()),
        title: const Text('Pengumuman'),
        actions: [
          IconButton(
            icon: Icon(isEffectivelyDark ? Icons.light_mode_outlined : Icons.dark_mode_outlined),
            tooltip: isEffectivelyDark ? 'Mode Terang' : 'Mode Gelap',
            onPressed: () => themeNotifier.toggleTheme(isEffectivelyDark ? Brightness.dark : Brightness.light),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          final result = await Navigator.of(context).pushNamed('/add-announcement');
          if (result == true) _loadAnnouncements();
        },
        child: const Icon(Icons.add),
      ),
      body: RefreshIndicator(
        onRefresh: () async => _loadAnnouncements(),
        child: FutureBuilder<List<Announcement>>(
          future: _announcementsFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            if (snapshot.hasError) return _buildErrorWidget(snapshot.error.toString());
            if (!snapshot.hasData || snapshot.data!.isEmpty) return _buildEmptyStateWidget();

            final announcements = snapshot.data!;
            return ListView.builder(
              padding: const EdgeInsets.all(8.0),
              itemCount: announcements.length,
              itemBuilder: (context, index) {
                return _AnnouncementCard(
                  announcement: announcements[index],
                  onEdit: () => _editAnnouncement(announcements[index]),
                  onDelete: () => _deleteAnnouncement(announcements[index].announcementId),
                );
              },
            );
          },
        ),
      ),
    );
  }

  Widget _buildErrorWidget(String error) {
    final textTheme = Theme.of(context).textTheme;
    final colors = Theme.of(context).colorScheme;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.cloud_off, color: colors.error, size: 60),
            const SizedBox(height: 16),
            Text(
              'Gagal Memuat Data',
              style: textTheme.headlineSmall,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'Terjadi kesalahan saat mengambil data pengumuman.',
              style: textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _loadAnnouncements,
              icon: const Icon(Icons.refresh),
              label: const Text('Coba Lagi'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyStateWidget() {
    final textTheme = Theme.of(context).textTheme;
    final colors = Theme.of(context).colorScheme;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.campaign_outlined, color: colors.secondary, size: 60),
            const SizedBox(height: 16),
            Text(
              'Belum Ada Pengumuman',
              style: textTheme.headlineSmall,
            ),
            const SizedBox(height: 8),
            Text(
              'Semua pengumuman terbaru akan ditampilkan di sini.',
              style: textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

class _AnnouncementCard extends StatelessWidget {
  final Announcement announcement;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _AnnouncementCard({required this.announcement, required this.onEdit, required this.onDelete});

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;

    return Card(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 16, 8, 16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(Icons.campaign, color: colorScheme.primary, size: 24),
                      const SizedBox(width: 12),
                      Expanded(child: Text(announcement.title, style: textTheme.titleMedium)),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Padding(
                    padding: const EdgeInsets.only(left: 36.0),
                    child: Text(announcement.content, style: textTheme.bodyMedium),
                  ),
                  const SizedBox(height: 16),
                  const Divider(),
                  const SizedBox(height: 8),
                  Padding(
                    padding: const EdgeInsets.only(left: 36.0),
                    child: Text(
                      DateFormat('d MMMM yyyy, HH:mm', 'id_ID').format(announcement.createdAt),
                      style: textTheme.bodySmall,
                    ),
                  ),
                ],
              ),
            ),
            PopupMenuButton<String>(
              onSelected: (value) {
                if (value == 'edit') onEdit();
                if (value == 'delete') onDelete();
              },
              itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
                const PopupMenuItem<String>(value: 'edit', child: Text('Edit')),
                const PopupMenuItem<String>(value: 'delete', child: Text('Hapus')),
              ],
            ),
          ],
        ),
      ),
    );
  }
}