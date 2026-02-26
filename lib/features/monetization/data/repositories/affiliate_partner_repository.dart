import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/affiliate_partner.dart';

/// Repository for managing affiliate partner data
abstract class AffiliatePartnerRepository {
  /// Get stream of all active partners
  Stream<List<AffiliatePartner>> getActivePartners();

  /// Get a specific partner by ID
  Future<AffiliatePartner?> getPartner(String partnerId);

  /// Get partners by network (CJ, Impact, etc.)
  Stream<List<AffiliatePartner>> getPartnersByNetwork(AffiliateNetwork network);

  /// Get partners supporting a specific archetype
  Stream<List<AffiliatePartner>> getPartnersByArchetype(String archetypeId);

  /// Add a new partner
  Future<void> addPartner(AffiliatePartner partner);

  /// Update existing partner
  Future<void> updatePartner(AffiliatePartner partner);

  /// Track impression (when user views sponsored challenge)
  Future<void> trackImpression(String partnerId, String userId);

  /// Track click (when user clicks affiliate link)
  Future<void> trackClick(String partnerId, String userId);

  /// Get partner analytics (impressions, clicks, conversions)
  Future<Map<String, dynamic>> getPartnerAnalytics(String partnerId);
}

/// Firestore implementation of AffiliatePartnerRepository
class FirestoreAffiliatePartnerRepository
    implements AffiliatePartnerRepository {
  final FirebaseFirestore _firestore;

  FirestoreAffiliatePartnerRepository({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  CollectionReference get _partnersCollection =>
      _firestore.collection('affiliatePartners');

  CollectionReference get _analyticsCollection =>
      _firestore.collection('affiliatePartnerAnalytics');

  @override
  Stream<List<AffiliatePartner>> getActivePartners() {
    return _partnersCollection
        .where('status', isEqualTo: 'active')
        .orderBy('name')
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map(
                (doc) => AffiliatePartner.fromMap(
                  doc.data() as Map<String, dynamic>,
                  id: doc.id,
                ),
              )
              .toList(),
        );
  }

  @override
  Future<AffiliatePartner?> getPartner(String partnerId) async {
    final doc = await _partnersCollection.doc(partnerId).get();
    if (!doc.exists) return null;
    return AffiliatePartner.fromMap(
      doc.data() as Map<String, dynamic>,
      id: doc.id,
    );
  }

  @override
  Stream<List<AffiliatePartner>> getPartnersByNetwork(
    AffiliateNetwork network,
  ) {
    return _partnersCollection
        .where('network', isEqualTo: network.name)
        .where('status', isEqualTo: 'active')
        .orderBy('name')
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map(
                (doc) => AffiliatePartner.fromMap(
                  doc.data() as Map<String, dynamic>,
                  id: doc.id,
                ),
              )
              .toList(),
        );
  }

  @override
  Stream<List<AffiliatePartner>> getPartnersByArchetype(String archetypeId) {
    return _partnersCollection
        .where('supportedArchetypes', arrayContains: archetypeId)
        .where('status', isEqualTo: 'active')
        .orderBy('name')
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map(
                (doc) => AffiliatePartner.fromMap(
                  doc.data() as Map<String, dynamic>,
                  id: doc.id,
                ),
              )
              .toList(),
        );
  }

  @override
  Future<void> addPartner(AffiliatePartner partner) async {
    await _partnersCollection.doc(partner.id).set(partner.toMap());
  }

  @override
  Future<void> updatePartner(AffiliatePartner partner) async {
    final updatedPartner = partner.copyWith(updatedAt: DateTime.now());
    await _partnersCollection.doc(partner.id).update(updatedPartner.toMap());
  }

  @override
  Future<void> trackImpression(String partnerId, String userId) async {
    final today = DateTime.now();
    final dateKey =
        '${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}';

    await _analyticsCollection.doc(partnerId).set({
      'partnerId': partnerId,
      'lastUpdated': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));

    await _analyticsCollection
        .doc(partnerId)
        .collection('daily')
        .doc(dateKey)
        .set({
          'date': dateKey,
          'impressions': FieldValue.increment(1),
          'lastUpdated': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));

    // Track per-user impressions
    await _analyticsCollection
        .doc(partnerId)
        .collection('users')
        .doc(userId)
        .set({
          'userId': userId,
          'impressions': FieldValue.increment(1),
          'lastImpressionAt': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
  }

  @override
  Future<void> trackClick(String partnerId, String userId) async {
    final today = DateTime.now();
    final dateKey =
        '${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}';

    await _analyticsCollection.doc(partnerId).set({
      'partnerId': partnerId,
      'lastUpdated': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));

    await _analyticsCollection
        .doc(partnerId)
        .collection('daily')
        .doc(dateKey)
        .set({
          'date': dateKey,
          'clicks': FieldValue.increment(1),
          'lastUpdated': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));

    // Track per-user clicks
    await _analyticsCollection
        .doc(partnerId)
        .collection('users')
        .doc(userId)
        .set({
          'userId': userId,
          'clicks': FieldValue.increment(1),
          'lastClickAt': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
  }

  @override
  Future<Map<String, dynamic>> getPartnerAnalytics(String partnerId) async {
    final partnerDoc = await _analyticsCollection.doc(partnerId).get();
    if (!partnerDoc.exists) {
      return {'impressions': 0, 'clicks': 0, 'ctr': 0.0, 'uniqueUsers': 0};
    }

    // Get aggregate data from daily stats (last 30 days)
    final thirtyDaysAgo = DateTime.now().subtract(const Duration(days: 30));
    final dailySnapshot = await _analyticsCollection
        .doc(partnerId)
        .collection('daily')
        .where('date', isGreaterThanOrEqualTo: thirtyDaysAgo.toIso8601String())
        .get();

    int totalImpressions = 0;
    int totalClicks = 0;

    for (var doc in dailySnapshot.docs) {
      final data = doc.data();
      totalImpressions += data['impressions'] as int? ?? 0;
      totalClicks += data['clicks'] as int? ?? 0;
    }

    // Get unique users count
    final usersSnapshot = await _analyticsCollection
        .doc(partnerId)
        .collection('users')
        .get();

    return {
      'impressions': totalImpressions,
      'clicks': totalClicks,
      'ctr': totalImpressions > 0 ? totalClicks / totalImpressions : 0.0,
      'uniqueUsers': usersSnapshot.docs.length,
      'lastUpdated': partnerDoc['lastUpdated'],
    };
  }
}
