import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fast_contacts/fast_contacts.dart' as fc;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';
import 'package:go_router/go_router.dart';
import 'package:permission_handler/permission_handler.dart';

import 'package:emerge_app/core/presentation/widgets/emerge_primary_button.dart';
import 'package:emerge_app/core/theme/emerge_colors.dart';
import 'package:emerge_app/features/auth/presentation/providers/auth_providers.dart';
import 'package:emerge_app/features/social/domain/services/contact_resolver.dart';
import 'package:emerge_app/features/social/presentation/providers/friend_provider.dart';

final contactResolverProvider = Provider<ContactResolver>((ref) {
  return FirestoreContactResolver(FirebaseFirestore.instance);
});

/// Address-book discovery surface: reads device contacts, matches them
/// against existing emerge users, and lets the user invite matches as
/// partners or send an invite code to non-matches.
///
/// Contacts are read on-device and never uploaded wholesale. Only the
/// phone/email needed for the lookup query are sent, and the lookup is a
/// read, not a store.
class SocialContactsScreen extends ConsumerStatefulWidget {
  const SocialContactsScreen({super.key});

  @override
  ConsumerState<SocialContactsScreen> createState() =>
      _SocialContactsScreenState();
}

class _SocialContactsScreenState extends ConsumerState<SocialContactsScreen> {
  bool _loading = false;
  String? _error;
  List<ContactMatch> _matches = const [];
  bool _permissionGranted = false;

  Future<void> _loadContacts() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final status = await Permission.contacts.status;
      if (!status.isGranted) {
        final result = await Permission.contacts.request();
        if (!result.isGranted) {
          setState(() {
            _loading = false;
            _permissionGranted = false;
          });
          return;
        }
      }
      _permissionGranted = true;

      // Read on-device via fast_contacts.
      final contacts = await fc.FastContacts.getAllContacts();
      final resolved = contacts
          .map((c) => ResolvedContact(
                name: c.displayName,
                phone: c.phones.isNotEmpty ? c.phones.first.number : null,
                email: c.emails.isNotEmpty ? c.emails.first.address : null,
              ))
          .where((c) => c.phone != null || c.email != null)
          .toList();

      final resolver = ref.read(contactResolverProvider);
      final matches = await resolver.resolve(resolved);
      // Matches first, then unmatched.
      matches.sort((a, b) {
        if (a.isMatched == b.isMatched) {
          return a.contact.name.compareTo(b.contact.name);
        }
        return a.isMatched ? -1 : 1;
      });

      setState(() {
        _matches = matches;
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Could not read contacts.';
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text('FIND FROM CONTACTS'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(strokeWidth: 2))
          : _error != null
              ? Center(
                  child: Text(
                    _error!,
                    style: const TextStyle(color: Colors.white60),
                  ),
                )
              : _matches.isEmpty && _permissionGranted
                  ? _emptyState()
                  : _matches.isEmpty
                      ? _permissionGate()
                      : _list(),
    );
  }

  Widget _permissionGate() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.contact_page, size: 48, color: Colors.white54),
            const Gap(16),
            const Text(
              'Find people you know from your address book.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.white70),
            ),
            const Gap(8),
            const Text(
              'Your contacts stay on your device. We only look up phone numbers and emails to find matches.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.white38, fontSize: 12),
            ),
            const Gap(24),
            EmergePrimaryButton(
              label: 'ALLOW CONTACTS',
              onPressed: _loadContacts,
            ),
          ],
        ),
      ),
    );
  }

  Widget _emptyState() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text(
            'No matches found yet.',
            style: TextStyle(color: Colors.white60),
          ),
          const Gap(12),
          TextButton(
            onPressed: () => context.pop(),
            child: const Text('Invite with a code instead →'),
          ),
        ],
      ),
    );
  }

  Widget _list() {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      itemCount: _matches.length,
      itemBuilder: (_, i) {
        final m = _matches[i];
        return _ContactRow(match: m);
      },
    );
  }
}

class _ContactRow extends ConsumerWidget {
  final ContactMatch match;
  const _ContactRow({required this.match});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: EmergeColors.glassWhite,
            child: Text(
              match.contact.name.isNotEmpty
                  ? match.contact.name[0].toUpperCase()
                  : '?',
            ),
          ),
          const Gap(12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  match.contact.name,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                if (match.isMatched)
                  Text(
                    match.matchedDisplayName ?? 'On Emerge',
                    style: const TextStyle(
                      color: Colors.greenAccent,
                      fontSize: 11,
                    ),
                  )
                else
                  const Text(
                    'Not on Emerge yet',
                    style: TextStyle(color: Colors.white38, fontSize: 11),
                  ),
              ],
            ),
          ),
          if (match.isMatched)
            TextButton(
              onPressed: () async {
                final user = ref.read(authStateChangesProvider).value;
                if (user == null || match.matchedUserId == null) return;
                final repo = ref.read(friendRepositoryProvider);
                await repo.sendPartnerRequest(
                  user.id,
                  match.matchedUserId!,
                  user.displayName ?? 'You',
                  'creator',
                  1,
                );
                if (!context.mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Partner request sent')),
                );
              },
              child: const Text('ADD'),
            )
          else
            TextButton(
              onPressed: () => context.push('/social/accountability'),
              child: const Text('INVITE'),
            ),
        ],
      ),
    );
  }
}
