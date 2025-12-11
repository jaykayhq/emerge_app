class Tribe {
  final String id;
  final String name;
  final String description;
  final int memberCount;
  final String imageUrl;

  const Tribe({
    required this.id,
    required this.name,
    required this.description,
    required this.memberCount,
    required this.imageUrl,
  });
}

class Challenge {
  final String id;
  final String title;
  final String description;
  final int participants;
  final int daysLeft;
  final String imageUrl;

  const Challenge({
    required this.id,
    required this.title,
    required this.description,
    required this.participants,
    required this.daysLeft,
    required this.imageUrl,
  });
}
