/// Health status of an archetype node on the World Map.
enum NodeHealthStatus {
  complete,
  pending,
  decaying,
  idle,
}

/// State representation of an archetype node on the World Map.
class ArchetypeNodeState {
  final NodeHealthStatus status;
  final int pendingCount;
  final int completedCount;
  final bool hasDecay;

  const ArchetypeNodeState({
    required this.status,
    this.pendingCount = 0,
    this.completedCount = 0,
    this.hasDecay = false,
  });

  /// Whether all habits for this archetype node have been completed today.
  bool get isComplete => status == NodeHealthStatus.complete;

  ArchetypeNodeState copyWith({
    NodeHealthStatus? status,
    int? pendingCount,
    int? completedCount,
    bool? hasDecay,
  }) {
    return ArchetypeNodeState(
      status: status ?? this.status,
      pendingCount: pendingCount ?? this.pendingCount,
      completedCount: completedCount ?? this.completedCount,
      hasDecay: hasDecay ?? this.hasDecay,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ArchetypeNodeState &&
          runtimeType == other.runtimeType &&
          status == other.status &&
          pendingCount == other.pendingCount &&
          completedCount == other.completedCount &&
          hasDecay == other.hasDecay;

  @override
  int get hashCode =>
      Object.hash(status, pendingCount, completedCount, hasDecay);

  @override
  String toString() =>
      'ArchetypeNodeState(status: $status, pendingCount: $pendingCount, completedCount: $completedCount, hasDecay: $hasDecay)';
}
