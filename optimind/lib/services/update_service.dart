import 'package:dio/dio.dart';
import 'package:path_provider/path_provider.dart';
import 'package:open_filex/open_filex.dart';

class UpdateService {
  final Dio _dio = Dio();

  Future<void> downloadAndInstallApk({
    required String apkUrl,
    Function(double progress)? onProgress,
  }) async {
    try {
      final directory = await getTemporaryDirectory();

      final filePath = '${directory.path}/optimind_update.apk';

      await _dio.download(
        apkUrl,
        filePath,
        onReceiveProgress: (received, total) {
          if (total > 0) {
            final progress = received / total;

            if (onProgress != null) {
              onProgress(progress);
            }
          }
        },
      );

      await OpenFilex.open(filePath);
    } catch (e) {
      throw Exception(
        'Failed to download update: $e',
      );
    }
  }
}