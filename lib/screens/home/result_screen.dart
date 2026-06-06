import 'dart:math';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../constants/app_colors.dart';
import '../../services/claude_service.dart';
import '../../services/wardrobe_service.dart';

class ResultScreen extends StatefulWidget {
  final Uint8List imageBytes;
  final AnalysisResult result;

  const ResultScreen({
    super.key,
    required this.imageBytes,
    required this.result,
  });

  @override
  State<ResultScreen> createState() => _ResultScreenState();
}

class _ResultScreenState extends State<ResultScreen> {
  bool _isSaving = false;

  Future<void> _saveToCloset() async {
    setState(() => _isSaving = true);
    final success = await WardrobeService.addItemToCloset(
      imageBytes: widget.imageBytes,
      category: widget.result.category,
    );
    if (!mounted) return;
    setState(() => _isSaving = false);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          success ? 'Added to closet!' : 'Error saving item. Please try again.',
        ),
      ),
    );
    if (success) Navigator.popUntil(context, (route) => route.isFirst);
  }

  @override
  Widget build(BuildContext context) {
    final isNotClothing =
        widget.result.recommendation == BuyRecommendation.notClothing;
    final screenWidth = MediaQuery.of(context).size.width;

    return Scaffold(
      backgroundColor: AppColors.cream,
      body: SafeArea(
        child: Stack(
          children: [
            // Lavender star — top left
            Positioned(
              top: 20,
              left: -10,
              child: _StarShape(size: 72, color: AppColors.starLavender),
            ),
            // Yellow star — top center
            Positioned(
              top: 30,
              left: screenWidth * 0.38,
              child: _StarShape(size: 56, color: AppColors.starYellow),
            ),
            // Pink star — top right
            Positioned(
              top: 10,
              right: 8,
              child: _StarShape(size: 66, color: const Color.fromARGB(255, 153, 207, 255)),
            ),
            // Blue star — mid right
            Positioned(
              top: 260,
              right: -12,
              child: _StarShape(size: 52, color: AppColors.starBlue),
            ),
            // Coral star — bottom left
            Positioned(
              bottom: 80,
              left: -16,
              child: _StarShape(size: 76, color: AppColors.starCoral),
            ),
            // Yellow star — bottom right
            Positioned(
              bottom: 60,
              right: -10,
              child: _StarShape(size: 64, color: AppColors.starYellow),
            ),
            // Pink star — bottom center-left
            Positioned(
              bottom: 20,
              left: 40,
              child: _StarShape(size: 48, color: AppColors.starPink),
            ),
            // Lavender star — bottom right area
            Positioned(
              bottom: 120,
              right: 30,
              child: _StarShape(size: 40, color: AppColors.starLavender),
            ),

            SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 28),
              child: Column(
                children: [
                  const SizedBox(height: 48),

                  Stack(
                    clipBehavior: Clip.none,
                    children: [
                      Container(
                          width: double.infinity,
                          padding: const EdgeInsets.fromLTRB(24, 36, 24, 32),
                          decoration: BoxDecoration(
                            color: AppColors.creamYellow,
                            borderRadius: BorderRadius.circular(24),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.08),
                                blurRadius: 16,
                                offset: const Offset(0, 6),
                              ),
                            ],
                          ),
                          child: Column(
                            children: [
                              Text(
                                isNotClothing ? 'Hmm...' : 'Should you\nbuy it?',
                                textAlign: TextAlign.center,
                                style: GoogleFonts.playfairDisplay(
                                  fontSize: 34,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.textMagenta,
                                  height: 1.15,
                                ),
                              ),
                              const SizedBox(height: 28),

                              Container(
                                width: double.infinity,
                                padding: const EdgeInsets.symmetric(vertical: 20),
                                decoration: BoxDecoration(
                                  color: _getResultBgColor(),
                                  borderRadius: BorderRadius.circular(18),
                                ),
                                child: Center(
                                  child: Text(
                                    _getResultText(),
                                    style: GoogleFonts.playfairDisplay(
                                      fontSize: 64,
                                      fontWeight: FontWeight.bold,
                                      color: _getResultTextColor(),
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 24),

                              _buildActionButton(),
                              const SizedBox(height: 16),

                              Container(
                                width: double.infinity,
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 16, vertical: 14),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFE8E0C9),
                                  borderRadius: BorderRadius.circular(14),
                                ),
                                child: Text(
                                  widget.result.reasoning,
                                  textAlign: TextAlign.center,
                                  style: GoogleFonts.lato(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.textDark,
                                    height: 1.4,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),

                      Positioned(
                        top: -68,
                        right: -38,
                        child: Transform.rotate(
                          angle: -0.1,
                          child: Image.asset(
                            'assets/images/paperclip.png',
                            width: 130,
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 80),

                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _getResultBgColor() {
    switch (widget.result.recommendation) {
      case BuyRecommendation.yes:
        return AppColors.resultYesBg;
      case BuyRecommendation.maybe:
        return AppColors.resultMaybeBg;
      case BuyRecommendation.no:
        return AppColors.resultNoBg;
      case BuyRecommendation.notClothing:
        return const Color(0xFFEEEEEE);
    }
  }

  Color _getResultTextColor() {
    switch (widget.result.recommendation) {
      case BuyRecommendation.yes:
        return AppColors.resultYes;
      case BuyRecommendation.maybe:
        return const Color(0xFFC68A00);
      case BuyRecommendation.no:
        return AppColors.resultNo;
      case BuyRecommendation.notClothing:
        return const Color(0xFF757575);
    }
  }

  String _getResultText() {
    switch (widget.result.recommendation) {
      case BuyRecommendation.yes:
        return 'YES';
      case BuyRecommendation.maybe:
        return 'MAYBE';
      case BuyRecommendation.no:
        return 'NO';
      case BuyRecommendation.notClothing:
        return 'OOPS';
    }
  }

  Widget _buildActionButton() {
    String label;
    VoidCallback onPressed;

    switch (widget.result.recommendation) {
      case BuyRecommendation.yes:
        label = '+ Add to my closet';
        onPressed = _isSaving ? () {} : _saveToCloset;
        break;
      case BuyRecommendation.maybe:
        label = 'Add to closet anyway';
        onPressed = _isSaving ? () {} : _saveToCloset;
        break;
      case BuyRecommendation.no:
        label = 'Skip';
        onPressed = () => Navigator.popUntil(context, (route) => route.isFirst);
        break;
      case BuyRecommendation.notClothing:
        label = 'Try a different photo';
        onPressed = () => Navigator.pop(context);
        break;
    }

    return ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: _getResultTextColor(),
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(30),
        ),
        elevation: 0,
      ),
      child: _isSaving
          ? const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
            )
          : Text(
              label,
              style: GoogleFonts.lato(fontSize: 14, fontWeight: FontWeight.bold),
            ),
    );
  }
}

class _StarShape extends StatelessWidget {
  final double size;
  final Color color;

  const _StarShape({required this.size, required this.color});

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: Size(size, size),
      painter: _StarPainter(color: color),
    );
  }
}

class _StarPainter extends CustomPainter {
  final Color color;

  const _StarPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    final cx = size.width / 2;
    final cy = size.height / 2;
    final outerR = size.width / 2;
    final innerR = size.width / 5;
    const points = 5;

    final path = Path();
    for (int i = 0; i < points * 2; i++) {
      final angle = (i * pi / points) - pi / 2;
      final r = i.isEven ? outerR : innerR;
      final x = cx + r * cos(angle);
      final y = cy + r * sin(angle);
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }
    path.close();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
