/// Axial coordinates for Hexagonal Grid (q, r)
/// s is derived as -q - r
class HexLocation {
  final int q; // column
  final int r; // row

  const HexLocation(this.q, this.r);

  int get s => -q - r;

  /// Equality check
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is HexLocation &&
          runtimeType == other.runtimeType &&
          q == other.q &&
          r == other.r;

  @override
  int get hashCode => q.hashCode ^ r.hashCode;

  @override
  String toString() => 'Hex($q, $r)';

  /// Distance between two hexes in grid units
  int distanceTo(HexLocation other) {
    return ((q - other.q).abs() +
            (q + r - other.q - other.r).abs() +
            (r - other.r).abs()) ~/
        2;
  }

  /// Get neighbor at direction index (0..5)
  HexLocation neighbor(int direction) {
    const directions = [
      HexLocation(1, 0),
      HexLocation(1, -1),
      HexLocation(0, -1),
      HexLocation(-1, 0),
      HexLocation(-1, 1),
      HexLocation(0, 1),
    ];
    final dir = directions[direction % 6];
    return HexLocation(q + dir.q, r + dir.r);
  }

  /// Convert to Cube coordinates (x, y, z)
  List<int> toCube() => [q, r, s];

  Map<String, dynamic> toMap() {
    return {'q': q, 'r': r};
  }

  factory HexLocation.fromMap(Map<String, dynamic> map) {
    return HexLocation(map['q'] as int, map['r'] as int);
  }
}
