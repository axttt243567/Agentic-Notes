import 'package:flutter/material.dart';

enum ChatAction { text, camera, gallery, files, audio, call, video, spaces }

enum ChipMode { icon, short, long }

class UniversalChatToolbar extends StatefulWidget {
  const UniversalChatToolbar({
    super.key,
    required this.onAction,
    this.textFieldFocus,
  });

  final void Function(ChatAction action) onAction;
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
      children: [_buildRow(row1), const SizedBox(height: 8), _buildRow(row2)],
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

    switch (mode) {
      case ChipMode.icon:
        return InkWell(
          borderRadius: BorderRadius.circular(999),
          onTap: trigger,
          child: Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: const Color(0xFF0A0A0A),
              borderRadius: BorderRadius.circular(999),
              border: Border.all(color: const Color(0xFF2F3336)),
            ),
            child: Icon(icon, size: 18, color: const Color(0xFF71767B)),
          ),
        );
      case ChipMode.short:
        return InputChip(
          label: Text(labelShort),
          avatar: Icon(icon, size: 16, color: const Color(0xFF71767B)),
          onPressed: trigger,
          backgroundColor: const Color(0xFF0A0A0A),
          shape: const StadiumBorder(),
          side: const BorderSide(color: Color(0xFF2F3336)),
        );
      case ChipMode.long:
        return InputChip(
          label: Text(labelLong),
          avatar: Icon(icon, size: 16, color: const Color(0xFF71767B)),
          onPressed: trigger,
          backgroundColor: const Color(0xFF0A0A0A),
          shape: const StadiumBorder(),
          side: const BorderSide(color: Color(0xFF2F3336)),
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
