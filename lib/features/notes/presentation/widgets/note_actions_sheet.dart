import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../domain/note_model.dart';
import '../providers/notes_provider.dart';

/// Opens the quick-actions bottom sheet for [note].
///
/// Called from a note tile's long-press or its trailing ⋮ button.
/// [context] should be a context that stays valid while the sheet is open
/// (the list screen's context), so snackbars still show after the sheet closes.
Future<void> showNoteActionsSheet(
  BuildContext context,
  WidgetRef ref,
  Note note,
) {
  // Pop the sheet FIRST after a tap, then run the action against the
  // screen context - this keeps dialogs/snackbars anchored to the screen,
  // not to the (closing) sheet.
  return showModalBottomSheet<void>(
    context: context,
    showDragHandle: true, // Material 3 drag handle at the top
    builder: (sheetContext) {
      // Rebuild-safe read of the current note from the provider, so the
      // sheet always shows fresh state (e.g. pin icon) even if reused.
      return SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _SheetHeader(title: note.title.isEmpty ? 'Untitled' : note.title),
            ListTile(
              leading: Icon(note.pinned ? Icons.push_pin : Icons.push_pin_outlined),
              title: Text(note.pinned ? 'Unpin note' : 'Pin note'),
              subtitle: Text(
                note.pinned
                    ? 'Remove from the top of your list'
                    : 'Keep at the top of your list',
              ),
              onTap: () async {
                Navigator.of(sheetContext).pop();
                // Capture before the state changes for the snackbar text.
                final wasPinned = note.pinned;
                if (!context.mounted) return;
                await ref.read(notesListProvider.notifier).togglePin(note);
                if (!context.mounted) return;
                _showMessage(context, wasPinned ? 'Note unpinned' : 'Note pinned');
              },
            ),
            ListTile(
              leading: const Icon(Icons.alarm),
              title: const Text('Set reminder'),
              // Show the currently scheduled time, if any.
              subtitle: note.reminderAt == null
                  ? const Text('Pick a date and time')
                  : Text(
                      'Reminder: ${DateFormat('MMM d, yyyy • h:mm a').format(note.reminderAt!)}',
                    ),
              onTap: () => _pickReminder(context, ref, sheetContext, note),
            ),
            // Only offer clearing when a reminder actually exists.
            if (note.reminderAt != null)
              ListTile(
                leading: const Icon(Icons.alarm_off),
                title: const Text('Clear reminder'),
                onTap: () async {
                  Navigator.of(sheetContext).pop();
                  if (!context.mounted) return;
                  await ref
                      .read(notesListProvider.notifier)
                      .setReminder(note, null);
                  if (context.mounted) _showMessage(context, 'Reminder cleared');
                },
              ),
            const Divider(height: 1),
            ListTile(
              leading: Icon(
                Icons.delete_outline,
                color: Theme.of(context).colorScheme.error,
              ),
              title: Text(
                'Delete note',
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
              onTap: () => _confirmDelete(context, ref, sheetContext, note),
            ),
            const SizedBox(height: 8),
          ],
        ),
      );
    },
  );
}

/// Small header showing which note the actions apply to.
class _SheetHeader extends StatelessWidget {
  final String title;
  const _SheetHeader({required this.title});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
      child: Row(
        children: [
          Expanded(
            child: Text(
              title,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primaryContainer,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              'Quick actions',
              style: TextStyle(
                fontSize: 11,
                color: Theme.of(context).colorScheme.onPrimaryContainer,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Date picker -> time picker -> save the combined reminder to the note.
Future<void> _pickReminder(
  BuildContext context,
  WidgetRef ref,
  BuildContext sheetContext,
  Note note,
) async {
  // Close the sheet so the pickers aren't stacked on top of it.
  Navigator.of(sheetContext).pop();

  // Pre-fill the pickers with the existing reminder (or "now" as a default).
  final now = note.reminderAt ?? DateTime.now();

  final date = await showDatePicker(
    context: context,
    initialDate: now,
    firstDate: DateTime.now(), // can't remind in the past
    lastDate: DateTime(now.year + 5),
  );
  if (date == null || !context.mounted) return;

  final time = await showTimePicker(
    context: context,
    initialTime: TimeOfDay.fromDateTime(now),
  );
  if (time == null || !context.mounted) return;

  // Combine the picked date + time into one DateTime.
  final reminder = DateTime(date.year, date.month, date.day, time.hour, time.minute);

  await ref.read(notesListProvider.notifier).setReminder(note, reminder);
  if (!context.mounted) return;
  _showMessage(
    context,
    'Reminder set for ${DateFormat('MMM d, yyyy • h:mm a').format(reminder)}',
  );
}

/// Double-confirmation for destructive delete (the sheet already counts
/// as the first tap, this prevents losing a note with one stray tap).
Future<void> _confirmDelete(
  BuildContext context,
  WidgetRef ref,
  BuildContext sheetContext,
  Note note,
) async {
  Navigator.of(sheetContext).pop();

  final confirmed = await showDialog<bool>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      title: const Text('Delete note?'),
      content: const Text('This action cannot be undone.'),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(dialogContext).pop(false),
          child: const Text('Cancel'),
        ),
        TextButton(
          onPressed: () => Navigator.of(dialogContext).pop(true),
          style: TextButton.styleFrom(
            foregroundColor: Theme.of(dialogContext).colorScheme.error,
          ),
          child: const Text('Delete'),
        ),
      ],
    ),
  );

  if (confirmed != true || !context.mounted) return;

  await ref.read(notesListProvider.notifier).deleteNote(note.id);
  if (!context.mounted) return;
  _showMessage(context, 'Note deleted');
}

/// Convenience wrapper so every action gives the same kind of feedback.
void _showMessage(BuildContext context, String message) {
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(content: Text(message)));
}
