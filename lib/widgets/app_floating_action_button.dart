import 'package:flutter/material.dart';
import '../view_models/home_view_model.dart';

enum FabType {
  home,
  add,
}

class AppFloatingActionButton extends StatelessWidget {
  final FabType type;
  final HomeViewModel? viewModel;
  final bool isAdmin;
  final VoidCallback? onSaveData;
  final VoidCallback? onAdminAction;
  final VoidCallback? onAnnouncementsAction;
  final VoidCallback? onAddAction;
  final String addLabel;
  final IconData addIcon;

  const AppFloatingActionButton.home({
    super.key,
    required this.viewModel,
    required this.isAdmin,
    required this.onSaveData,
    required this.onAdminAction,
    required this.onAnnouncementsAction,
  })  : type = FabType.home,
        onAddAction = null,
        addLabel = '',
        addIcon = Icons.add;

  const AppFloatingActionButton.add({
    super.key,
    required this.onAddAction,
    this.addLabel = 'Baru',
    this.addIcon = Icons.add_comment_outlined,
  })  : type = FabType.add,
        viewModel = null,
        isAdmin = false,
        onSaveData = null,
        onAdminAction = null,
        onAnnouncementsAction = null;

  @override
  Widget build(BuildContext context) {
    switch (type) {
      case FabType.home:
        assert(viewModel != null);
        assert(onSaveData != null);
        assert(onAdminAction != null);
        assert(onAnnouncementsAction != null);
        return _buildHomeFab(context);
      case FabType.add:
        assert(onAddAction != null);
        return _buildAddFab(context);
    }
  }

  Widget _buildHomeFab(BuildContext context) {
    final theme = Theme.of(context);
    return SizedBox(
      height: 56.0,
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 350),
        transitionBuilder: (Widget child, Animation<double> animation) {
          return SlideTransition(
            position: Tween<Offset>(begin: const Offset(0.0, 2.0), end: Offset.zero).animate(animation),
            child: FadeTransition(opacity: animation, child: child),
          );
        },
        child: (viewModel!.isActive || viewModel!.isNotesExpanded)
            ? Stack(
          key: const ValueKey('active_fabs'),
          children: [
            Positioned(
              right: 16,
              bottom: 0,
              child: FloatingActionButton(
                heroTag: 'fab_announcements',
                onPressed: onAnnouncementsAction,
                tooltip: 'Pengumuman',
                child: const Icon(Icons.campaign_outlined),
              ),
            ),

            if (isAdmin)
              Positioned(
                left: 16,
                bottom: 0,
                child: FloatingActionButton(
                  heroTag: 'admin-fab',
                  onPressed: onAdminAction,
                  tooltip: 'Admin Area',
                  backgroundColor: theme.colorScheme.tertiaryContainer,
                  foregroundColor: theme.colorScheme.onTertiaryContainer,
                  child: const Icon(Icons.admin_panel_settings_outlined),
                ),
              ),

            Align(
              alignment: Alignment.center,
              child: FloatingActionButton.extended(
                heroTag: 'fab_save',
                onPressed: viewModel!.isFetchingLocation || viewModel!.isSaving ? null : onSaveData,
                label: Text(viewModel!.isSaving ? 'Menyimpan...' : 'Simpan'),
                icon: viewModel!.isFetchingLocation || viewModel!.isSaving
                    ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : const Icon(Icons.save_alt_outlined),
              ),
            ),
          ],
        )
            : (isAdmin
            ? Align(
          key: const ValueKey('inactive_admin_fab'),
          alignment: Alignment.center,
          child: FloatingActionButton.extended(
            heroTag: 'admin-fab-inactive',
            onPressed: onAdminAction,
            label: const Text('Admin Panel'),
            icon: const Icon(Icons.admin_panel_settings_outlined),
            backgroundColor: theme.colorScheme.tertiaryContainer,
            foregroundColor: theme.colorScheme.onTertiaryContainer,
          ),
        )
            : const SizedBox.shrink(key: ValueKey('inactive_empty'))),
      ),
    );
  }

  Widget _buildAddFab(BuildContext context) {
    return FloatingActionButton.extended(
      onPressed: onAddAction,
      icon: Icon(addIcon),
      label: Text(addLabel),
    );
  }
}