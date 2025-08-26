import 'package:flutter/material.dart';

enum ChatAction { text, camera, gallery, files, audio, call, video, spaces }

enum ChipMode { icon, short, long }

class UniversalChatToolbar extends StatefulWidget {
  const UniversalChatToolbar({
    super.key,
    required this.onAction,
    required this.onSend,
    this.controller,
    this.sending = false,
    this.textFieldFocus,
  });

  final void Function(ChatAction action) onAction;
  final void Function(String text) onSend;
  final TextEditingController? controller;
  final bool sending;
  final FocusNode? textFieldFocus;

  @override
  State<UniversalChatToolbar> createState() => _UniversalChatToolbarState();
}

class _UniversalChatToolbarState extends State<UniversalChatToolbar> {
  final Map<ChatAction, ChipMode> _modes = {
    for (final a in ChatAction.values) a: ChipMode.short,
  };

  void _cycleMode(ChatAction a) {
    setState(() {
      final now = _modes[a]!;
      _modes[a] = now == ChipMode.icon
          ? ChipMode.short
          : now == ChipMode.short
          ? ChipMode.long
          : ChipMode.icon;
    });
  }

  @override
  Widget build(BuildContext context) {
    final row1 = const [
      ChatAction.text,
      ChatAction.camera,
      ChatAction.gallery,
      ChatAction.files,
    ];
    final row2 = const [
      ChatAction.audio,
      ChatAction.call,
      ChatAction.video,
      ChatAction.spaces,
    ];

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _buildRow(row1),
        const SizedBox(height: 8),
        _buildRow(row2),
        const SizedBox(height: 8),
        _inputRow(context),
      ],
    );
  }

  Widget _inputRow(BuildContext context) {
    final ctrl = widget.controller ?? TextEditingController();
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 0, 8, 8),
      child: Row(
        children: [
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: const Color(0xFF0A0A0A),
                borderRadius: BorderRadius.circular(999),
                border: Border.all(color: const Color(0xFF2F3336)),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.edit_outlined,
                    size: 18,
                    color: const Color(0xFF71767B),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: TextField(
                      controller: ctrl,
                      focusNode: widget.textFieldFocus,
                      textInputAction: TextInputAction.send,
                      onSubmitted: (t) => widget.onSend(t),
                      style: const TextStyle(color: Color(0xFFE7E9EA)),
                      decoration: const InputDecoration.collapsed(
                        hintText: 'Message, images, files...',
                        hintStyle: TextStyle(color: Color(0xFF71767B)),
                      ),
                    ),
                  ),
                  if (ctrl.text.isNotEmpty) const SizedBox(width: 6),
                ],
              ),
            ),
          ),
          const SizedBox(width: 8),
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: widget.sending
                  ? Colors.grey.shade800
                  : const Color(0xFF1D9BF0),
              borderRadius: BorderRadius.circular(999),
            ),
            child: IconButton(
              onPressed: widget.sending ? null : () => widget.onSend(ctrl.text),
              icon: const Icon(Icons.send, color: Colors.white),
              splashRadius: 22,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRow(List<ChatAction> actions) {
    return SizedBox(
      height: 40,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 8),
        itemCount: actions.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, i) {
          final a = actions[i];
          final mode = _modes[a]!;
          return GestureDetector(
            onLongPress: () => _cycleMode(a),
            child: _buildChip(context, a, mode),
          );
        },
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
            width: 40,
            height: 40,
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
    }
  }
}
