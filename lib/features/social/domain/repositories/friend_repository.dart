import 'package:emerge_app/features/social/domain/entities/social_entities.dart';

abstract class FriendRepository {
  Future<List<Friend>> getFriends(String userId);
  Stream<List<Friend>> watchFriends(String userId);
  Future<void> addFriend(String userId, String friendId);
  Future<void> removeFriend(String userId, String friendId);
  Future<void> sendPartnerRequest(
    String fromId,
    String toId,
    String senderName,
    String senderArchetype,
    int senderLevel,
  );
  Future<void> acceptPartnerRequest(String requestId);
  Future<void> rejectPartnerRequest(String requestId);
  Future<List<PartnerRequest>> getPendingRequests(String userId);
  Future<List<Friend>> getOnlinePartners(String userId);
  Stream<List<PartnerRequest>> watchPendingRequests(String userId);
  Stream<List<Friend>> watchOnlinePartners(String userId);
}
