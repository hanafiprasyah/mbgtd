import 'dart:convert';
import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloudinary_public/cloudinary_public.dart';
import 'package:dio/dio.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:mbg_test/features/food/data/models/food_model.dart';

class FoodRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String _collection = 'foods';

  // Cloudinary instance using CloudinaryPublic
  late final CloudinaryPublic _cloudinary;
  final String _cloudName;
  final String _apiKey;
  final String _apiSecret;

  FoodRepository()
    : _cloudName = dotenv.env['CLOUDINARY_CLOUD_NAME']!,
      _apiKey = dotenv.env['CLOUDINARY_API_KEY']!,
      _apiSecret = dotenv.env['CLOUDINARY_API_SECRET']! {
    _cloudinary = CloudinaryPublic(
      dotenv.env['CLOUDINARY_CLOUD_NAME']!,
      dotenv.env['CLOUDINARY_UPLOAD_PRESET']!,
      cache: false,
    );
  }

  // === CRUD Firestore ===
  Future<List<Food>> getFoods() async {
    final snapshot = await _firestore
        .collection(_collection)
        .orderBy('updatedAt')
        .get();

    return snapshot.docs
        .map((doc) => Food.fromFirestore(doc.data(), doc.id))
        .toList();
  }

  Future<void> addFood(Food food) async {
    await _firestore.collection(_collection).add(food.toFirestore());
  }

  Future<void> updateFood(Food food) async {
    if (food.id == null) throw Exception('Food id cannot be null for update');
    await _firestore
        .collection(_collection)
        .doc(food.id)
        .update(food.toFirestore());
  }

  Future<void> deleteFood(String id) async {
    await _firestore.collection(_collection).doc(id).delete();
  }

  // === Upload photos to Cloudinary ===
  Future<String> uploadPhoto(File imageFile) async {
    try {
      // Create a file Cloudinary with 80% quality transform
      final cloudinaryFile = CloudinaryFile.fromFile(
        imageFile.path,
        resourceType: CloudinaryResourceType.Image,
        folder: 'food_bank', // folder on Cloudinary
      );

      final response = await _cloudinary.uploadFile(cloudinaryFile);

      // Check and get secure URL
      if (response.secureUrl.isNotEmpty && response.assetId.isNotEmpty) {
        return response.secureUrl;
      } else {
        throw Exception(
          'Upload failed: Something wrong while connect to Cloud. Please try again.',
        );
      }
    } catch (e) {
      throw Exception('Cloud server upload error: $e');
    }
  }

  // === Delete photos from Cloudinary ===
  Future<void> deletePhoto(String photoUrl) async {
    if (photoUrl.isEmpty) return;

    try {
      final uri = Uri.parse(photoUrl);
      String path = uri.path;
      String withoutPrefix = path.replaceFirst(RegExp(r'^/image/upload/'), '');
      List<String> parts = withoutPrefix.split('/');
      String publicId = '';
      for (int i = 0; i < parts.length; i++) {
        if (parts[i].startsWith('v') &&
            int.tryParse(parts[i].substring(1)) != null) {
          publicId = parts.sublist(i + 1).join('/');
          break;
        }
      }
      if (publicId.isEmpty) publicId = withoutPrefix;
      int lastDot = publicId.lastIndexOf('.');
      if (lastDot != -1) publicId = publicId.substring(0, lastDot);

      // basic auth
      final dio = Dio();
      final String basicAuth =
          'Basic ${base64Encode(utf8.encode('$_apiKey:$_apiSecret'))}';

      final response = await dio.post(
        'https://api.cloudinary.com/v1_1/$_cloudName/image/destroy',
        data: {'public_id': publicId},
        options: Options(
          headers: {'Authorization': basicAuth},
          contentType: Headers.formUrlEncodedContentType,
        ),
      );

      if (response.statusCode == 200) {
        return;
      } else {
        throw Exception('Cloudinary delete failed: ${response.data}');
      }
    } catch (e) {
      throw Exception('Failed to delete photo from Cloudinary: $e');
    }
  }
}
