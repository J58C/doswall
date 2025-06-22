import 'package:flutter/material.dart';

class NotesCard extends StatelessWidget {
  final bool isSaving;
  final TextEditingController notesController;
  final String? storedNotes;
  final GlobalKey notesExpansionTileKey;
  final ExpansibleController notesExpansionController;
  final FocusNode notesFocusNode;
  final ValueChanged<bool> onExpansionChanged;

  const NotesCard({
    super.key,
    required this.isSaving,
    required this.notesController,
    this.storedNotes,
    required this.notesExpansionTileKey,
    required this.notesExpansionController,
    required this.notesFocusNode,
    required this.onExpansionChanged,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final bool isNotesInteractable = !isSaving;
    return Card(
      elevation: 2,
      margin: const EdgeInsets.symmetric(horizontal: 0),
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Theme(
        data: theme.copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          key: notesExpansionTileKey,
          controller: notesExpansionController,
          onExpansionChanged: onExpansionChanged,
          enabled: isNotesInteractable,
          leading: const Icon(Icons.note_alt_outlined),
          title: const Text('Catatan'),
          subtitle: notesController.text.isNotEmpty
              ? Text(notesController.text,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.bodySmall)
              : const Text('Ketuk untuk menambahkan'),
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 20),
              child: TextField(
                focusNode: notesFocusNode,
                controller: notesController,
                enabled: isNotesInteractable,
                decoration: InputDecoration(
                  hintText: 'Tulis catatan Anda di sini...',
                  suffixIcon: storedNotes != null &&
                      storedNotes!.isNotEmpty &&
                      storedNotes != '-'
                      ? IconButton(
                    icon: const Icon(Icons.history_rounded),
                    tooltip: 'Gunakan catatan sebelumnya',
                    onPressed: isNotesInteractable
                        ? () => notesController.text = storedNotes!
                        : null,
                  )
                      : null,
                ),
                maxLines: 3,
                textInputAction: TextInputAction.done,
              ),
            ),
          ],
        ),
      ),
    );
  }
}