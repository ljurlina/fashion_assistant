import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'app_colors.dart';

class AppTextStyles {
  static TextStyle heading1 = GoogleFonts.playfairDisplay(
    fontSize: 36,
    fontWeight: FontWeight.bold,
    color: AppColors.textMagenta,
  );

  static TextStyle heading2 = GoogleFonts.playfairDisplay(
    fontSize: 28,
    fontWeight: FontWeight.bold,
    color: AppColors.textMagenta,
  );

  static TextStyle heading3 = GoogleFonts.playfairDisplay(
    fontSize: 22,
    fontWeight: FontWeight.w600,
    color: AppColors.textDark,
  );

  static TextStyle resultHuge = GoogleFonts.playfairDisplay(
    fontSize: 56,
    fontWeight: FontWeight.bold,
  );

  static TextStyle body = GoogleFonts.lato(
    fontSize: 16,
    fontWeight: FontWeight.normal,
    color: AppColors.textDark,
  );

  static TextStyle bodyBold = GoogleFonts.lato(
    fontSize: 16,
    fontWeight: FontWeight.bold,
    color: AppColors.textDark,
  );

  static TextStyle subtitle = GoogleFonts.lato(
    fontSize: 14,
    fontWeight: FontWeight.normal,
    color: AppColors.textMuted,
  );

  static TextStyle button = GoogleFonts.lato(
    fontSize: 16,
    fontWeight: FontWeight.bold,
    color: Colors.white,
  );

  static TextStyle inputLabel = GoogleFonts.lato(
    fontSize: 14,
    fontWeight: FontWeight.w500,
    color: AppColors.textMuted,
  );

  static TextStyle chipDefault = GoogleFonts.lato(
    fontSize: 15,
    fontWeight: FontWeight.w600,
    color: AppColors.textMagenta,
  );

  static TextStyle chipSelected = GoogleFonts.lato(
    fontSize: 15,
    fontWeight: FontWeight.w600,
    color: Colors.white,
  );

  static TextStyle link = GoogleFonts.lato(
    fontSize: 14,
    fontWeight: FontWeight.bold,
    color: AppColors.magenta,
    decoration: TextDecoration.underline,
  );
}