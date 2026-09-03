import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_jailbreak_detection/flutter_jailbreak_detection.dart';

class RootCheckerService {
  static Future<void> verifyDeviceIntegrity() async {
    // Fitur ini tidak didukung di Web
    if (kIsWeb) return;

    try {
      bool isCompromised = false;

      if (defaultTargetPlatform == TargetPlatform.android) {
        bool isRooted = await FlutterJailbreakDetection.jailbroken;
        bool isDevMode = await FlutterJailbreakDetection.developerMode;
        
        // Di aplikasi nyata, matikan isDevMode saat rilis production
        isCompromised = isRooted || isDevMode; 
      } else if (defaultTargetPlatform == TargetPlatform.iOS) {
        isCompromised = await FlutterJailbreakDetection.jailbroken;
      }

      if (isCompromised) {
        _forceCloseApp();
      }
    } on PlatformException {
      // Jika terjadi error saat memanggil native, asumsikan aman atau force close tergantung strict level
    } catch (e) {
      // Tangani error lainnya
      debugPrint('Root checker error: $e');
    }
  }

  static void _forceCloseApp() {
    debugPrint("🚨 PERANGKAT TER-ROOT/JAILBREAK. APLIKASI DIHENTIKAN.");
    SystemNavigator.pop();
  }
}
