
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class WardrobeService {
  static final _supabase = Supabase.instance.client;
  
  static Future<bool> addItemToCloset({
    required Uint8List imageBytes,
    required String category,
    String? color,
    String? name,
  }) async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) throw Exception('User not logged in');

      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final fileName = '${user.id}/$timestamp.jpg';

      await _supabase.storage
          .from('wardrobe-images')
          .uploadBinary(
            fileName,
            imageBytes,
            fileOptions: const FileOptions(
              contentType: 'image/jpeg',
              upsert: false,
            ),
          );

      final imageUrl =
          _supabase.storage.from('wardrobe-images').getPublicUrl(fileName);

      await _supabase.from('wardrobe_items').insert({
        'image_url': imageUrl,
        'category': category,
        'color': color,
        'name': name,
      });

      return true;
    } catch (e) {
      if (kDebugMode) {
        print('Error adding item to closet: $e');
      }
      return false;
    }
  }

  static Future<void> saveScanToHistory({
    required Uint8List imageBytes,
    required String recommendation,
    required String reasoning,
  }) async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) return;

      final fileName = '${user.id}/${DateTime.now().millisecondsSinceEpoch}.jpg';
      await _supabase.storage.from('scanned-images').uploadBinary(
            fileName,
            imageBytes,
            fileOptions: const FileOptions(
              contentType: 'image/jpeg',
              upsert: false,
            ),
          );
      final imageUrl =
          _supabase.storage.from('scanned-images').getPublicUrl(fileName);

      await _supabase.from('scan_history').insert({
        'scanned_image_url': imageUrl,
        'recommendation': recommendation,
        'ai_response': reasoning,
      });
    } catch (e) {
      if (kDebugMode) print('Error saving scan history: $e');
    }
  }

  static Future<Map<String, List<WardrobeItem>>> getWardrobeItems() async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) return {'tops': [], 'bottoms': [], 'footwear': []};
      final response = await _supabase
          .from('wardrobe_items')
          .select()
          .eq('user_id', userId)
          .order('created_at', ascending: false);

      final Map<String, List<WardrobeItem>> grouped = {
        'tops': [],
        'bottoms': [],
        'footwear': [],
      };

      for (final item in response) {
        final wardrobeItem = WardrobeItem.fromJson(item);
        final category = wardrobeItem.category.toLowerCase();
        if (grouped.containsKey(category)) {
          grouped[category]!.add(wardrobeItem);
        }
      }

      return grouped;
    } catch (e) {
      if (kDebugMode) {
        print('Error fetching wardrobe: $e');
      }
      return {'tops': [], 'bottoms': [], 'footwear': []};
    }
  }

  static Future<String> getWardrobeDescription() async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) return 'Empty wardrobe (no items yet)';
      final items = await _supabase
          .from('wardrobe_items')
          .select('category, name, color, image_url')
          .eq('user_id', userId)
          .order('created_at', ascending: false);

      if (items.isEmpty) return 'Empty wardrobe (no items yet)';

      final tops = <String>[];
      final bottoms = <String>[];
      final footwear = <String>[];

      for (final item in items) {
        final category = (item['category'] as String?)?.toLowerCase() ?? '';
        final description = _buildItemDescription(item);

        switch (category) {
          case 'tops':
            tops.add(description);
            break;
          case 'bottoms':
            bottoms.add(description);
            break;
          case 'footwear':
            footwear.add(description);
            break;
        }
      }

      final parts = <String>[];
      if (tops.isNotEmpty) {
        parts.add('TOPS (${tops.length}): ${tops.join(", ")}');
      }
      if (bottoms.isNotEmpty) {
        parts.add('BOTTOMS (${bottoms.length}): ${bottoms.join(", ")}');
      }
      if (footwear.isNotEmpty) {
        parts.add('FOOTWEAR (${footwear.length}): ${footwear.join(", ")}');
      }

      return parts.join('\n');
    } catch (e) {
      return 'Empty wardrobe (no items yet)';
    }
  }

  static String _buildItemDescription(Map<String, dynamic> item) {
    final name = item['name'] as String?;
    final color = item['color'] as String?;

    if (name != null && color != null) return '$color $name';
    if (name != null) return name;
    if (color != null) return '$color item';
    return 'item';
  }

  static Future<bool> deleteItem({
    required int id,
    required String imageUrl,
  }) async {
    try {
      await _supabase.from('wardrobe_items').delete().eq('id', id);

      final uri = Uri.parse(imageUrl);
      final segments = uri.pathSegments;
      final bucketIndex = segments.indexOf('wardrobe-images');
      if (bucketIndex != -1 && bucketIndex < segments.length - 1) {
        final storagePath = segments.sublist(bucketIndex + 1).join('/');
        await _supabase.storage.from('wardrobe-images').remove([storagePath]);
      }

      return true;
    } catch (e) {
      if (kDebugMode) print('Error deleting item: $e');
      return false;
    }
  }

  static Future<List<Map<String, String>>> getWardrobeImageData({int limit = 10}) async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) return [];
      final items = await _supabase
          .from('wardrobe_items')
          .select('image_url, category')
          .eq('user_id', userId)
          .order('created_at', ascending: false)
          .limit(limit);

      return items.map((item) => {
        'url': item['image_url'] as String,
        'category': item['category'] as String,
      }).toList();
    } catch (e) {
      return [];
    }
  }
}

class WardrobeItem {
  final int id;
  final String imageUrl;
  final String category;
  final String? color;
  final String? name;
  final DateTime createdAt;

  WardrobeItem({
    required this.id,
    required this.imageUrl,
    required this.category,
    this.color,
    this.name,
    required this.createdAt,
  });

  factory WardrobeItem.fromJson(Map<String, dynamic> json) {
    return WardrobeItem(
      id: json['id'] as int,
      imageUrl: json['image_url'] as String,
      category: json['category'] as String,
      color: json['color'] as String?,
      name: json['name'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }
}