import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../constants/app_colors.dart';
import '../../constants/app_text_styles.dart';
import 'color_palette_screen.dart';

class StylePreferenceScreen extends StatefulWidget {
  final bool isEditing;
  const StylePreferenceScreen({super.key, this.isEditing = false});

  @override
  State<StylePreferenceScreen> createState() => _StylePreferenceScreenState();
}

class _StylePreferenceScreenState extends State<StylePreferenceScreen> {
  final List<String> _styles = [
    'Minimalist',
    'Classic',
    'Streetwear',
    'Romantic',
    'Vintage/Retro',
    'Edgy/Alternative',
    'Sporty/Athleisure',
    'Boho/Earthy',
    'Y2K/Trendy',
    'Editorial',
  ];

  final Set<String> _selectedStyles = {};
  bool _isLoadingPreferences = false;

  static const int _minSelections = 2;
  static const int _maxSelections = 4;

  bool get _canContinue =>
      _selectedStyles.length >= _minSelections &&
      _selectedStyles.length <= _maxSelections;

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
          .select('style_preferences')
          .eq('id', userId)
          .single();
      final existing = List<String>.from(profile['style_preferences'] ?? []);
      setState(() => _selectedStyles.addAll(existing));
    } catch (_) {
    } finally {
      if (mounted) setState(() => _isLoadingPreferences = false);
    }
  }

  void _toggleStyle(String style) {
    setState(() {
      if (_selectedStyles.contains(style)) {
        _selectedStyles.remove(style);
      } else {
        if (_selectedStyles.length >= _maxSelections) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('You can only pick up to $_maxSelections styles'),
              duration: const Duration(seconds: 2),
            ),
          );
          return;
        }
        _selectedStyles.add(style);
      }
    });
  }

  Future<void> _saveAndContinue() async {
    try {
      final userId = Supabase.instance.client.auth.currentUser?.id;
      if (userId == null) return;

      await Supabase.instance.client.from('profiles').update({
        'style_preferences': _selectedStyles.toList(),
      }).eq('id', userId);

      if (mounted) {
        if (widget.isEditing) {
          Navigator.pop(context);
        } else {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (_) => const ColorPaletteScreen()),
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

              Text(
                'What is your',
                style: AppTextStyles.heading1,
              ),
              Text(
                'STYLE preference?',
                style: AppTextStyles.heading1,
              ),
              const SizedBox(height: 8),
              Text(
                'Pick 2-4 styles that fit you best',
                style: AppTextStyles.subtitle.copyWith(
                  color: AppColors.magentaLight,
                ),
              ),
              const SizedBox(height: 32),

              Wrap(
                spacing: 12,
                runSpacing: 12,
                alignment: WrapAlignment.center,
                children: _styles.map((style) {
                  final isSelected = _selectedStyles.contains(style);
                  return _buildStyleChip(style, isSelected);
                }).toList(),
              ),

              const SizedBox(height: 40),

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

  Widget _buildStyleChip(String style, bool isSelected) {
    return GestureDetector(
      onTap: () => _toggleStyle(style),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.magenta : AppColors.creamYellow,
          borderRadius: BorderRadius.circular(30),
        ),
        child: Text(
          style,
          style: isSelected
              ? AppTextStyles.chipSelected
              : AppTextStyles.chipDefault,
        ),
      ),
    );
  }
}