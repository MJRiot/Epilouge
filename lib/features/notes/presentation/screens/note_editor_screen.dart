import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_quill/flutter_quill.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:uuid/uuid.dart';
import 'package:image_picker/image_picker.dart';
import '../../../../core/constants/app_constants.dart';
import '../../domain/note_model.dart';
import '../providers/notes_provider.dart';

class NoteEditorScreen extends ConsumerStatefulWidget {
  final String? noteId;
  
  const NoteEditorScreen({super.key, this.noteId});

  @override
  ConsumerState<NoteEditorScreen> createState() => _NoteEditorScreenState();
}

class _NoteEditorScreenState extends ConsumerState<NoteEditorScreen> {
  final _titleController = TextEditingController();
  late QuillController _quillController;

  // Editor focus/scroll state, created ONCE and reused across rebuilds.
  // If these were constructed inline in build(), every rebuild would create a
  // new instance that never gets disposed -> memory leak + broken focus/scroll.
  final _editorFocusNode = FocusNode();
  final _editorScrollController = ScrollController();
  String _selectedCategory = 'Personal';
  Color _selectedColor = Colors.orange;
  final List<String> _imagePaths = [];
  Note? _existingNote;
  
  final List<Color> _noteColors = [
    Colors.orange,
    Colors.blue,
    Colors.green,
    Colors.purple,
    Colors.pink,
    Colors.red,
    Colors.teal,
  ];

  @override
  void initState() {
    super.initState();
    _quillController = QuillController.basic();
    if (widget.noteId != null) {
      _loadNote();
    }
  }

  Future<void> _loadNote() async {
    final notes = await ref.read(notesListProvider.future);
    try {
      _existingNote = notes.firstWhere((n) => n.id == widget.noteId);
      _titleController.text = _existingNote!.title;
      _selectedCategory = _existingNote!.category;
      _selectedColor = Color(_existingNote!.color);
      _imagePaths.addAll(_existingNote!.imagePaths);
      
      if (_existingNote!.content.isNotEmpty) {
        try {
          final doc = Document.fromJson(jsonDecode(_existingNote!.content));
          _quillController = QuillController(
            document: doc,
            selection: const TextSelection.collapsed(offset: 0),
          );
        } catch (e) {
          _quillController = QuillController.basic();
        }
      }
      setState(() {});
    } catch (e) {
      // Note not found
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _quillController.dispose();
    // Release focus/scroll resources when the screen is closed.
    _editorFocusNode.dispose();
    _editorScrollController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        _imagePaths.add(pickedFile.path);
      });
    }
  }

  Future<void> _saveNote() async {
    final content = jsonEncode(_quillController.document.toDelta().toJson());
    final now = DateTime.now();
    
    final note = Note(
      id: _existingNote?.id ?? const Uuid().v4(),
      title: _titleController.text,
      content: content,
      category: _selectedCategory,
      color: _selectedColor.toARGB32(),
      createdAt: _existingNote?.createdAt ?? now,
      updatedAt: now,
      imagePaths: _imagePaths,
    );
    
    if (_existingNote != null) {
      await ref.read(notesListProvider.notifier).updateNote(note);
    } else {
      await ref.read(notesListProvider.notifier).addNote(note);
    }
    
    if (mounted) context.pop();
  }

  Future<void> _deleteNote() async {
    if (_existingNote == null) return;

    // Guard against accidental data loss: ask the user to confirm first.
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete note?'),
        content: const Text('This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: TextButton.styleFrom(
              foregroundColor: Theme.of(ctx).colorScheme.error,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    // Only delete if the user actually confirmed.
    if (confirmed != true) return;

    // The dialog was awaited, so check `mounted` before using context again.
    if (!mounted) return;
    await ref.read(notesListProvider.notifier).deleteNote(_existingNote!.id);
    if (mounted) context.pop();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_existingNote != null ? 'Edit Note' : 'New Note'),
        actions: [
          if (_existingNote != null)
            IconButton(
              icon: const Icon(Icons.delete_outline),
              onPressed: _deleteNote,
            ),
          IconButton(
            icon: const Icon(Icons.check),
            onPressed: _saveNote,
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              controller: _titleController,
              decoration: const InputDecoration(
                hintText: 'Note title...',
                border: InputBorder.none,
                filled: false,
              ),
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                DropdownButton<String>(
                  value: _selectedCategory,
                  items: AppConstants.defaultCategories
                      .where((c) => c != 'All')
                      .map((category) {
                    return DropdownMenuItem(
                      value: category,
                      child: Text(category),
                    );
                  }).toList(),
                  onChanged: (value) {
                    if (value != null) {
                      setState(() => _selectedCategory = value);
                    }
                  },
                ),
                const SizedBox(width: 16),
                const Text('Color:'),
                const SizedBox(width: 8),
                ..._noteColors.map((color) {
                  return GestureDetector(
                    onTap: () => setState(() => _selectedColor = color),
                    child: Container(
                      margin: const EdgeInsets.only(right: 8),
                      width: 24,
                      height: 24,
                      decoration: BoxDecoration(
                        color: color,
                        shape: BoxShape.circle,
                        border: _selectedColor == color
                            ? Border.all(color: Colors.black, width: 2)
                            : null,
                      ),
                    ),
                  );
                }),
              ],
            ),
          ),
          const Divider(),
          QuillSimpleToolbar(
            controller: _quillController,
          ),
          const Divider(),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: QuillEditor(
                controller: _quillController,
                // Reuse the long-lived instances instead of creating new ones
                // on every rebuild.
                focusNode: _editorFocusNode,
                scrollController: _editorScrollController,
                config: const QuillEditorConfig(
                  placeholder: 'Start writing...',
                ),
              ),
            ),
          ),
          if (_imagePaths.isNotEmpty)
            SizedBox(
              height: 100,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.all(8),
                itemCount: _imagePaths.length,
                itemBuilder: (context, index) {
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: Stack(
                      children: [
                        Image.file(
                          File(_imagePaths[index]),
                          width: 100,
                          height: 100,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => Container(
                            width: 100,
                            height: 100,
                            color: Colors.grey[300],
                            child: const Icon(Icons.image),
                          ),
                        ),
                        Positioned(
                          top: 4,
                          right: 4,
                          child: GestureDetector(
                            onTap: () {
                              setState(() => _imagePaths.removeAt(index));
                            },
                            child: Container(
                              decoration: const BoxDecoration(
                                color: Colors.black54,
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.close,
                                color: Colors.white,
                                size: 16,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          Padding(
            padding: const EdgeInsets.all(8),
            child: Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.image_outlined),
                  onPressed: _pickImage,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
