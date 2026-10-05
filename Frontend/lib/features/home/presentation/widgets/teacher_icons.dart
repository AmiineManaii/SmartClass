import 'package:flutter/material.dart';

IconData teacherIconFromName(String name) {
  switch (name) {
    case 'school':
      return Icons.school_outlined;
    case 'auto_stories':
      return Icons.auto_stories_outlined;
    case 'assignment_turned_in':
      return Icons.assignment_turned_in_outlined;
    case 'laptop_chromebook':
      return Icons.laptop_chromebook_outlined;
    case 'account_tree':
      return Icons.account_tree_outlined;
    case 'laptop_mac':
      return Icons.laptop_mac_outlined;
    case 'format_list_numbered':
      return Icons.format_list_numbered_outlined;
    case 'quiz':
      return Icons.quiz_outlined;
    case 'code_blocks':
      return Icons.code_outlined;
    case 'cases':
      return Icons.cases_outlined;
    default:
      return Icons.circle_outlined;
  }
}
