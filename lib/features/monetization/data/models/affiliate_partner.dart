import 'package:equatable/equatable.dart';

/// Represents an affiliate partner (e.g., Nike, Headspace, Blinkist)
/// Used for sponsored challenges and brand partnerships
class AffiliatePartner extends Equatable {
  final String id;
  final String name;
  final String logoUrl;
  final AffiliateNetwork network;
  final String baseUrl;
  final double commissionRate;
  final int cookieDuration; // in days
  final PartnerStatus status;
  final List<String> supportedArchetypes;
  final DateTime createdAt;
  final DateTime? updatedAt;

  const AffiliatePartner({
    required this.id,
    required this.name,
    required this.logoUrl,
    required this.network,
    required this.baseUrl,
    required this.commissionRate,
    required this.cookieDuration,
    required this.status,
    required this.supportedArchetypes,
    required this.createdAt,
    this.updatedAt,
  });

  /// Converts partner data to Firestore document format
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'logoUrl': logoUrl,
      'network': network.name,
      'baseUrl': baseUrl,
      'commissionRate': commissionRate,
      'cookieDuration': cookieDuration,
      'status': status.name,
      'supportedArchetypes': supportedArchetypes,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
    };
  }

  /// Creates partner from Firestore document
  factory AffiliatePartner.fromMap(Map<String, dynamic> map, {String? id}) {
    // Parse network string to enum
    final networkString = map['network'] as String?;
    AffiliateNetwork parsedNetwork = AffiliateNetwork.none;
    if (networkString != null) {
      try {
        parsedNetwork = AffiliateNetwork.values.firstWhere(
          (e) => e.name == networkString,
          orElse: () => AffiliateNetwork.none,
        );
      } catch (_) {
        parsedNetwork = AffiliateNetwork.none;
      }
    }

    // Parse status string to enum
    final statusString = map['status'] as String?;
    PartnerStatus parsedStatus = PartnerStatus.pending;
    if (statusString != null) {
      try {
        parsedStatus = PartnerStatus.values.firstWhere(
          (e) => e.name == statusString,
          orElse: () => PartnerStatus.pending,
        );
      } catch (_) {
        parsedStatus = PartnerStatus.pending;
      }
    }

    // Parse dates
    DateTime createdAt = DateTime.now();
    if (map['createdAt'] != null) {
      createdAt = DateTime.parse(map['createdAt'] as String);
    }

    DateTime? updatedAt;
    if (map['updatedAt'] != null) {
      updatedAt = DateTime.parse(map['updatedAt'] as String);
    }

    return AffiliatePartner(
      id: id ?? map['id'] ?? '',
      name: map['name'] ?? '',
      logoUrl: map['logoUrl'] ?? '',
      network: parsedNetwork,
      baseUrl: map['baseUrl'] ?? '',
      commissionRate: map['commissionRate']?.toDouble() ?? 0.0,
      cookieDuration: map['cookieDuration']?.toInt() ?? 30,
      status: parsedStatus,
      supportedArchetypes: List<String>.from(map['supportedArchetypes'] ?? []),
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }

  AffiliatePartner copyWith({
    String? name,
    String? logoUrl,
    AffiliateNetwork? network,
    String? baseUrl,
    double? commissionRate,
    int? cookieDuration,
    PartnerStatus? status,
    List<String>? supportedArchetypes,
    DateTime? updatedAt,
  }) {
    return AffiliatePartner(
      id: id,
      name: name ?? this.name,
      logoUrl: logoUrl ?? this.logoUrl,
      network: network ?? this.network,
      baseUrl: baseUrl ?? this.baseUrl,
      commissionRate: commissionRate ?? this.commissionRate,
      cookieDuration: cookieDuration ?? this.cookieDuration,
      status: status ?? this.status,
      supportedArchetypes: supportedArchetypes ?? this.supportedArchetypes,
      createdAt: createdAt,
      updatedAt: updatedAt ?? DateTime.now(),
    );
  }

  @override
  List<Object?> get props => [
    id,
    name,
    logoUrl,
    network,
    baseUrl,
    commissionRate,
    cookieDuration,
    status,
    supportedArchetypes,
    createdAt,
    updatedAt,
  ];
}

/// Affiliate network types
enum AffiliateNetwork { cj, impact, shareASale, amazon, direct, none }

/// Partner status for approval workflow
enum PartnerStatus { active, inactive, pending }
