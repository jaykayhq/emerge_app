/// A line of narrator text.
///
/// [GenericLine] is pre-written copy shown to all users (free tier).
/// [PersonalLine] is data-grounded copy shown to Pro users.
sealed class NarratorLine {
  const NarratorLine();

  /// The display text — both [GenericLine] and [PersonalLine] carry this.
  String get text;
}

class GenericLine extends NarratorLine {
  final String text;
  const GenericLine(this.text);
}

class PersonalLine extends NarratorLine {
  final String text;
  final String dataBasis;

  const PersonalLine({required this.text, required this.dataBasis});
}
