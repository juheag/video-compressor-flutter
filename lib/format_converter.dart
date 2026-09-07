import 'dart:io';
import 'package:ffmpeg_kit_flutter_new/ffmpeg_kit.dart';
import 'package:ffmpeg_kit_flutter_new/return_code.dart';
import 'package:path_provider/path_provider.dart';

class FormatConverter {
  static Future<String?> convert({
    required String inputPath,
    required String targetFormat,
  }) async {
    final tempDir = await getTemporaryDirectory();
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final outputPath = '${tempDir.path}/convertido_$timestamp.$targetFormat';

    String command;

    switch (targetFormat.toLowerCase()) {
      case 'mov':
        command = '-y -i "$inputPath" -c copy "$outputPath"';
        break;
      case 'mp4':
        command = '-y -i "$inputPath" -c:v libx264 -c:a aac "$outputPath"';
        break;
      case 'mp3':
        command = '-y -i "$inputPath" -vn -c:a aac "$outputPath"';
        break;
      case 'gif':
        command = '-y -i "$inputPath" -vf "fps=10,scale=360:-1:flags=lanczos" "$outputPath"';
        break;
      default:
        command = '-y -i "$inputPath" "$outputPath"';
    }

    final session = await FFmpegKit.execute(command);
    final returnCode = await session.getReturnCode();

    if (ReturnCode.isSuccess(returnCode)) {
      return outputPath;
    } else {
      return null;
    }
  }
}
