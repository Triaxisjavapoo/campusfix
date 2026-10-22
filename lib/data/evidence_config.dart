abstract final class EvidenceConfig {
  static const emulators = bool.fromEnvironment('USE_EMULATORS');
  static const enabled = emulators || bool.fromEnvironment('STORAGE_ENABLED');
  static const provider = emulators
      ? 'firebase'
      : String.fromEnvironment('EVIDENCE_PROVIDER', defaultValue: 'firebase');
  static const supabaseUrl = String.fromEnvironment('SUPABASE_URL');
}
