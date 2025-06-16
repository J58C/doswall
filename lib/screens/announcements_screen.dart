import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../services/announcement_service.dart';
import '../models/announcement_response.dart';
import '../theme/custom_colors.dart';
import '../providers/theme_notifier.dart';

class AnnouncementsScreen extends StatefulWidget {
  const AnnouncementsScreen({super.key});

  @override
  State<AnnouncementsScreen> createState() => _AnnouncementsScreenState();
}

class _AnnouncementsScreenState extends State<AnnouncementsScreen> {
  late Future<List<Announcement>> _announcementsFuture;
  final _announcementService = AnnouncementService();

  @override
  void initState() {
    super.initState();
    _loadAnnouncements();
  }

  void _loadAnnouncements() {
    setState(() {
      _announcementsFuture = _announcementService.fetchAnnouncements();
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
          ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Theme.of(context).colorScheme.error,
                foregroundColor: Theme.of(context).colorScheme.onError,
              ),
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Hapus')
          ),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      final success = await _announcementService.deleteAnnouncement(announcementId: announcementId);
      if (mounted) {
        _showFeedback(success,
            successMessage: 'Pengumuman berhasil dihapus.',
            errorMessage: 'Gagal menghapus pengumuman.'
        );
        if (success) _loadAnnouncements();
      }
    } catch (e) {
      if (mounted) {
        _showFeedback(false, errorMessage: 'Error: ${e.toString()}', successMessage: '');
      }
    }
  }

  void _openAnnouncementForm({Announcement? announcement}) async {
    final result = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
        child: _AnnouncementFormSheet(
          announcement: announcement,
          service: _announcementService,
        ),
      ),
    );

    if (result == true) {
      _loadAnnouncements();
    }
  }

  void _showFeedback(bool success, {required String successMessage, required String errorMessage}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(success ? successMessage : errorMessage),
        backgroundColor: success
            ? Theme.of(context).extension<CustomColors>()?.success
            : Theme.of(context).colorScheme.errorContainer,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final themeNotifier = Provider.of<ThemeNotifier>(context);
    final isDark = theme.brightness == Brightness.dark;

    Color appBarColor = isDark ? theme.colorScheme.surface : theme.colorScheme.primary;
    Color onAppBarColor = isDark ? theme.colorScheme.onSurface : theme.colorScheme.onPrimary;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text('Pengumuman', style: theme.textTheme.headlineSmall?.copyWith(color: onAppBarColor)),
        backgroundColor: appBarColor,
        elevation: 1,
        shadowColor: Colors.black.withAlpha(50),
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: onAppBarColor),
          onPressed: () => Navigator.of(context).pop(),
        ),
        actions: [
          IconButton(
            icon: Icon(isDark ? Icons.light_mode_outlined : Icons.dark_mode_outlined),
            tooltip: isDark ? 'Mode Terang' : 'Mode Gelap',
            onPressed: () => themeNotifier.toggleTheme(theme.brightness),
            color: onAppBarColor,
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openAnnouncementForm(),
        icon: const Icon(Icons.add_comment_outlined),
        label: const Text('Baru'),
      ),
      body: Stack(
        children: [
          _buildArtisticBackground(context, isDark),
          RefreshIndicator(
            onRefresh: () async => _loadAnnouncements(),
            child: FutureBuilder<List<Announcement>>(
              future: _announcementsFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) return _buildErrorWidget();
                if (!snapshot.hasData || snapshot.data!.isEmpty) return _buildEmptyStateWidget();

                final announcements = snapshot.data!;
                return ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                  itemCount: announcements.length,
                  itemBuilder: (context, index) {
                    return _AnnouncementCard(
                      announcement: announcements[index],
                      onEdit: () => _openAnnouncementForm(announcement: announcements[index]),
                      onDelete: () => _deleteAnnouncement(announcements[index].announcementId),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildArtisticBackground(BuildContext context, bool isDark) {
    final primary = Theme.of(context).colorScheme.primary;
    final secondary = Theme.of(context).colorScheme.secondary;

    return Stack(
      children: [
        Positioned(
          top: -120,
          left: -180,
          child: Container(
            width: 350,
            height: 350,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: primary.withAlpha(isDark ? 30 : 50),
            ),
          ),
        ),
        Positioned(
          bottom: -150,
          right: -100,
          child: Container(
            width: 320,
            height: 320,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: secondary.withAlpha(isDark ? 35 : 55),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildErrorWidget() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.cloud_off_outlined, color: Theme.of(context).colorScheme.error, size: 60),
            const SizedBox(height: 16),
            Text('Gagal Memuat Data', style: Theme.of(context).textTheme.headlineSmall, textAlign: TextAlign.center),
            const SizedBox(height: 8),
            Text('Terjadi kesalahan saat mengambil data. Silakan coba lagi.', style: Theme.of(context).textTheme.bodyMedium, textAlign: TextAlign.center),
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
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.campaign_outlined, color: Theme.of(context).colorScheme.secondary, size: 60),
            const SizedBox(height: 16),
            Text('Belum Ada Pengumuman', style: Theme.of(context).textTheme.headlineSmall),
            const SizedBox(height: 8),
            Text('Semua pengumuman terbaru akan ditampilkan di sini.', style: Theme.of(context).textTheme.bodyMedium, textAlign: TextAlign.center),
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
    final theme = Theme.of(context);
    final textTheme = theme.textTheme;
    final colorScheme = theme.colorScheme;

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8.0),
      elevation: 2,
      shadowColor: Colors.black.withAlpha(20),
      shape: RoundedRectangleBorder(
        side: BorderSide(color: colorScheme.outlineVariant.withAlpha(80), width: 0.5),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.campaign_outlined, color: colorScheme.primary, size: 24),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    announcement.title,
                    style: textTheme.titleLarge,
                  ),
                ),
                SizedBox(
                  width: 28,
                  height: 28,
                  child: PopupMenuButton<String>(
                    iconSize: 20,
                    onSelected: (value) {
                      if (value == 'edit') onEdit();
                      if (value == 'delete') onDelete();
                    },
                    itemBuilder: (context) => <PopupMenuEntry<String>>[
                      const PopupMenuItem<String>(
                        value: 'edit',
                        child: ListTile(leading: Icon(Icons.edit_outlined, size: 20), title: Text('Edit')),
                      ),
                      const PopupMenuItem<String>(
                        value: 'delete',
                        child: ListTile(leading: Icon(Icons.delete_outline, size: 20), title: Text('Hapus')),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Padding(
              padding: const EdgeInsets.only(left: 36.0),
              child: Text(announcement.content, style: textTheme.bodyMedium),
            ),
            const SizedBox(height: 16),
            const Divider(height: 1),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.only(left: 36.0),
              child: Row(
                children: [
                  Icon(Icons.access_time, size: 14, color: textTheme.bodySmall?.color),
                  const SizedBox(width: 6),
                  Text(
                    DateFormat('d MMMM yyyy, HH:mm', 'id_ID').format(announcement.createdAt),
                    style: textTheme.bodySmall,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AnnouncementFormSheet extends StatefulWidget {
  final Announcement? announcement;
  final AnnouncementService service;
  const _AnnouncementFormSheet({
    this.announcement,
    required this.service
  });

  @override
  State<_AnnouncementFormSheet> createState() => _AnnouncementFormSheetState();
}

class _AnnouncementFormSheetState extends State<_AnnouncementFormSheet> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _titleController;
  late final TextEditingController _contentController;
  bool _isLoading = false;

  bool get _isEditing => widget.announcement != null;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.announcement?.title);
    _contentController = TextEditingController(text: widget.announcement?.content);
  }

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    super.dispose();
  }

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      bool success = false;
      if (_isEditing) {
        success = await widget.service.updateAnnouncement(
          announcementId: widget.announcement!.announcementId,
          title: _titleController.text,
          content: _contentController.text,
        );
      } else {
        final newId = await widget.service.addAnnouncement(
          title: _titleController.text,
          content: _contentController.text,
        );
        success = newId != null;
      }

      if (mounted) {
        Navigator.of(context).pop(success);
      }
    } catch(e) {
      if(mounted) {
        Navigator.of(context).pop(false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: theme.scaffoldBackgroundColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              _isEditing ? 'Edit Pengumuman' : 'Tambah Pengumuman Baru',
              style: theme.textTheme.headlineSmall,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            TextFormField(
              controller: _titleController,
              decoration: const InputDecoration(labelText: 'Judul'),
              validator: (v) => v!.trim().isEmpty ? 'Judul tidak boleh kosong' : null,
              textInputAction: TextInputAction.next,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _contentController,
              decoration: const InputDecoration(labelText: 'Konten'),
              maxLines: 4,
              validator: (v) => v!.trim().isEmpty ? 'Konten tidak boleh kosong' : null,
              textInputAction: TextInputAction.newline,
            ),
            const SizedBox(height: 24),
            SizedBox(
              height: 50,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _submitForm,
                child: _isLoading
                    ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : Text(_isEditing ? 'Simpan Perubahan' : 'Kirim Pengumuman'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}