import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../enums/view_state.dart';
import '../view_models/announcements_view_model.dart';
import '../models/announcement_response.dart';
import '../models/background_shape.dart';

import '../widgets/artistic_background.dart';
import '../widgets/app_floating_action_button.dart';
import '../theme/custom_colors.dart';
import '../providers/theme_notifier.dart';

class AnnouncementsScreen extends StatefulWidget {
  const AnnouncementsScreen({super.key});

  @override
  State<AnnouncementsScreen> createState() => _AnnouncementsScreenState();
}

class _AnnouncementsScreenState extends State<AnnouncementsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AnnouncementsViewModel>().fetchAnnouncements();
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
              child: const Text('Hapus')),
        ],
      ),
    );

    if (confirm != true) return;

    if (mounted) {
      await context.read<AnnouncementsViewModel>().deleteAnnouncement(
        announcementId: announcementId,
        onSuccess: (message) => _showFeedback(true, message),
        onError: (message) => _showFeedback(false, message),
      );
    }
  }

  void _openAnnouncementForm({Announcement? announcement}) async {
    final viewModel = context.read<AnnouncementsViewModel>();
    final result = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
        child: _AnnouncementFormSheet(
          announcement: announcement,
          onSubmit: (title, content) {
            if (announcement == null) {
              return viewModel.addAnnouncement(title: title, content: content);
            } else {
              return viewModel.updateAnnouncement(
                  announcementId: announcement.announcementId, title: title, content: content);
            }
          },
        ),
      ),
    );

    if (result != null) {
      final String message = result
          ? (announcement == null ? 'Pengumuman berhasil ditambah.' : 'Pengumuman berhasil diperbarui.')
          : 'Gagal menyimpan pengumuman.';
      _showFeedback(result, message);
    }
  }

  void _showFeedback(bool success, String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: success
            ? Theme.of(context).extension<CustomColors>()?.success
            : Theme.of(context).colorScheme.errorContainer,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final viewModel = context.watch<AnnouncementsViewModel>();
    final theme = Theme.of(context);
    final themeNotifier = context.watch<ThemeNotifier>();
    final isDark = theme.brightness == Brightness.dark;

    Color appBarColor = isDark ? theme.colorScheme.surface : theme.colorScheme.primary;
    Color onAppBarColor = isDark ? theme.colorScheme.onSurface : theme.colorScheme.onPrimary;

    final tertiaryColor = theme.colorScheme.tertiary;
    final List<BackgroundShape> announcementScreenPattern = [
      BackgroundShape(
        top: 20,
        right: -80,
        width: 200,
        height: 200,
        color: tertiaryColor.withAlpha(isDark ? 35 : 50),
      ),
      BackgroundShape(
        bottom: 100,
        left: -120,
        width: 300,
        height: 300,
        color: tertiaryColor.withAlpha(isDark ? 25 : 40),
      ),
    ];

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text('Pengumuman', style: theme.textTheme.headlineSmall?.copyWith(color: onAppBarColor)),
        backgroundColor: appBarColor,
        elevation: 1,
        shadowColor: Colors.black.withAlpha(50),
        leading: IconButton(icon: Icon(Icons.arrow_back, color: onAppBarColor), onPressed: () => Navigator.of(context).pop()),
        actions: [
          IconButton(
            icon: Icon(isDark ? Icons.light_mode_outlined : Icons.dark_mode_outlined),
            onPressed: () => themeNotifier.toggleTheme(theme.brightness),
            color: onAppBarColor,
          ),
        ],
      ),
      floatingActionButton: AppFloatingActionButton.add(
        onAddAction: () => _openAnnouncementForm(),
      ),
      body: Stack(
        children: [
          ArtisticBackground(shapes: announcementScreenPattern),
          RefreshIndicator(
            onRefresh: () => viewModel.fetchAnnouncements(),
            child: _buildBody(viewModel),
          ),
        ],
      ),
    );
  }

  Widget _buildBody(AnnouncementsViewModel viewModel) {
    switch (viewModel.state) {
      case ViewState.loading:
        return const Center(child: CircularProgressIndicator());
      case ViewState.error:
        return _buildErrorWidget(viewModel);
      case ViewState.empty:
        return _buildEmptyStateWidget();
      case ViewState.success:
        return ListView.builder(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
          itemCount: viewModel.announcements.length,
          itemBuilder: (context, index) {
            final announcement = viewModel.announcements[index];
            return _AnnouncementCard(
              announcement: announcement,
              onEdit: () => _openAnnouncementForm(announcement: announcement),
              onDelete: () => _deleteAnnouncement(announcement.announcementId),
            );
          },
        );
      case ViewState.idle:
        return const SizedBox.shrink();
    }
  }

  Widget _buildErrorWidget(AnnouncementsViewModel viewModel) {
    return Center(
        child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
              Icon(Icons.cloud_off_outlined, color: Theme.of(context).colorScheme.error, size: 60),
              const SizedBox(height: 16),
              Text('Gagal Memuat Data', style: Theme.of(context).textTheme.headlineSmall, textAlign: TextAlign.center),
              const SizedBox(height: 8),
              Text(viewModel.errorMessage, style: Theme.of(context).textTheme.bodyMedium, textAlign: TextAlign.center),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                  onPressed: () => viewModel.fetchAnnouncements(),
                  icon: const Icon(Icons.refresh),
                  label: const Text('Coba Lagi'))
            ])));
  }

  Widget _buildEmptyStateWidget() {
    return Center(
        child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
              Icon(Icons.campaign_outlined, color: Theme.of(context).colorScheme.secondary, size: 60),
              const SizedBox(height: 16),
              Text('Belum Ada Pengumuman', style: Theme.of(context).textTheme.headlineSmall),
              const SizedBox(height: 8),
              Text('Semua pengumuman terbaru akan ditampilkan di sini.',
                  style: Theme.of(context).textTheme.bodyMedium, textAlign: TextAlign.center)
            ])));
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
            borderRadius: BorderRadius.circular(16)),
        child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Icon(Icons.campaign_outlined, color: colorScheme.primary, size: 24),
                const SizedBox(width: 12),
                Expanded(child: Text(announcement.title, style: textTheme.titleLarge)),
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
                              child: ListTile(leading: Icon(Icons.edit_outlined, size: 20), title: Text('Edit'))),
                          const PopupMenuItem<String>(
                              value: 'delete',
                              child: ListTile(
                                  leading: Icon(Icons.delete_outline, size: 20), title: Text('Hapus')))
                        ]))
              ]),
              const SizedBox(height: 12),
              Padding(padding: const EdgeInsets.only(left: 36.0), child: Text(announcement.content, style: textTheme.bodyMedium)),
              const SizedBox(height: 16),
              const Divider(height: 1),
              const SizedBox(height: 8),
              Padding(
                  padding: const EdgeInsets.only(left: 36.0),
                  child: Row(children: [
                    Icon(Icons.access_time, size: 14, color: textTheme.bodySmall?.color),
                    const SizedBox(width: 6),
                    Text(DateFormat('d MMMM yyyy, HH:mm', 'id_ID').format(announcement.createdAt),
                        style: textTheme.bodySmall)
                  ]))
            ])));
  }
}

class _AnnouncementFormSheet extends StatefulWidget {
  final Announcement? announcement;
  final Future<bool> Function(String title, String content) onSubmit;

  const _AnnouncementFormSheet({this.announcement, required this.onSubmit});

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

    final success = await widget.onSubmit(_titleController.text, _contentController.text);

    if (mounted) {
      Navigator.of(context).pop(success);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
            color: theme.scaffoldBackgroundColor,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24))),
        child: Form(
            key: _formKey,
            child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.stretch, children: [
              Text(_isEditing ? 'Edit Pengumuman' : 'Tambah Pengumuman Baru',
                  style: theme.textTheme.headlineSmall, textAlign: TextAlign.center),
              const SizedBox(height: 24),
              TextFormField(
                  controller: _titleController,
                  decoration: const InputDecoration(labelText: 'Judul'),
                  validator: (v) => v!.trim().isEmpty ? 'Judul tidak boleh kosong' : null,
                  textInputAction: TextInputAction.next),
              const SizedBox(height: 16),
              TextFormField(
                  controller: _contentController,
                  decoration: const InputDecoration(labelText: 'Konten'),
                  maxLines: 4,
                  validator: (v) => v!.trim().isEmpty ? 'Konten tidak boleh kosong' : null,
                  textInputAction: TextInputAction.newline),
              const SizedBox(height: 24),
              SizedBox(
                  height: 50,
                  child: ElevatedButton(
                      onPressed: _isLoading ? null : _submitForm,
                      child: _isLoading
                          ? const SizedBox(
                          width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                          : Text(_isEditing ? 'Simpan Perubahan' : 'Kirim Pengumuman')))
            ])));
  }
}