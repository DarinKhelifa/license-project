// Web implementation: listens for window.postMessage from an embedded Wokwi project
import 'dart:html' as html;
import 'dart:convert';

typedef WokwiDataCallback = void Function(Map<String, dynamic> data);

WokwiDataCallback? _callback;

void startWokwiListener(WokwiDataCallback cb) {
  _callback = cb;
  html.window.onMessage.listen((event) {
    try {
      final data = event.data;
      if (data is String) {
        try {
          final decoded = jsonDecode(data);
          if (decoded is Map && (decoded['type'] == 'wokwi-sensor' || decoded['type'] == 'wokwi-energy')) {
            _callback?.call(Map<String, dynamic>.from(decoded));
            return;
          }
        } catch (_) {}
      }
      if (data is Map) {
        // Expect messages like: 
        // { type: 'wokwi-sensor', temperature: 23.4, humidity: 45 }
        // { type: 'wokwi-energy', readings: [{deviceId, deviceName, readingType, value, unit, timestamp}] }
        if (data['type'] == 'wokwi-sensor' || data['type'] == 'wokwi-energy') {
          final map = Map<String, dynamic>.from(data as Map);
          _callback?.call(map);
        }
      }
    } catch (_) {
      // ignore
    }
  });
}

void stopWokwiListener() {
  _callback = null;
}
