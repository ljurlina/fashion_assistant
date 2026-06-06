import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../constants/app_colors.dart';
import '../../constants/app_text_styles.dart';
import '../main_layout.dart';

class ColorPaletteScreen extends StatefulWidget {
  final bool isEditing;
  const ColorPaletteScreen({super.key, this.isEditing = false});

  @override
  State<ColorPaletteScreen> createState() => _ColorPaletteScreenState();
}

class _ColorPaletteScreenState extends State<ColorPaletteScreen> {
  final List<ColorPaletteOption> _palettes = [
    ColorPaletteOption(
      name: 'Neutrals',
      colors: [
        const Color(0xFFF5E6D3), // krem
        const Color(0xFF8B7355), // taupe
        const Color(0xFFD4C5A0), // sage
      ],
      textColor: const Color(0xFF8B7355),
    ),
    ColorPaletteOption(
      name: 'Black & White',
      colors: [
        Colors.white,
        const Color(0xFF888888), // sivi
        Colors.black,
      ],
      textColor: const Color(0xFF555555),
    ),
    ColorPaletteOption(
      name: 'Pastels',
      colors: [
        const Color(0xFFF9D5E5), // baby pink
        const Color(0xFFBFD7ED), // baby blue
        const Color(0xFFD7BFE8), // lavender
      ],
      textColor: const Color(0xFFD08FB8),
    ),
    ColorPaletteOption(
      name: 'Bold & Bright',
      colors: [
        const Color(0xFFFFD93D), // yellow
        const Color(0xFFB8327F), // magenta
        const Color(0xFFE85D5D), // red
      ],
      textColor: const Color(0xFFB8327F),
    ),
    ColorPaletteOption(
      name: 'Earthy Tones',
      colors: [
        const Color(0xFFC9A28A), // dusty rose
        const Color(0xFF8B6F47), // brown
        const Color(0xFF8B9D5F), // olive
      ],
      textColor: const Color(0xFF8B6F47),
    ),
    ColorPaletteOption(
      name: 'Jewel Tones',
      colors: [
        const Color(0xFF6B2D5C), // plum
        const Color(0xFF2D6B7E), // teal
        const Color(0xFFD4A04E), // mustard
      ],
      textColor: const Color(0xFF2D6B7E),
    ),
  ];

  final Set<String> _selectedPalettes = {};
  bool _isLoadingPreferences = false;

  static const int _minSelections = 1;
  static const int _maxSelections = 3;

  bool get _canContinue =>
      _selectedPalettes.length >= _minSelections &&
      _selectedPalettes.length <= _maxSelections;

  @override
  void initState() {
    super.initState();
    if (widget.isEditing) _loadExistingPreferences();
  }

  Future<void> _loadExistingPreferences() async {
    setState(() => _isLoadingPreferences = true);
    try {
      final userId = Supabase.instance.client.auth.currentUser?.id;
      if (userId == null) return;
      final profile = await Supabase.instance.client
          .from('profiles')
          .select('color_preferences')
          .eq('id', userId)
          .single();
      final existing = List<String>.from(profile['color_preferences'] ?? []);
      setState(() => _selectedPalettes.addAll(existing));
    } catch (_) {
    } finally {
      if (mounted) setState(() => _isLoadingPreferences = false);
    }
  }

  void _togglePalette(String paletteName) {
    setState(() {
      if (_selectedPalettes.contains(paletteName)) {
        _selectedPalettes.remove(paletteName);
      } else {
        if (_selectedPalettes.length >= _maxSelections) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content:
                  Text('You can only pick up to $_maxSelections palettes'),
              duration: const Duration(seconds: 2),
            ),
          );
          return;
        }
        _selectedPalettes.add(paletteName);
      }
    });
  }

  Future<void> _saveAndContinue() async {
    try {
      final userId = Supabase.instance.client.auth.currentUser?.id;
      if (userId == null) return;

      await Supabase.instance.client.from('profiles').update({
        'color_preferences': _selectedPalettes.toList(),
      }).eq('id', userId);

      if (mounted) {
        if (widget.isEditing) {
          Navigator.pop(context);
        } else {
          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(builder: (_) => const MainLayout()),
            (route) => false,
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoadingPreferences) {
      return const Scaffold(
        backgroundColor: AppColors.cream,
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.cream,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (widget.isEditing) ...[
                const SizedBox(height: 16),
                GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: const Icon(Icons.arrow_back, size: 28),
                ),
                const SizedBox(height: 16),
              ] else
                const SizedBox(height: 40),

              Text('What is your', style: AppTextStyles.heading1),
              Text('COLOR preference?', style: AppTextStyles.heading1),
              const SizedBox(height: 8),
              Text(
                'Pick up to 3 palettes',
                style: AppTextStyles.subtitle.copyWith(
                  color: AppColors.magentaLight,
                ),
              ),
              const SizedBox(height: 32),

              Column(
                children: _palettes.map((palette) {
                  final isSelected = _selectedPalettes.contains(palette.name);
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: _buildPaletteChip(palette, isSelected),
                  );
                }).toList(),
              ),

              const SizedBox(height: 24),

              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _canContinue ? _saveAndContinue : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.magenta,
                    foregroundColor: Colors.white,
                    disabledBackgroundColor: AppColors.magentaPale,
                    disabledForegroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                    elevation: 0,
                  ),
                  child: Text('Continue', style: AppTextStyles.button),
                ),
              ),

              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPaletteChip(ColorPaletteOption palette, bool isSelected) {
    return GestureDetector(
      onTap: () => _togglePalette(palette.name),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        decoration: BoxDecoration(
          color: AppColors.creamYellow,
          borderRadius: BorderRadius.circular(30),
          border: isSelected
              ? Border.all(color: AppColors.magenta, width: 3)
              : Border.all(color: Colors.transparent, width: 3),
        ),
        child: Row(
          children: [
            ...palette.colors.map((color) => Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: color,
                      shape: BoxShape.circle,
                    ),
                  ),
                )),
            const Spacer(),

            Text(
              palette.name,
              style: AppTextStyles.bodyBold.copyWith(
                color: palette.textColor,
                fontSize: 16,
              ),
            ),
            const SizedBox(width: 8),
          ],
        ),
      ),
    );
  }
}

class ColorPaletteOption {
  final String name;
  final List<Color> colors;
  final Color textColor;

  ColorPaletteOption({
    required this.name,
    required this.colors,
    required this.textColor,
  });
}