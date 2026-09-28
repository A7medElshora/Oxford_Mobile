import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Editorial Learning Atelier palette
class C {
  static const primary = Color(0xFFF36A21), primaryHover = Color(0xFFD95614);
  static const bgL = Color(0xFFFBFAF7), bgD = Color(0xFF151719);
  static const cardL = Color(0xFFFFFEFA), cardD = Color(0xFF202427);
  static const fgL = Color(0xFF181615), fgD = Color(0xFFF7EFE7);
  static const borderL = Color(0xFFEBE3DB), borderD = Color(0xFF384047);
  static const muted = Color(0xFF7B6E65), mint = Color(0xFF10B981);
  static const amber = Color(0xFFE79A23), coral = Color(0xFFDF5B3D), paper = Color(0xFFFFFAF4);
}

const kCurve = Cubic(0.23, 1.0, 0.32, 1.0);
const kRadius = 17.0;

/// DM Sans for numbers, dates, percentages
TextStyle numStyle({double size = 16, FontWeight w = FontWeight.w700, Color? color}) =>
    GoogleFonts.dmSans(fontSize: size, fontWeight: w, color: color);

ThemeData buildTheme(bool dark) {
  final fg = dark ? C.fgD : C.fgL, bg = dark ? C.bgD : C.bgL;
  final card = dark ? C.cardD : C.cardL, border = dark ? C.borderD : C.borderL;
  final base = ThemeData(brightness: dark ? Brightness.dark : Brightness.light);
  return base.copyWith(
    scaffoldBackgroundColor: bg,
    cardColor: card,
    dividerColor: border,
    colorScheme: ColorScheme.fromSeed(seedColor: C.primary, brightness: base.brightness).copyWith(
        primary: C.primary, surface: card, onSurface: fg, error: C.coral),
    textTheme: GoogleFonts.changaTextTheme(base.textTheme).apply(bodyColor: fg, displayColor: fg),
    appBarTheme: AppBarTheme(
        backgroundColor: bg, foregroundColor: fg, elevation: 0, centerTitle: true,
        titleTextStyle: GoogleFonts.changa(fontSize: 19, fontWeight: FontWeight.w700, color: fg)),
    elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
            backgroundColor: C.primary, foregroundColor: Colors.white,
            minimumSize: const Size.fromHeight(50),
            textStyle: GoogleFonts.changa(fontSize: 16, fontWeight: FontWeight.w700),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)))),
    inputDecorationTheme: InputDecorationTheme(
        filled: true, fillColor: card,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: border)),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: border)),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: C.primary, width: 1.6))),
    navigationBarTheme: NavigationBarThemeData(
        backgroundColor: card, indicatorColor: C.primary.withOpacity(.14),
        labelTextStyle: WidgetStatePropertyAll(GoogleFonts.changa(fontSize: 12, fontWeight: FontWeight.w600))),
  );
}
