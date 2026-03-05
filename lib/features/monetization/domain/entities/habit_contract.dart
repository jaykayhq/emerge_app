import 'package:equatable/equatable.dart';

class HabitContract extends Equatable {
  final String id;
  final String userId;
  final String habitId;
  final String habitName;
  final String partnerEmail;
  final String? partnerId;
  final String? partnerName;
  final double penaltyAmount;
  final bool isActive;
  final String? signatureUrl;
  final DateTime? signedAt;
  final DateTime? contractStart;
  final DateTime? contractEnd;
  final int missedDays;
  final int totalDays;
  final String status; // active, paused, completed, broken

  const HabitContract({
    required this.id,
    required this.userId,
    required this.habitId,
    this.habitName = 'Habit Contract',
    required this.partnerEmail,
    this.partnerId,
    this.partnerName,
    required this.penaltyAmount,
    this.isActive = true,
    this.signatureUrl,
    this.signedAt,
    this.contractStart,
    this.contractEnd,
    this.missedDays = 0,
    this.totalDays = 30,
    this.status = 'active',
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'userId': userId,
      'habitId': habitId,
      'habitName': habitName,
      'partnerEmail': partnerEmail,
      'partnerId': partnerId,
      'partnerName': partnerName,
      'penaltyAmount': penaltyAmount,
      'isActive': isActive,
      'signatureUrl': signatureUrl,
      'signedAt': signedAt?.toIso8601String(),
      'contractStart': contractStart?.toIso8601String(),
      'contractEnd': contractEnd?.toIso8601String(),
      'missedDays': missedDays,
      'totalDays': totalDays,
      'status': status,
    };
  }

  factory HabitContract.fromMap(Map<String, dynamic> map) {
    return HabitContract(
      id: map['id'] ?? '',
      userId: map['userId'] ?? '',
      habitId: map['habitId'] ?? '',
      habitName: map['habitName'] ?? 'Habit Contract',
      partnerEmail: map['partnerEmail'] ?? '',
      partnerId: map['partnerId'],
      partnerName: map['partnerName'],
      penaltyAmount: (map['penaltyAmount'] ?? 0.0).toDouble(),
      isActive: map['isActive'] ?? false,
      signatureUrl: map['signatureUrl'] as String?,
      signedAt: map['signedAt'] != null
          ? DateTime.tryParse(map['signedAt'] as String)
          : null,
      contractStart: map['contractStart'] != null
          ? DateTime.tryParse(map['contractStart'] as String)
          : null,
      contractEnd: map['contractEnd'] != null
          ? DateTime.tryParse(map['contractEnd'] as String)
          : null,
      missedDays: map['missedDays']?.toInt() ?? 0,
      totalDays: map['totalDays']?.toInt() ?? 30,
      status: map['status'] ?? 'active',
    );
  }

  @override
  List<Object?> get props => [
    id,
    userId,
    habitId,
    habitName,
    partnerEmail,
    partnerId,
    partnerName,
    penaltyAmount,
    isActive,
    signatureUrl,
    signedAt,
    contractStart,
    contractEnd,
    missedDays,
    totalDays,
    status,
  ];
}
