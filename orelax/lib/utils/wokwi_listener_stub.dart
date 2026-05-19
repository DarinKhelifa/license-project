typedef WokwiDataCallback = void Function(Map<String, dynamic> data);

void startWokwiListener(WokwiDataCallback cb) {
  // No-op on non-web platforms
}

void stopWokwiListener() {
  // No-op
}
