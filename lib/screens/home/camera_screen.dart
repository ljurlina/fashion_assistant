import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import '../../constants/app_colors.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../services/claude_service.dart';
import '../../services/wardrobe_service.dart';
import 'result_screen.dart';
import 'package:http/http.dart' as http;


class CameraScreen extends StatefulWidget {
  final bool isNewItem;

  const CameraScreen({super.key, required this.isNewItem});

  @override
  State<CameraScreen> createState() => _CameraScreenState();
}

class _CameraScreenState extends State<CameraScreen> {
  Uint8List? _imageBytes;
  bool _isProcessing = false;

  Future<void> _pickImage(ImageSource source) async {
    try {
      final ImagePicker picker = ImagePicker();
      final XFile? image = await picker.pickImage(
        source: source,
        imageQuality: 80,
      );

      if (image != null) {
        final bytes = await image.readAsBytes();
        setState(() {
          _imageBytes = bytes;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not open photo. Please try again.')),
        );
      }
    }
  }

  Future<void> _processImage() async {
    if (_imageBytes == null) return;

    setState(() => _isProcessing = true);

    try {
      if (widget.isNewItem) {
        await _analyzeWithAI();
      } else {
        await _analyzeAndSaveToCloset();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(_friendlyError(e))),
        );
      }
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  Future<void> _analyzeWithAI() async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) throw Exception('Not logged in');

    final profile = await Supabase.instance.client
        .from('profiles')
        .select('style_preferences, color_preferences')
        .eq('id', user.id)
        .single();

    final stylePrefs =
        (profile['style_preferences'] as List?)?.cast<String>() ?? [];
    final colorPrefs =
        (profile['color_preferences'] as List?)?.cast<String>() ?? [];

    final wardrobeDescription = await WardrobeService.getWardrobeDescription();

    final wardrobeImageData = await WardrobeService.getWardrobeImageData(limit: 5);

    final wardrobeImages = <Uint8List>[];
    final wardrobeImageCategories = <String>[];
    for (final data in wardrobeImageData) {
      try {
        final response = await http.get(Uri.parse(data['url']!));
        if (response.statusCode == 200) {
          wardrobeImages.add(response.bodyBytes);
          wardrobeImageCategories.add(data['category']!);
        }
      } catch (e) {
        // skip
      }
    }

    final result = await ClaudeService.analyzeItem(
      imageBytes: _imageBytes!,
      stylePreferences: stylePrefs,
      colorPreferences: colorPrefs,
      wardrobeDescription: wardrobeDescription,
      wardrobeImages: wardrobeImages,
      wardrobeImageCategories: wardrobeImageCategories,
    );

    await WardrobeService.saveScanToHistory(
      imageBytes: _imageBytes!,
      recommendation: result.recommendation.name,
      reasoning: result.reasoning,
    );

    if (mounted) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => ResultScreen(
            imageBytes: _imageBytes!,
            result: result,
          ),
        ),
      );
    }
  }

  Future<void> _analyzeAndSaveToCloset() async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) throw Exception('Not logged in');

    final profile = await Supabase.instance.client
        .from('profiles')
        .select('style_preferences, color_preferences')
        .eq('id', user.id)
        .maybeSingle();

    final stylePrefs =
        (profile?['style_preferences'] as List?)?.cast<String>() ?? [];
    final colorPrefs =
        (profile?['color_preferences'] as List?)?.cast<String>() ?? [];

    final result = await ClaudeService.analyzeItem(
      imageBytes: _imageBytes!,
      stylePreferences: stylePrefs,
      colorPreferences: colorPrefs,
    );

    if (result.recommendation == BuyRecommendation.notClothing) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              "That doesn't look like a clothing item. Try a different photo.",
            ),
          ),
        );
      }
      return;
    }

    final success = await WardrobeService.addItemToCloset(
      imageBytes: _imageBytes!,
      category: result.category,
      color: result.color,
    );

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            success ? 'Added to closet!' : 'Error saving item. Please try again.',
          ),
        ),
      );
      if (success) Navigator.pop(context);
    }
  }

  String _friendlyError(Object e) {
    final msg = e.toString();
    if (msg.contains('Not logged in')) return 'Please log in again.';
    if (msg.contains('API key')) return 'Setup error. Contact support.';
    if (msg.contains('SocketException') || msg.contains('network')) {
      return 'No internet connection.';
    }
    return 'Something went wrong. Please try again.';
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.cream,
      appBar: AppBar(
        backgroundColor: AppColors.cream,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.magenta),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          widget.isNewItem ? 'Scan to evaluate' : 'Add to closet',
          style: GoogleFonts.playfairDisplay(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: AppColors.textMagenta,
          ),
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              const SizedBox(height: 20),

              Expanded(
                child: Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: AppColors.creamYellow,
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(
                      color: AppColors.magentaLight,
                      width: 2,
                      style: BorderStyle.solid,
                    ),
                  ),
                  child: _imageBytes != null
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(22),
                          child: Image.memory(
                            _imageBytes!,
                            fit: BoxFit.cover,
                          ),
                        )
                      : Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.image_outlined,
                                size: 80,
                                color: AppColors.magentaLight,
                              ),
                              const SizedBox(height: 16),
                              Text(
                                'No image yet',
                                style: GoogleFonts.playfairDisplay(
                                  fontSize: 18,
                                  color: AppColors.textMuted,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Pick a photo to analyze',
                                style: GoogleFonts.lato(
                                  fontSize: 14,
                                  color: AppColors.textMuted,
                                ),
                              ),
                            ],
                          ),
                        ),
                ),
              ),

              const SizedBox(height: 24),

              if (_imageBytes == null)
                Row(
                  children: [
                    Expanded(
                      child: _buildPickButton(
                        icon: Icons.camera_alt,
                        label: 'Camera',
                        onTap: () => _pickImage(ImageSource.camera),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildPickButton(
                        icon: Icons.photo_library,
                        label: 'Gallery',
                        onTap: () => _pickImage(ImageSource.gallery),
                      ),
                    ),
                  ],
                ),

              if (_imageBytes != null) ...[
                Row(
                  children: [
                    Expanded(
                      child: _buildPickButton(
                        icon: Icons.refresh,
                        label: 'Retake',
                        onTap: () => setState(() => _imageBytes = null),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      flex: 2,
                      child: ElevatedButton(
                        onPressed: _isProcessing ? null : _processImage,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.magenta,
                          foregroundColor: Colors.white,
                          padding:
                              const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(30),
                          ),
                          elevation: 0,
                        ),
                        child: _isProcessing
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 2,
                                ),
                              )
                            : Text(
                                widget.isNewItem ? 'Analyze' : 'Add to closet',
                                style: GoogleFonts.lato(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                      ),
                    ),
                  ],
                ),
              ],

              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPickButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: AppColors.creamYellow,
          borderRadius: BorderRadius.circular(30),
          border: Border.all(color: AppColors.magenta, width: 2),
        ),
        child: Column(
          children: [
            Icon(icon, color: AppColors.magenta, size: 28),
            const SizedBox(height: 4),
            Text(
              label,
              style: GoogleFonts.lato(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: AppColors.textMagenta,
              ),
            ),
          ],
        ),
      ),
    );
  }
}