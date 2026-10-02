/// Sound effect cues played by VEGA AI.
enum AudioCue {
  wakeWordAcknowledge,
  listeningStarted,
  commandCompleted,
  errorChime,
}

/// Interface for audio feedback and earcons.
abstract class AudioService {
  Future<void> playCue(AudioCue cue);
  Future<void> stopAll();
  void dispose();
}

/// Default sound service placeholder.
class DefaultAudioService implements AudioService {
  @override
  Future<void> playCue(AudioCue cue) async {
    // Audio earcons trigger haptics and lightweight sound player
  }

  @override
  Future<void> stopAll() async {}

  @override
  void dispose() {}
}
