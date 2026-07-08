enum Mood {
  terrible(1, '😞'),
  meh(2, '😐'),
  ok(3, '🙂'),
  good(4, '😊'),
  great(5, '🔥');

  final int value;
  final String emoji;
  const Mood(this.value, this.emoji);

  static Mood fromInt(int value) =>
      Mood.values.firstWhere((m) => m.value == value, orElse: () => Mood.ok);
}
