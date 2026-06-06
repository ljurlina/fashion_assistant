import 'dart:math';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../constants/app_colors.dart';
import '../../services/wardrobe_service.dart';

class ClosetScreen extends StatefulWidget {
  const ClosetScreen({super.key});

  @override
  State<ClosetScreen> createState() => _ClosetScreenState();
}

class _ClosetScreenState extends State<ClosetScreen> {
  Map<String, List<WardrobeItem>> _items = {
    'tops': [],
    'bottoms': [],
    'footwear': [],
  };
  bool _isLoading = true;

  final Map<String, int> _currentIndex = {
    'tops': 0,
    'bottoms': 0,
    'footwear': 0,
  };

  @override
  void initState() {
    super.initState();
    _loadWardrobe();
  }

  Future<void> _loadWardrobe() async {
    setState(() => _isLoading = true);
    final items = await WardrobeService.getWardrobeItems();
    if (mounted) {
      setState(() {
        _items = items;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        backgroundColor: AppColors.cream,
        body: Center(child: CircularProgressIndicator(color: AppColors.magenta)),
      );
    }

    final screenWidth = MediaQuery.of(context).size.width;

    return Scaffold(
      backgroundColor: AppColors.cream,
      body: SafeArea(
        child: Stack(
          children: [
            // Top-center mauve star
            Positioned(
              top: 10,
              left: screenWidth * 0.44,
              child: const _StarShape(size: 64, color: Color(0xFFD4A5CE)),
            ),
            // Top-right cream-yellow star
            Positioned(
              top: 72,
              right: 24,
              child: const _StarShape(size: 44, color: Color(0xFFF0E4A0)),
            ),
            // Bottom-left light pink star
            Positioned(
              bottom: 40,
              left: -12,
              child: const _StarShape(size: 84, color: Color(0xFFF5C4CC)),
            ),
            RefreshIndicator(
              onRefresh: _loadWardrobe,
              color: AppColors.magenta,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 80),
                    const SizedBox(height: 24),

                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppColors.creamYellow,
                        borderRadius: BorderRadius.circular(24),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.08),
                            blurRadius: 20,
                            spreadRadius: 1,
                            offset: const Offset(0, 6),
                          ),
                        ],
                      ),
                      child: Column(
                        children: [
                          _buildCategorySection(
                            category: 'tops',
                            title: 'TOPS',
                            items: _items['tops']!,
                          ),
                          const SizedBox(height: 12),
                          _buildDivider(),
                          const SizedBox(height: 12),
                          _buildCategorySection(
                            category: 'bottoms',
                            title: 'BOTTOMS',
                            items: _items['bottoms']!,
                          ),
                          const SizedBox(height: 12),
                          _buildDivider(),
                          const SizedBox(height: 12),
                          _buildCategorySection(
                            category: 'footwear',
                            title: 'FOOTWEAR',
                            items: _items['footwear']!,
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDivider() {
    return Container(
      height: 1,
      decoration: BoxDecoration(
        color: AppColors.cream.withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(1),
      ),
    );
  }

  Widget _buildCategorySection({
    required String category,
    required String title,
    required List<WardrobeItem> items,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4),
          child: Text(
            title,
            style: GoogleFonts.lato(
              fontSize: 11,
              fontWeight: FontWeight.w800,
              color: AppColors.textMuted,
              letterSpacing: 2.0,
            ),
          ),
        ),
        const SizedBox(height: 8),
        Container(
          height: 140,
          decoration: BoxDecoration(
            color: const Color(0xFFE2DAC0),
            borderRadius: BorderRadius.circular(16),
          ),
          child: items.isEmpty
              ? _buildEmptyState()
              : _buildCarousel(category, items),
        ),
        if (items.length > 1) ...[
          const SizedBox(height: 8),
          _buildDotIndicator(category, items.length),
        ],
      ],
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.add_a_photo_outlined, color: AppColors.magentaLight, size: 28),
          const SizedBox(height: 6),
          Text(
            'Scan to add',
            style: GoogleFonts.lato(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: AppColors.textMuted,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCarousel(String category, List<WardrobeItem> items) {
    final currentIdx = _currentIndex[category]!;
    final currentItem = items[currentIdx];

    return Row(
      children: [
        IconButton(
          onPressed: currentIdx > 0
              ? () => setState(() => _currentIndex[category] = currentIdx - 1)
              : null,
          icon: Icon(
            Icons.chevron_left,
            color: currentIdx > 0 ? AppColors.magenta : AppColors.magentaLight,
            size: 28,
          ),
        ),
        Expanded(
          child: GestureDetector(
            onLongPress: () => _confirmDelete(currentItem, category),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: Image.network(
                currentItem.imageUrl,
                fit: BoxFit.contain,
                height: 120,
                errorBuilder: (_, _, _) => Center(
                  child: Icon(Icons.broken_image, color: AppColors.textMuted),
                ),
                loadingBuilder: (_, child, progress) {
                  if (progress == null) return child;
                  return const Center(
                    child: CircularProgressIndicator(color: AppColors.magenta),
                  );
                },
              ),
            ),
          ),
        ),
        IconButton(
          onPressed: currentIdx < items.length - 1
              ? () => setState(() => _currentIndex[category] = currentIdx + 1)
              : null,
          icon: Icon(
            Icons.chevron_right,
            color: currentIdx < items.length - 1
                ? AppColors.magenta
                : AppColors.magentaLight,
            size: 28,
          ),
        ),
      ],
    );
  }

  Future<void> _confirmDelete(WardrobeItem item, String category) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppColors.creamYellow,
        title: Text('Remove item?', style: GoogleFonts.playfairDisplay(fontWeight: FontWeight.bold)),
        content: Text('This will permanently delete the item from your closet.', style: GoogleFonts.lato()),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('Cancel', style: GoogleFonts.lato(color: AppColors.textMuted)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text('Delete', style: GoogleFonts.lato(color: AppColors.magenta, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    final success = await WardrobeService.deleteItem(id: item.id, imageUrl: item.imageUrl);
    if (!mounted) return;

    if (success) {
      setState(() {
        _items[category]!.remove(item);
        final maxIdx = (_items[category]!.length - 1).clamp(0, double.maxFinite.toInt());
        if (_currentIndex[category]! > maxIdx) _currentIndex[category] = maxIdx;
      });
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to delete item. Please try again.')),
      );
    }
  }

  Widget _buildDotIndicator(String category, int totalItems) {
    final currentIdx = _currentIndex[category]!;
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(totalItems, (index) {
        final isActive = index == currentIdx;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          margin: const EdgeInsets.symmetric(horizontal: 3),
          width: isActive ? 12 : 6,
          height: 6,
          decoration: BoxDecoration(
            color: isActive ? AppColors.magenta : AppColors.magentaLight,
            borderRadius: BorderRadius.circular(3),
          ),
        );
      }),
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
