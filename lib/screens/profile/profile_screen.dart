import 'dart:math';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../constants/app_colors.dart';
import '../auth/login_screen.dart';
import '../onboarding/style_preference_screen.dart';
import '../onboarding/color_palette_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  String _username = '';
  String _email = '';
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user == null) return;

      final profile = await Supabase.instance.client
      .from('profiles')
      .select('username')
      .eq('id', user.id)
      .single();
      
      setState(() {
        _username = profile['username'] ?? '';
        _email = user.email ?? '';
        _isLoading = false;
      });

    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _logout() async {
    try {
      await Supabase.instance.client.auth.signOut();
      if (mounted) {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (_) => const LoginScreen()),
          (route) => false,
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Logout error: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        backgroundColor: AppColors.cream,
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final initial = _username.isNotEmpty ? _username[0].toUpperCase() : '?';

    return Scaffold(
      backgroundColor: AppColors.cream,
      body: SafeArea(
        child: Stack(
          children: [
            // Top-right pink star
            const Positioned(
              top: 16,
              right: 28,
              child: _StarShape(size: 58, color: Color(0xFFE8A0C8)),
            ),
            // Bottom-left light pink star
            const Positioned(
              bottom: 50,
              left: -14,
              child: _StarShape(size: 80, color: Color(0xFFF8D0D8)),
            ),
            // Bottom-right cream-yellow star
            const Positioned(
              bottom: 90,
              right: 20,
              child: _StarShape(size: 42, color: Color(0xFFF0E89A)),
            ),
            // Top-left lavender star
            Positioned(
              top: 28,
              left: 14,
              child: _StarShape(size: 36, color: AppColors.starLavender),
            ),
            // Mid-right coral star
            Positioned(
              top: 190,
              right: -6,
              child: _StarShape(size: 34, color: AppColors.starCoral),
            ),
            SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
            children: [
              const SizedBox(height: 60),

              
              Stack(
                clipBehavior: Clip.none,
                alignment: Alignment.topLeft,
                children: [
                  
                  Container(
                    margin: const EdgeInsets.only(top: 80),
                    padding: const EdgeInsets.fromLTRB(20, 100, 20, 20),
                    decoration: BoxDecoration(
                      color: AppColors.creamYellow,
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.10),
                          blurRadius: 24,
                          spreadRadius: 2,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        
                        _buildInfoPill(_username),
                        const SizedBox(height: 12),

                        
                        _buildInfoPill(_email),
                        const SizedBox(height: 12),

                        
                        _buildEditablePill(
                          'Style preference',
                          onTap: () async {
                            await Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const StylePreferenceScreen(isEditing: true),
                              ),
                            );
                          },
                        ),
                        const SizedBox(height: 12),

                        _buildEditablePill(
                          'Color palette',
                          onTap: () async {
                            await Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const ColorPaletteScreen(isEditing: true),
                              ),
                            );
                          },
                        ),
                        const SizedBox(height: 20),

                        Align(
                          alignment: Alignment.centerRight,
                          child: ElevatedButton(
                            onPressed: _logout,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.magenta,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 28, vertical: 10),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(30),
                              ),
                              elevation: 0,
                              shadowColor: Colors.transparent,
                            ).copyWith(
                              shadowColor: WidgetStateProperty.all(Colors.transparent),
                            ),
                            child: Text(
                              'Log out',
                              style: GoogleFonts.lato(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  Positioned(
                    left: 10,
                    top: 0,
                    child: _buildPolaroid(initial),
                  ),
                ],
              ),

              const SizedBox(height: 24),
            ],
          ),
        ),
          ],
        ),
      ),
    );
  }

  Widget _buildPolaroid(String initial) {
    return Transform.rotate(
      angle: -0.05,
      child: SizedBox(
        width: 160,
        height: 200,
        child: Stack(
          clipBehavior: Clip.none,
          alignment: Alignment.center,
          children: [
            // bijeli polaroid okvir
            Container(
              width: 160,
              height: 200,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(4),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.15),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                children: [
                  // roze box s inicijalom
                  Expanded(
                    child: Container(
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: const Color(0xFFF9D5E5),
                        borderRadius: BorderRadius.circular(2),
                      ),
                      child: Center(
                        child: Text(
                          initial,
                          style: GoogleFonts.playfairDisplay(
                            fontSize: 90,
                            fontWeight: FontWeight.bold,
                            color: const Color(0xFFE89C8A),
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
            //selotejp gore
            Positioned(
              top: -8,
              child: Transform.rotate(
                angle: 0.05,
                child: Container(
                  width: 60,
                  height: 20,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.7),
                    borderRadius: BorderRadius.circular(2),
                    border: Border.all(
                      color: Colors.grey.withValues(alpha: 0.3),
                      width: 0.5,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
  Widget _buildInfoPill(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFD4C9A8),
        borderRadius: BorderRadius.circular(30),
      ),
      child: Center(
        child: Text(
          text,
          style: GoogleFonts.playfairDisplay(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
      ),
    );
  }

  Widget _buildEditablePill(String text, {required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        decoration: BoxDecoration(
          color: const Color(0xFFF9D5E5),
          borderRadius: BorderRadius.circular(30),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.10),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Center(
          child: Text(
            text,
            style: GoogleFonts.playfairDisplay(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: const Color(0xFFE89C8A),
            ),
          ),
        ),
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