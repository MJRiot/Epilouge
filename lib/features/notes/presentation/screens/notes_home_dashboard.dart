import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../providers/notes_provider.dart';
import '../widgets/category_filter_pills.dart';
import '../widgets/note_actions_sheet.dart';
import '../widgets/note_card.dart';

class NotesHomeDashboard extends ConsumerWidget {
  const NotesHomeDashboard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final filteredNotes = ref.watch(filteredNotesProvider);
    final notesAsync = ref.watch(notesListProvider);
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Wordsy'),
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () {},
          ),
          IconButton(
            icon: const Icon(Icons.more_vert),
            onPressed: () {},
          ),
        ],
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 8),
          const CategoryFilterPills(),
          const SizedBox(height: 16),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Text(
              'My Notes',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: notesAsync.when(
              data: (notes) {
                if (filteredNotes.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.note_add_outlined,
                          size: 64,
                          color: Colors.grey[400],
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'No notes yet',
                          style: TextStyle(
                            fontSize: 18,
                            color: Colors.grey[600],
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Tap + to create your first note',
                          style: TextStyle(
                            color: Colors.grey[500],
                          ),
                        ),
                      ],
                    ),
                  );
                }
                return ListView.builder(
                  itemCount: filteredNotes.length,
                  // Item context is named `itemContext` on purpose: the
                  // quick-actions sheet receives the DASHBOARD's `context`
                  // instead, because item elements get unmounted whenever the
                  // list rebuilds (pin toggle / delete) - using a dead item
                  // context would silently swallow the confirmation snackbars.
                  itemBuilder: (itemContext, index) {
                    final note = filteredNotes[index];
                    return NoteCard(
                      note: note,
                      onTap: () => context.push('/editor?id=${note.id}'),
                      onShowActions: () =>
                          showNoteActionsSheet(context, ref, note),
                    );
                  },
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, stack) => Center(
                child: Text('Error: $error'),
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => context.push('/editor'),
        child: const Icon(Icons.add),
      ),
    );
  }
}
