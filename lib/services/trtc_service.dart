// Mock TRTC service for testing without Tencent SDK
// Replace with real implementation when Tencent credentials are available

class TRTCService {
  bool isMuted = false;
  bool isSpeakerOn = true;
  
  Future<void> initialize({required int sdkAppId, required String secretKey}) async {
    // Mock initialization - no-op for now
    await Future.delayed(const Duration(milliseconds: 100));
  }
  
  Future<void> createRoom({required String roomId, required String userId}) async {
    // Mock room creation - no-op for now
    await Future.delayed(const Duration(milliseconds: 100));
  }
  
  Future<void> joinRoom({required String roomId, required String userId}) async {
    // Mock room join - no-op for now
    await Future.delayed(const Duration(milliseconds: 100));
  }
  
  Future<void> leaveRoom() async {
    // Mock leave - no-op for now
    await Future.delayed(const Duration(milliseconds: 50));
  }
  
  Future<void> toggleMute() async {
    isMuted = !isMuted;
  }
  
  Future<void> toggleSpeaker() async {
    isSpeakerOn = !isSpeakerOn;
  }
}