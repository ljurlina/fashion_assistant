import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../constants/app_colors.dart';
import 'camera_screen.dart';

class ScanIntentScreen extends StatelessWidget {
  const ScanIntentScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          children: [
            const SizedBox(height: 40),

            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: const Color(0xFFFCE5EC),
                borderRadius: BorderRadius.circular(24),
              ),
              child: Column(
                children: [
                  Text(
                    'What are we doing?',
                    style: GoogleFonts.playfairDisplay(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textMagenta,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 32),

                  _buildIntentCard(
                    context: context,
                    imagePath: 'assets/images/shopping_basket.png',
                    label: 'Thinking of buying',
                    onTap: () {
                      _navigateToScan(context, isNewItem: true);
                    },
                  ),
                  const SizedBox(height: 24),

                  _buildIntentCard(
                    context: context,
                    imagePath: 'assets/images/hanger.png',
                    label: 'I already own this',
                    onTap: () {
                      _navigateToScan(context, isNewItem: false);
                    },
                  ),
                ],
              ),
            ),

            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildIntentCard({
    required BuildContext context,
    required String imagePath,
    required String label,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        height: 180,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: AppColors.creamYellow,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset(
              imagePath,
              height: 80,
              fit: BoxFit.contain,
            ),
            const SizedBox(height: 12),
            Text(
              label,
              style: GoogleFonts.playfairDisplay(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppColors.textMagenta,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _navigateToScan(BuildContext context, {required bool isNewItem}) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => CameraScreen(isNewItem: isNewItem),
      ),
    );
  }
}