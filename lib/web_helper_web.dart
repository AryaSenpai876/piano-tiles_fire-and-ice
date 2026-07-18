import 'dart:typed_data';
import 'dart:html' as html;

class WebHelper {
  static String createBlobUrl(Uint8List bytes) {
    final blob = html.Blob([bytes]);
    return html.Url.createObjectUrlFromBlob(blob);
  }

  static Future<void> saveHighscore(int score) async {
    html.window.localStorage['highscore'] = score.toString();
  }

  static Future<int?> loadHighscore() async {
    final s = html.window.localStorage['highscore'];
    return s != null ? int.tryParse(s) : null;
  }
}
