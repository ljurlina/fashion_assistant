import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;

enum BuyRecommendation { yes, maybe, no, notClothing }

class AnalysisResult {
  final BuyRecommendation recommendation;
  final String reasoning;
  final String category;

  AnalysisResult({
    required this.recommendation,
    required this.reasoning,
    required this.category,
  });
}


class ClaudeService {
  static const String _apiUrl = 'https://api.anthropic.com/v1/messages';
  static const String _model = 'claude-haiku-4-5-20251001';
  static const String _apiVersion = '2023-06-01';

  /// [imageBytes] 
  /// [stylePreferences] 
  /// [colorPreferences]
  /// [wardrobeDescription]
  static Future<AnalysisResult> analyzeItem({
    required Uint8List imageBytes,
    required List<String> stylePreferences,
    required List<String> colorPreferences,
    String wardrobeDescription = 'No items yet',
    List<Uint8List> wardrobeImages = const [],
    List<String> wardrobeImageCategories = const [],
    }) async {
    try {
      final apiKey = dotenv.env['CLAUDE_API_KEY'];
      if (apiKey == null || apiKey.isEmpty) {
        throw Exception('CLAUDE_API_KEY not found in .env');
      }
      
      final mediaType = _detectMediaType(imageBytes);

      final base64Image = base64Encode(imageBytes);

      final systemPrompt = '''
You are a thoughtful fashion stylist helping users decide if they should buy a new clothing item. Your goal is to encourage mindful, sustainable consumption and prevent duplicate purchases.

USER PROFILE:
- Style preferences: ${stylePreferences.join(", ")}
- Color preferences: ${colorPreferences.join(", ")}
- Current wardrobe: $wardrobeDescription

IMPORTANT: First check if the first image actually shows a clothing item. If it does NOT (e.g. food, a face, an animal, a landscape, furniture, a screenshot, text, etc.), return:
{
  "recommendation": "NOT_CLOTHING",
  "category": "other",
  "reasoning": "This doesn't appear to be a clothing item. Please take a photo of a shirt, pants, shoes, or similar garment."
}

If it IS a clothing item, continue with the analysis below.

CRITICAL DUPLICATE DETECTION:
If the user has shared wardrobe images (after the first image), compare them VERY carefully to the new item:
- If the new item is identical or near-identical to an existing item → ALWAYS recommend NO
- If the new item is very similar (same category, similar color, similar style) → recommend NO with duplication reasoning
- Same item in different colors → recommend MAYBE only if it adds variety
- Different styles or fills a gap in wardrobe → YES

RECOMMENDATION RULES:
- YES: Item strongly matches user's style, fills a gap, and is NOT a duplicate
- MAYBE: Item is okay but has concerns (somewhat similar to existing items, slightly off-style)
- NO: Item is a duplicate of something owned OR doesn't match user's aesthetic

CATEGORY DETECTION (for the FIRST image only):
- "tops" = shirts, blouses, t-shirts, sweaters, jackets, dresses
- "bottoms" = pants, jeans, skirts, shorts
- "footwear" = shoes, boots, sneakers, sandals

RESPONSE FORMAT (strict JSON):
{
  "recommendation": "YES" or "MAYBE" or "NO" or "NOT_CLOTHING",
  "category": "tops" or "bottoms" or "footwear" or "other",
  "reasoning": "Short 1-2 sentence explanation. If duplicate, mention it specifically."
}

Respond ONLY with the JSON, no other text.
''';
      final userMessage = 'Should I buy this item? Analyze and respond in JSON format.';
      final contentList = <Map<String, dynamic>>[];
      contentList.add({
        'type': 'image',
        'source': {
          'type': 'base64',
          'media_type': mediaType,
          'data': base64Image,
        }
      });

      final limitedWardrobeImages = wardrobeImages.take(5).toList();
      for (var i = 0; i < limitedWardrobeImages.length; i++) {
        final category = i < wardrobeImageCategories.length
            ? wardrobeImageCategories[i].toUpperCase()
            : 'UNKNOWN';
        contentList.add({
          'type': 'text',
          'text': '[Wardrobe item ${i + 1} — category: $category]',
        });
        contentList.add({
          'type': 'image',
          'source': {
            'type': 'base64',
            'media_type': _detectMediaType(limitedWardrobeImages[i]),
            'data': base64Encode(limitedWardrobeImages[i]),
          }
        });
      }

      final wardrobeContext = limitedWardrobeImages.isEmpty
          ? ''
          : '\n\nThe images after the first one are items the user ALREADY OWNS, each labeled with their category. Only flag a duplicate if the new item is visually very similar to an item of the SAME category. Do NOT assume the user owns items in categories not shown.';

      contentList.add({
        'type': 'text',
        'text': userMessage + wardrobeContext,
      });

      final requestBody = {
        'model': _model,
        'max_tokens': 500,
        'system': systemPrompt,
        'messages': [
          {
            'role': 'user',
            'content': contentList,
          }
        ],
      };

      final response = await http.post(
        Uri.parse(_apiUrl),
        headers: {
          'Content-Type': 'application/json',
          'x-api-key': apiKey,
          'anthropic-version': _apiVersion,
          'anthropic-dangerous-direct-browser-access': 'true',
        },
        body: jsonEncode(requestBody),
      ).timeout(const Duration(seconds: 30));

      if (response.statusCode != 200) {
        throw Exception('Claude API error: ${response.statusCode} - ${response.body}');
      }

      final responseData = jsonDecode(response.body);
      final aiText = responseData['content'][0]['text'] as String;

      String cleanedJson = aiText.trim();
      if (cleanedJson.startsWith('```')) {
        final firstNewline = cleanedJson.indexOf('\n');
        if (firstNewline != -1) {
          cleanedJson = cleanedJson.substring(firstNewline + 1);
        }
        if (cleanedJson.endsWith('```')) {
          cleanedJson = cleanedJson.substring(0, cleanedJson.length - 3);
        }
        cleanedJson = cleanedJson.trim();
      }

      final aiJson = jsonDecode(cleanedJson);
      final recommendationStr = ((aiJson['recommendation'] as String?) ?? 'MAYBE').toUpperCase();
      final reasoning = (aiJson['reasoning'] as String?) ?? 'No reasoning provided.';
      final category = ((aiJson['category'] as String?) ?? 'other').toLowerCase();

      BuyRecommendation recommendation;
      switch (recommendationStr) {
        case 'YES':
          recommendation = BuyRecommendation.yes;
          break;
        case 'MAYBE':
          recommendation = BuyRecommendation.maybe;
          break;
        case 'NO':
          recommendation = BuyRecommendation.no;
          break;
        case 'NOT_CLOTHING':
          recommendation = BuyRecommendation.notClothing;
          break;
        default:
          recommendation = BuyRecommendation.maybe;
      }

      return AnalysisResult(
        recommendation: recommendation,
        reasoning: reasoning,
        category: category,
      );
    } on TimeoutException {
      throw Exception('Request timed out. Check your connection and try again.');
    } catch (e) {
      if (kDebugMode) {
        print('Claude API error: $e');
      }
      rethrow;
    }
  }

  static String _detectMediaType(Uint8List bytes) {
    if (bytes.length >= 4) {
      if (bytes[0] == 0x89 && bytes[1] == 0x50 && bytes[2] == 0x4E && bytes[3] == 0x47) {
        return 'image/png';
      }
      if (bytes.length >= 12 &&
          bytes[0] == 0x52 && bytes[1] == 0x49 && bytes[2] == 0x46 && bytes[3] == 0x46 &&
          bytes[8] == 0x57 && bytes[9] == 0x45 && bytes[10] == 0x42 && bytes[11] == 0x50) {
        return 'image/webp';
      }
      if (bytes[0] == 0x47 && bytes[1] == 0x49 && bytes[2] == 0x46 && bytes[3] == 0x38) {
        return 'image/gif';
      }
      if (bytes[0] == 0xFF && bytes[1] == 0xD8 && bytes[2] == 0xFF) {
        return 'image/jpeg';
      }
    }
    return 'image/jpeg';
  }
}