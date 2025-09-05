import 'package:flutter/material.dart';

/// Maps common emojis used in the app to Material Icons.
IconData iconForEmoji(String emoji) {
  switch (emoji) {
    // Books / study
    case '📚':
    case '📘':
      return Icons.menu_book_outlined;

    // Notes / writing
    case '📝':
    case '📃':
      return Icons.edit_note_outlined;

    // Computer / programming
    case '💻':
      return Icons.code;

    // Science / chemistry / biology
    case '🧪':
      return Icons.science_outlined;
    case '🧬':
      return Icons.biotech_outlined;

    // Math
    case '🧮':
    case '🔢':
      return Icons.calculate_outlined;

    // Physics / motion
    case '🪐':
      return Icons.auto_awesome_motion;

    // Globe / world / web
    case '🌍':
    case '🌐':
      return Icons.public;

    // Health / medical
    case '🩺':
      return Icons.medical_services_outlined;
    case '🧠':
      return Icons.psychology_alt_outlined;

    // Fitness / activities
    case '🏃‍♂️':
      return Icons.directions_run;
    case '🏋️':
      return Icons.fitness_center;
    case '🧘':
      return Icons.self_improvement;

    // Hobbies
    case '🎵':
      return Icons.music_note;
    case '🎨':
      return Icons.palette_outlined;
    case '🍳':
      return Icons.restaurant_menu;

    default:
      return Icons.folder_outlined;
  }
}

class EmojiIcon extends StatelessWidget {
  const EmojiIcon(this.emoji, {super.key, this.size = 20, this.color});

  final String emoji;
  final double size;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    return Icon(iconForEmoji(emoji), size: size, color: color);
  }
}
