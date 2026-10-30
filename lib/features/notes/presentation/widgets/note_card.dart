import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import '../../../../core/utils/delta_utils.dart';
import '../../domain/note_model.dart';

/// A single note tile in the list.
///
/// Gestures:
///  - tap        -> open the note ([onTap])
///  - long-press -> open quick actions ([onShowActions]) with haptic feedback
///  - ⋮ button   -> same quick actions, for users who don't discover long-press
///
/// Visual feedback: a subtle background tint + raised shadow while the tile is
/// pressed, held, or hovered - animated smoothly via [AnimatedContainer].
class NoteCard extends StatefulWidget {
  final Note note;
  final VoidCallback onTap;

  /// Opens the quick-actions bottom sheet (long-press or the ⋮ button).
  final VoidCallback onShowActions;

  const NoteCard({
    super.key,
    required this.note,
    required this.onTap,
    required this.onShowActions,
  });

  @override
  State<NoteCard> createState() => _NoteCardState();
}

class _NoteCardState extends State<NoteCard> {
  /// True while the tile is touched (finger down, tap or long-press).
  bool _pressed = false;

  /// True while hovering with a mouse/stylus (desktop & web).
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final note = widget.note;
    final dateFormat = DateFormat('MMM dd, yyyy');

    // One flag drives all feedback: touch OR hover.
    final active = _pressed || _hovered;

    // Root of the tile. AnimatedContainer animates BOTH the background tint
    // and the box shadow (our "elevation") whenever [active] flips.
    return AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      curve: Curves.easeOut,
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        // Very light primary tint when pressed/hovered, normal surface
        // color otherwise - lerp keeps it subtle and theme-aware.
        color: active
            ? Color.lerp(colorScheme.surface, colorScheme.primary, 0.08)!
            : colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: active ? 0.16 : 0.06),
            blurRadius: active ? 14 : 4,
            offset: Offset(0, active ? 6 : 2),
          ),
        ],
      ),
      // Transparent Material = ink canvas so the InkWell ripples below
      // are visible on top of the animated background.
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: widget.onTap,
          onLongPress: () {
            // Nudge so the user feels the menu is about to open.
            HapticFeedback.mediumImpact();
            widget.onShowActions();
          },
          // These two drive the pressed/hovered state above.
          onHighlightChanged: (value) => setState(() => _pressed = value),
          onHover: (value) => setState(() => _hovered = value),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    // Color accent bar matching the note's chosen color.
                    Container(
                      width: 4,
                      height: 20,
                      decoration: BoxDecoration(
                        color: Color(note.color),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        note.title.isEmpty ? 'Untitled' : note.title,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    // Pin indicator: small icon only when actually pinned.
                    if (note.pinned) ...[
                      Icon(
                        Icons.push_pin,
                        size: 14,
                        color: colorScheme.primary,
                      ),
                      const SizedBox(width: 6),
                    ],
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: colorScheme.primaryContainer,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        note.category,
                        style: TextStyle(
                          fontSize: 12,
                          color: colorScheme.onPrimaryContainer,
                        ),
                      ),
                    ),
                    // Explicit menu entry point next to the category chip.
                    IconButton(
                      onPressed: widget.onShowActions,
                      icon: const Icon(Icons.more_vert, size: 18),
                      tooltip: 'Note actions',
                      visualDensity: VisualDensity.compact,
                      constraints: const BoxConstraints(
                        minWidth: 32,
                        minHeight: 32,
                      ),
                      padding: EdgeInsets.zero,
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                // Clean plain text preview (Delta JSON -> readable text).
                Text(
                  deltaToPlainText(note.content),
                  style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Edited ${dateFormat.format(note.updatedAt)}',
                      style: TextStyle(fontSize: 12, color: Colors.grey[500]),
                    ),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Reminder indicator with the scheduled time.
                        if (note.reminderAt != null) ...[
                          Icon(Icons.alarm, size: 14, color: colorScheme.primary),
                          const SizedBox(width: 4),
                          Text(
                            DateFormat('MMM d, h:mm a')
                                .format(note.reminderAt!),
                            style: TextStyle(
                              fontSize: 12,
                              color: colorScheme.primary,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(width: 8),
                        ],
                        if (note.imagePaths.isNotEmpty)
                          Icon(Icons.image, size: 16, color: Colors.grey[500]),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
