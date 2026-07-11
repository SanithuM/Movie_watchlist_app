import 'dart:typed_data';
import 'package:dio/dio.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class CloudinaryService {
  final Dio _dio;

  CloudinaryService()
      : _dio = Dio(
          BaseOptions(
            connectTimeout: const Duration(seconds: 30),
            receiveTimeout: const Duration(seconds: 30),
          ),
        );

  /// Uploads image/gif bytes to Cloudinary and returns the secure URL on success.
  Future<String> uploadImage(Uint8List bytes, String filename) async {
    final cloudName = dotenv.env['CLOUDINARY_CLOUD_NAME']?.trim();
    final uploadPreset = dotenv.env['CLOUDINARY_UPLOAD_PRESET']?.trim();

    if (cloudName == null || cloudName.isEmpty || uploadPreset == null || uploadPreset.isEmpty) {
      throw Exception(
        'Cloudinary credentials are not configured. Please add CLOUDINARY_CLOUD_NAME and CLOUDINARY_UPLOAD_PRESET to your .env file.',
      );
    }

    final url = 'https://api.cloudinary.com/v1_1/$cloudName/image/upload';

    try {
      final formData = FormData.fromMap({
        'file': MultipartFile.fromBytes(
          bytes,
          filename: filename,
        ),
        'upload_preset': uploadPreset,
      });

      final response = await _dio.post(
        url,
        data: formData,
      );

      if (response.statusCode == 200 && response.data != null) {
        final secureUrl = response.data['secure_url'] as String?;
        if (secureUrl != null) {
          return secureUrl;
        }
      }
      throw Exception('Failed to upload image: Invalid response');
    } on DioException catch (e) {
      final responseMsg = e.response?.data?['error']?['message'] ?? e.message;
      throw Exception('Cloudinary Upload Error: $responseMsg');
    } catch (e) {
      throw Exception('Upload Failed: $e');
    }
  }
}

final cloudinaryServiceProvider = Provider<CloudinaryService>((ref) => CloudinaryService());
