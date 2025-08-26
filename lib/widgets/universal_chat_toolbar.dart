import 'package:flutter/material.dart';

enum ChatAction {
  text,
  camera,
  gallery,
  files,
  audio,
  call,
  video,
  spaces,
  createImage,
}

enum ChipMode { icon, short, long }

class UniversalChatToolbar extends StatefulWidget {
  const UniversalChatToolbar({
    super.key,
    required this.onAction,
    required this.onSend,
    this.controller,
    this.sending = false,
    this.textFieldFocus,
    this.currentModel,
    this.onPickModel,
    this.createImageActive = false,
  });

  final void Function(ChatAction action) onAction;
  final void Function(String text) onSend;
  final TextEditingController? controller;
  final bool sending;
  final FocusNode? textFieldFocus;
  final String? currentModel;
  final VoidCallback? onPickModel;
  final bool createImageActive;

  @override
  State<UniversalChatToolbar> createState() => _UniversalChatToolbarState();
}

class _UniversalChatToolbarState extends State<UniversalChatToolbar> {
  final Map<ChatAction, ChipMode> _modes = {
    for (final a in ChatAction.values) a: ChipMode.icon,
  };

  void _cycleMode(ChatAction a) {
    setState(() {
      final now = _modes[a]!;
      switch (now) {
        case ChipMode.icon:
          _modes[a] = ChipMode.short;
          break;
        case ChipMode.short:
          _modes[a] = ChipMode.long;
          break;
        case ChipMode.long:
          _modes[a] = ChipMode.icon;
          break;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final all = const [
      ChatAction.camera,
      ChatAction.gallery,
      ChatAction.files,
      ChatAction.audio,
      ChatAction.spaces,
    ];

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [_buildRow(all), const SizedBox(height: 8), _inputRow(context)],
    );
  }

  Widget _inputRow(BuildContext context) {
    final ctrl = widget.controller ?? TextEditingController();
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 0, 8, 12),
      child: Row(
        children: [
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: const Color(0xFF111113), // iOS-like dark input field
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: const Color(0xFF2F3336)),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: ctrl,
                      focusNode: widget.textFieldFocus,
                      textInputAction: TextInputAction.send,
                      onSubmitted: (t) => widget.onSend(t),
                      style: const TextStyle(color: Color(0xFFE7E9EA)),
                      decoration: const InputDecoration.collapsed(
                        hintText: 'Message',
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 8),
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: widget.sending
                  ? Colors.grey.shade800
                  : const Color(0xFF1D9BF0),
              shape: BoxShape.circle,
            ),
            child: IconButton(
              onPressed: widget.sending ? null : () => widget.onSend(ctrl.text),
              icon: const Icon(Icons.arrow_upward_rounded, color: Colors.white),
              splashRadius: 19,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRow(List<ChatAction> actions) {
    return SizedBox(
      height: 36,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 8),
        itemCount: actions.length + 2,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, i) {
          if (i == 0) {
            return _modelChip();
          }
          if (i == 1) {
            return _createImageChip();
          }
          final a = actions[i - 2];
          final mode = _modes[a]!;
          return GestureDetector(
            onLongPress: () => _cycleMode(a),
            child: _buildChip(context, a, mode),
          );
        },
      ),
    );
  }

  Widget _modelChip() {
    final model = widget.currentModel ?? 'gemini-2.5-flash-lite';
    return InkWell(
      onTap: widget.onPickModel,
      borderRadius: BorderRadius.circular(999),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: const Color(0xFF0A0A0A),
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: const Color(0xFF2F3336)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.memory_outlined,
              size: 16,
              color: Color(0xFF71767B),
            ),
            const SizedBox(width: 8),
            Text(model, style: const TextStyle(color: Color(0xFFE7E9EA))),
            const SizedBox(width: 4),
            const Icon(Icons.expand_more, size: 16, color: Color(0xFF71767B)),
          ],
        ),
      ),
    );
  }

  Widget _createImageChip() {
    final active = widget.createImageActive;
    final bg = active ? const Color(0xFF1D9BF0) : const Color(0xFF0A0A0A);
    final fg = active ? Colors.white : const Color(0xFFE7E9EA);
    final ic = active ? Colors.white : const Color(0xFF71767B);
    return InkWell(
      onTap: () => widget.onAction(ChatAction.createImage),
      borderRadius: BorderRadius.circular(999),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: const Color(0xFF2F3336)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.auto_awesome, size: 16, color: ic),
            const SizedBox(width: 8),
            Text('Create imge', style: TextStyle(color: fg)),
          ],
        ),
      ),
    );
  }

  Widget _buildChip(BuildContext context, ChatAction a, ChipMode mode) {
    final icon = _iconFor(a);
    final labelShort = _labelFor(a);
    final labelLong = _longLabelFor(a);

    void trigger() {
      if (a == ChatAction.text && widget.textFieldFocus != null) {
        widget.textFieldFocus!.requestFocus();
      }
      widget.onAction(a);
    }

    // Modern, X-inspired chip visuals
    final baseDecoration = BoxDecoration(
      color: const Color(0xFF0A0A0A),
      borderRadius: BorderRadius.circular(999),
      border: Border.all(color: const Color(0xFF2F3336)),
    );

    switch (mode) {
      case ChipMode.icon:
        return InkWell(
          onTap: trigger,
          borderRadius: BorderRadius.circular(999),
          child: Container(
            width: 36,
            height: 36,
            decoration: baseDecoration,
            child: Center(
              child: Icon(icon, size: 18, color: const Color(0xFF71767B)),
            ),
          ),
        );
      case ChipMode.short:
        return InkWell(
          onTap: trigger,
          borderRadius: BorderRadius.circular(999),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: baseDecoration,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon, size: 16, color: const Color(0xFF71767B)),
                const SizedBox(width: 8),
                Text(
                  labelShort,
                  style: const TextStyle(color: Color(0xFFE7E9EA)),
                ),
              ],
            ),
          ),
        );
      case ChipMode.long:
        return InkWell(
          onTap: trigger,
          borderRadius: BorderRadius.circular(999),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: baseDecoration.copyWith(),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon, size: 16, color: const Color(0xFF71767B)),
                const SizedBox(width: 10),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      labelShort,
                      style: const TextStyle(
                        color: Color(0xFFE7E9EA),
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      labelLong,
                      style: const TextStyle(
                        color: Color(0xFF71767B),
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
    }
  }

  IconData _iconFor(ChatAction a) {
    switch (a) {
      case ChatAction.text:
        return Icons.edit_outlined;
      case ChatAction.camera:
        return Icons.photo_camera_outlined;
      case ChatAction.gallery:
        return Icons.image_outlined;
      case ChatAction.files:
        return Icons.attach_file;
      case ChatAction.audio:
        return Icons.mic_none;
      case ChatAction.call:
        return Icons.call_outlined;
      case ChatAction.video:
        return Icons.videocam_outlined;
      case ChatAction.spaces:
        return Icons.folder_open;
      case ChatAction.createImage:
        return Icons.auto_awesome;
    }
  }

  String _labelFor(ChatAction a) {
    switch (a) {
      case ChatAction.text:
        return 'Text';
      case ChatAction.camera:
        return 'Camera';
      case ChatAction.gallery:
        return 'Images';
      case ChatAction.files:
        return 'Files';
      case ChatAction.audio:
        return 'Audio';
      case ChatAction.call:
        return 'Call';
      case ChatAction.video:
        return 'Video';
      case ChatAction.spaces:
        return 'Spaces';
      case ChatAction.createImage:
        return 'Create imge';
    }
  }

  String _longLabelFor(ChatAction a) {
    switch (a) {
      case ChatAction.text:
        return 'Type a message';
      case ChatAction.camera:
        return 'Take a photo';
      case ChatAction.gallery:
        return 'Pick images';
      case ChatAction.files:
        return 'Attach files';
      case ChatAction.audio:
        return 'Record audio';
      case ChatAction.call:
        return 'Start call';
      case ChatAction.video:
        return 'Start video';
      case ChatAction.spaces:
        return 'Add space context';
      case ChatAction.createImage:
        return 'Generate from text';
    }
  }
}
