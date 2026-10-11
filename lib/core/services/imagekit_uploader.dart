import 'dart:convert';
import 'dart:typed_data';

import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// رفع مباشر للصور إلى ImageKit (CDN مجاني) دون المرور على Supabase Storage.
///
/// التدفّق:
/// 1) نداء Edge Function `imagekit-auth` (يتحقق من دور الطاقم) للحصول على
///    `token`/`expire`/`signature`/`publicKey`.
/// 2) رفع متعدد الأجزاء مباشرة إلى `upload.imagekit.io`.
/// 3) إعادة رابط CDN مُحمَّل بتحويلات جاهزة (تصغير + webp) لتقليل الحجم.
class ImageKitUploader {
  ImageKitUploader(this._client);

  final SupabaseClient _client;

  /// تحويلات افتراضية: عرض 800، تنسيق webp، جودة 80 (حجم أصغر بكثير).
  static const String defaultTransformation = 'w-800,f-webp,q-80';

  static const String _uploadEndpoint = 'https://upload.imagekit.io/api/v1/files/upload';

  /// يرفع [file] إلى المجلد [folder] باسم [fileNameBase] (مع الامتداد الأصلي)
  /// ويعيد رابط CDN مع [transformation].
  Future<String> upload({
    required XFile file,
    required String folder,
    required String fileNameBase,
    String transformation = defaultTransformation,
  }) async {
    final FunctionResponse auth = await _client.functions.invoke('imagekit-auth');
    if (auth.status != 200 || auth.data is! Map) {
      throw Exception('imagekit_auth_failed:${auth.status}:${auth.data}');
    }
    final Map<String, dynamic> authData = Map<String, dynamic>.from(auth.data as Map);
    final Uint8List bytes = await file.readAsBytes();

    final http.MultipartRequest request = http.MultipartRequest('POST', Uri.parse(_uploadEndpoint))
      ..fields['publicKey'] = '${authData['publicKey']}'
      ..fields['signature'] = '${authData['signature']}'
      ..fields['token'] = '${authData['token']}'
      ..fields['expire'] = '${authData['expire']}'
      ..fields['fileName'] = '$fileNameBase.${_extensionOf(file.name)}'
      ..fields['folder'] = folder
      // إعادة الرفع لنفس الاسم تستبدل الملف بدل إنشاء نسخ مكرّرة.
      ..fields['useUniqueFileName'] = 'false'
      ..files.add(http.MultipartFile.fromBytes('file', bytes, filename: file.name));

    final http.StreamedResponse response = await request.send();
    final String body = await response.stream.bytesToString();
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception('imagekit_upload_failed:${response.statusCode}:$body');
    }
    final Object? url = (jsonDecode(body) as Map)['url'];
    if (url is! String || url.isEmpty) {
      throw Exception('imagekit_upload_no_url:$body');
    }
    return withTransformation(url, transformation);
  }

  /// يضيف `?tr=` إن لم يكن الرابط يحمل تحويلاً مسبقاً.
  static String withTransformation(String url, [String transformation = defaultTransformation]) {
    return url.contains('tr=') ? url : '$url?tr=$transformation';
  }

  static String _extensionOf(String name) {
    final int dot = name.lastIndexOf('.');
    final String ext = dot >= 0 ? name.substring(dot + 1).toLowerCase() : 'jpg';
    return RegExp(r'^[a-z0-9]{2,4}$').hasMatch(ext) ? ext : 'jpg';
  }
}
