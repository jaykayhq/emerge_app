class CompanionMessage {
  final String message;
  final String tone;
  final List<String>? suggestions;

  const CompanionMessage({
    required this.message,
    required this.tone,
    this.suggestions,
  });
}
