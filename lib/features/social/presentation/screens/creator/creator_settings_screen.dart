// lib/features/social/presentation/screens/creator/creator_settings_screen.dart
import 'package:emerge_app/core/presentation/widgets/app_error_widget.dart';
import 'package:emerge_app/core/presentation/widgets/emerge_loading_skeleton.dart';
import 'package:emerge_app/core/presentation/widgets/fallback_initial_avatar.dart';
import 'package:emerge_app/core/theme/emerge_colors.dart';
import 'package:emerge_app/features/auth/presentation/providers/auth_providers.dart';
import 'package:emerge_app/features/blueprints/data/repositories/blueprint_repository.dart';
import 'package:emerge_app/features/blueprints/domain/models/blueprint.dart';
import 'package:emerge_app/features/blueprints/presentation/widgets/blueprint_artwork.dart';
import 'package:emerge_app/features/social/domain/entities/creator_profile.dart';
import 'package:emerge_app/features/social/domain/services/creator_media_service.dart';
import 'package:emerge_app/features/social/presentation/providers/creator_provider.dart';
import 'package:emerge_app/features/social/presentation/providers/creator_settings_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';
import 'package:go_router/go_router.dart';

/// Creator-mode settings: profile image + hero banner, name, bio + specialty
/// tags, per-blueprint cover art, and sign-out. Image changes pick from the
/// gallery, upload to Firebase Storage, then write the download URL to the
/// matching Firestore doc — the public profile and blueprint cards pick the
/// change up via their live streams.
class CreatorSettingsScreen extends ConsumerStatefulWidget {
  const CreatorSettingsScreen({super.key});

  @override
  ConsumerState<CreatorSettingsScreen> createState() =>
      _CreatorSettingsScreenState();
}

class _CreatorSettingsScreenState extends ConsumerState<CreatorSettingsScreen> {
  static const int _maxBioChars = 280;
  static const int _maxTags = 8;
  static const int _maxTagLength = 24;

  bool _uploading = false;

  @override
  Widget build(BuildContext context) {
    final uid = ref.watch(currentCreatorUidProvider);
    if (uid == null) return _buildSignedOutScaffold();

    final profileAsync = ref.watch(creatorProfileProvider(uid));

    return Scaffold(
      backgroundColor: EmergeColors.cosmicVoidDark,
      appBar: AppBar(
        title: const Text('Creator Settings'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => context.pop(),
        ),
      ),
      body: profileAsync.when(
        loading: () => const Padding(
          padding: EdgeInsets.all(16),
          child: EmergeLoadingSkeleton(itemCount: 4),
        ),
        error: (e, st) => AppErrorWidget(
          message: 'Could not load your creator profile.',
          onRetry: () => ref.invalidate(creatorProfileProvider(uid)),
        ),
        data: (profile) {
          if (profile == null) return _buildMissingProfile();
          return _buildContent(context, uid, profile);
        },
      ),
    );
  }

  // ── Content ──────────────────────────────────────────────────────────────
  Widget _buildContent(BuildContext context, String uid, CreatorProfile profile) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _buildSectionHeader('Profile'),
        _buildAvatarAndHero(context, uid, profile),
        const Gap(24),
        _buildSectionHeader('Identity'),
        _buildSectionContainer([
          _buildListTile(
            Icons.badge_outlined,
            'Name',
            subtitle: profile.displayName?.isNotEmpty == true
                ? profile.displayName!
                : 'No name set',
            onTap: _uploading ? null : () => _showNameDialog(uid, profile),
          ),
          _buildListTile(
            Icons.notes_rounded,
            'Bio',
            subtitle: profile.bio.isNotEmpty
                ? profile.bio
                : 'Tell your tribe who you are',
            onTap: _uploading ? null : () => _showBioDialog(uid, profile),
          ),
        ]),
        const Gap(16),
        _buildSectionContainer([
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
            child: Text(
              'SPECIALITY TAGS',
              style: TextStyle(
                color: Colors.white38,
                fontSize: 11,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.5,
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final tag in profile.specialityTags)
                  Chip(
                    label: Text(tag),
                    labelStyle: const TextStyle(
                      color: EmergeColors.neonTeal,
                      fontWeight: FontWeight.w600,
                      fontSize: 12,
                    ),
                    backgroundColor: EmergeColors.neonTeal.withValues(
                      alpha: 0.12,
                    ),
                    deleteIconColor: EmergeColors.neonTeal,
                    side: BorderSide(
                      color: EmergeColors.neonTeal.withValues(alpha: 0.3),
                    ),
                    onDeleted: _uploading || profile.specialityTags.length <= 1
                        ? null
                        : () => _removeTag(uid, profile, tag),
                  ),
                ActionChip(
                  avatar: const Icon(
                    Icons.add_rounded,
                    size: 16,
                    color: Colors.white70,
                  ),
                  label: const Text(
                    'Add tag',
                    style: TextStyle(color: Colors.white70, fontSize: 12),
                  ),
                  backgroundColor: Colors.white.withValues(alpha: 0.06),
                  side: BorderSide(color: Colors.white.withValues(alpha: 0.15)),
                  onPressed: _uploading || profile.specialityTags.length >= _maxTags
                      ? null
                      : () => _showAddTagDialog(uid, profile),
                ),
              ],
            ),
          ),
        ]),
        const Gap(24),
        _buildSectionHeader('Blueprint covers'),
        _buildBlueprintCovers(uid),
        const Gap(24),
        _buildSectionHeader('Account'),
        _buildSectionContainer([
          _buildListTile(
            Icons.open_in_new_rounded,
            'View public profile',
            subtitle: 'See how your tribe sees you',
            onTap: () => context.push('/creators/$uid'),
          ),
        ]),
        const Gap(24),
        SizedBox(
          width: double.infinity,
          height: 50,
          child: OutlinedButton(
            onPressed: _uploading ? null : _logout,
            style: OutlinedButton.styleFrom(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              side: const BorderSide(color: EmergeColors.coral),
              foregroundColor: EmergeColors.coral,
            ),
            child: const Text(
              'Log Out',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
        ),
        const Gap(32),
      ],
    );
  }

  Widget _buildAvatarAndHero(
    BuildContext context,
    String uid,
    CreatorProfile profile,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Hero banner — tap to change.
        GestureDetector(
          key: const Key('creator_settings_hero'),
          onTap: _uploading ? null : () => _pickAndUpload(uid, CreatorMediaType.hero),
          child: Container(
            height: 120,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.12),
              ),
            ),
            clipBehavior: Clip.antiAlias,
            child: Stack(
              fit: StackFit.expand,
              children: [
                if (profile.heroImageUrl != null &&
                    profile.heroImageUrl!.isNotEmpty)
                  Image.network(
                    profile.heroImageUrl!,
                    fit: BoxFit.cover,
                    errorBuilder: (_, _, _) => const _HeroPlaceholder(),
                  )
                else
                  const _HeroPlaceholder(),
                Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.transparent,
                        Colors.black.withValues(alpha: 0.55),
                      ],
                    ),
                  ),
                ),
                Positioned(
                  bottom: 10,
                  right: 12,
                  child: _CameraBadge(enabled: !_uploading),
                ),
                const Positioned(
                  bottom: 10,
                  left: 12,
                  child: Text(
                    'HERO BANNER',
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.5,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        const Gap(16),
        // Avatar — tap to change.
        Center(
          child: GestureDetector(
            key: const Key('creator_settings_avatar'),
            onTap: _uploading
                ? null
                : () => _pickAndUpload(uid, CreatorMediaType.avatar),
            child: Stack(
              children: [
                FallbackInitialAvatar(
                  name: profile.displayName,
                  size: 104,
                  imageUrl: profile.avatarUrl,
                  borderColor: EmergeColors.neonTeal.withValues(alpha: 0.4),
                  borderWidth: 2,
                ),
                Positioned(
                  right: 0,
                  bottom: 0,
                  child: _CameraBadge(enabled: !_uploading),
                ),
              ],
            ),
          ),
        ),
        const Gap(8),
        Center(
          child: Text(
            _uploading ? 'Uploading…' : 'Tap your avatar to change it',
            style: const TextStyle(color: Colors.white38, fontSize: 12),
          ),
        ),
      ],
    );
  }

  Widget _buildBlueprintCovers(String uid) {
    final blueprintsAsync = ref.watch(creatorOwnBlueprintsProvider);

    return blueprintsAsync.when(
      loading: () => const EmergeLoadingSkeleton(itemCount: 2),
      error: (e, st) => Text(
        'Could not load your blueprints.',
        style: TextStyle(color: Colors.white38, fontSize: 13),
      ),
      data: (blueprints) {
        if (blueprints.isEmpty) {
          return Text(
            'No blueprints yet — publish one from the Blueprint Studio.',
            style: TextStyle(color: Colors.white38, fontSize: 13),
          );
        }
        return Column(
          children: [
            for (final blueprint in blueprints)
              _buildBlueprintRow(uid, blueprint),
          ],
        );
      },
    );
  }

  Widget _buildBlueprintRow(String uid, Blueprint blueprint) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.04),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
        ),
        child: Row(
          children: [
            SizedBox(
              width: 56,
              height: 56,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: BlueprintArtwork(
                  imageUrl: blueprint.imageUrl,
                  useCachedNetworkImage: true,
                ),
              ),
            ),
            const Gap(12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    blueprint.title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const Gap(2),
                  Text(
                    '${blueprint.habits.length} habits · '
                    '${blueprint.adoptionCount} adopted',
                    style: const TextStyle(color: Colors.white38, fontSize: 11),
                  ),
                ],
              ),
            ),
            TextButton(
              onPressed: _uploading
                  ? null
                  : () => _pickAndUpload(
                      uid,
                      CreatorMediaType.blueprint,
                      blueprintId: blueprint.id,
                    ),
              child: const Text('Change'),
            ),
          ],
        ),
      ),
    );
  }

  // ── Section scaffolding (design-doc glass containers) ────────────────────
  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12, left: 4),
      child: Text(
        title.toUpperCase(),
        style: const TextStyle(
          color: Colors.white38,
          fontSize: 13,
          fontWeight: FontWeight.bold,
          letterSpacing: 1.2,
        ),
      ),
    );
  }

  Widget _buildSectionContainer(List<Widget> children) {
    // Material(type: transparency) so ListTile paints its ink/background on a
    // real Material ancestor instead of being hidden by the DecoratedBox.
    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
      ),
      child: Material(
        type: MaterialType.transparency,
        child: Column(children: children),
      ),
    );
  }

  Widget _buildListTile(
    IconData icon,
    String title, {
    String? subtitle,
    VoidCallback? onTap,
  }) {
    return ListTile(
      onTap: onTap,
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: EmergeColors.neonTeal.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, color: EmergeColors.neonTeal, size: 20),
      ),
      title: Text(
        title,
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w500,
          fontSize: 14,
        ),
      ),
      subtitle: subtitle != null
          ? Text(
              subtitle,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(color: Colors.white38, fontSize: 12),
            )
          : null,
      trailing: const Icon(Icons.chevron_right_rounded, color: Colors.white24),
    );
  }

  // ── Image flow ───────────────────────────────────────────────────────────
  Future<void> _pickAndUpload(
    String uid,
    CreatorMediaType type, {
    String? blueprintId,
  }) async {
    final PickedCreatorImage? picked;
    try {
      picked = await ref.read(creatorImagePickerProvider).pickImage();
    } catch (_) {
      _showSnack('Could not open the photo picker.');
      return;
    }
    if (picked == null) return; // Cancelled — deliberate no-op.

    setState(() => _uploading = true);
    try {
      final url = await ref.read(creatorMediaServiceProvider).uploadCreatorImage(
        userId: uid,
        type: type,
        bytes: picked.bytes,
        filename: picked.filename,
        blueprintId: blueprintId,
      );

      if (type == CreatorMediaType.blueprint) {
        await ref
            .read(blueprintRepositoryProvider)
            .updateBlueprintImage(blueprintId!, url);
      } else {
        await ref.read(creatorRepositoryProvider).updateCreatorProfileFields(
          uid,
          avatarUrl: type == CreatorMediaType.avatar ? url : null,
          heroImageUrl: type == CreatorMediaType.hero ? url : null,
        );
      }

      ref.invalidate(creatorProfileProvider(uid));
      ref.invalidate(creatorOwnBlueprintsProvider);
      _showSnack(
        type == CreatorMediaType.blueprint
            ? 'Blueprint cover updated.'
            : 'Profile image updated.',
      );
    } catch (_) {
      _showSnack("Couldn't upload the image. Check your connection and try again.");
    } finally {
      if (mounted) setState(() => _uploading = false);
    }
  }

  // ── Name / bio / tags ────────────────────────────────────────────────────
  Future<void> _showNameDialog(String uid, CreatorProfile profile) async {
    final controller = TextEditingController(
      text: profile.displayName ?? '',
    );
    final saved = await showDialog<String>(
      context: context,
      builder: (context) => _TextEntryDialog(
        title: 'Change name',
        hint: 'How should your tribe address you?',
        controller: controller,
        actionLabel: 'Save',
        maxLength: 50,
        onSave: (value) => value.trim().isNotEmpty ? value.trim() : null,
      ),
    );
    if (saved == null || !mounted) return;

    final result = await ref
        .read(authRepositoryProvider)
        .updateDisplayName(saved);
    result.fold(
      (failure) => _showSnack("Couldn't update name: ${failure.message}"),
      (_) async {
        try {
          await ref.read(creatorRepositoryProvider).updateCreatorName(uid, saved);
          ref.invalidate(authStateChangesProvider);
          ref.invalidate(creatorProfileProvider(uid));
        } catch (_) {
          _showSnack("Name saved to your account but the profile sync lagged — pull to refresh.");
          return;
        }

        // Best-effort: sync the denormalized creatorName onto published
        // blueprints. A failure here is non-fatal — the account rename above
        // already succeeded and new blueprints pick up the fresh name.
        try {
          await ref
              .read(blueprintRepositoryProvider)
              .updateCreatorNameOnBlueprints(uid, saved);
        } catch (_) {
          // Blueprint cards catch up on the next edit/publish.
        }
        ref.invalidate(creatorOwnBlueprintsProvider);
        _showSnack('Name updated.');
      },
    );
  }

  Future<void> _showBioDialog(String uid, CreatorProfile profile) async {
    final controller = TextEditingController(text: profile.bio);
    final saved = await showDialog<String>(
      context: context,
      builder: (context) => _TextEntryDialog(
        title: 'Edit bio',
        hint: 'What do you teach? Who is it for?',
        controller: controller,
        actionLabel: 'Save',
        maxLength: _maxBioChars,
        maxLines: 4,
        onSave: (value) => value.trim(),
      ),
    );
    if (saved == null || !mounted) return;
    try {
      await ref
          .read(creatorRepositoryProvider)
          .updateCreatorProfileFields(uid, bio: saved);
      ref.invalidate(creatorProfileProvider(uid));
      _showSnack('Bio updated.');
    } catch (_) {
      _showSnack("Couldn't save your bio. Try again.");
    }
  }

  Future<void> _showAddTagDialog(String uid, CreatorProfile profile) async {
    final controller = TextEditingController();
    final tag = await showDialog<String>(
      context: context,
      builder: (context) => _TextEntryDialog(
        title: 'Add speciality tag',
        hint: 'e.g. Strength, Mobility, Recovery',
        controller: controller,
        actionLabel: 'Add',
        maxLength: _maxTagLength,
        onSave: (value) {
          final trimmed = value.trim();
          if (trimmed.isEmpty) return null;
          if (profile.specialityTags.contains(trimmed)) return null;
          return trimmed;
        },
      ),
    );
    if (tag == null || !mounted) return;
    try {
      await ref.read(creatorRepositoryProvider).updateCreatorProfileFields(
        uid,
        specialityTags: [...profile.specialityTags, tag],
      );
      ref.invalidate(creatorProfileProvider(uid));
      _showSnack('Tag added.');
    } catch (_) {
      _showSnack("Couldn't save the tag. Try again.");
    }
  }

  Future<void> _removeTag(String uid, CreatorProfile profile, String tag) async {
    try {
      await ref.read(creatorRepositoryProvider).updateCreatorProfileFields(
        uid,
        specialityTags: profile.specialityTags.where((t) => t != tag).toList(),
      );
      ref.invalidate(creatorProfileProvider(uid));
    } catch (_) {
      _showSnack("Couldn't remove the tag. Try again.");
    }
  }

  // ── Logout ───────────────────────────────────────────────────────────────
  Future<void> _logout() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF13081E),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(
            color: EmergeColors.coral.withValues(alpha: 0.3),
          ),
        ),
        title: const Text(
          'Log out?',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        content: const Text(
          'You will need your invite code to sign back in to creator mode.',
          style: TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel', style: TextStyle(color: Colors.white54)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text(
              'Log Out',
              style: TextStyle(color: EmergeColors.coral),
            ),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    try {
      await ref.read(authRepositoryProvider).signOut();
      if (mounted) context.go('/creator/login');
    } catch (_) {
      _showSnack("Couldn't log out. Try again.");
    }
  }

  // ── Edge states ──────────────────────────────────────────────────────────
  Widget _buildSignedOutScaffold() {
    return Scaffold(
      backgroundColor: EmergeColors.cosmicVoidDark,
      appBar: AppBar(
        title: const Text('Creator Settings'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.lock_outline_rounded, size: 48, color: Colors.white24),
            const Gap(16),
            const Text(
              'Not signed in',
              style: TextStyle(color: Colors.white70, fontSize: 16),
            ),
            const Gap(16),
            FilledButton(
              onPressed: () => context.go('/creator/login'),
              style: FilledButton.styleFrom(
                backgroundColor: EmergeColors.neonTeal,
                foregroundColor: Colors.black,
              ),
              child: const Text('Go to creator login'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMissingProfile() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.person_off_rounded, size: 48, color: Colors.white24),
          const Gap(16),
          const Text(
            'Creator profile not found',
            style: TextStyle(color: Colors.white70, fontSize: 16),
          ),
        ],
      ),
    );
  }

  void _showSnack(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }
}

// ── Small private widgets ──────────────────────────────────────────────────
class _CameraBadge extends StatelessWidget {
  final bool enabled;

  const _CameraBadge({required this.enabled});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 36,
      height: 36,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: EmergeColors.neonTeal,
        border: Border.all(color: EmergeColors.cosmicVoidDark, width: 2),
      ),
      child: Icon(
        Icons.photo_camera_rounded,
        size: 18,
        color: enabled ? Colors.black : Colors.black45,
      ),
    );
  }
}

class _HeroPlaceholder extends StatelessWidget {
  const _HeroPlaceholder();

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            EmergeColors.nebulaSecondary.withValues(alpha: 0.3),
            EmergeColors.cosmicVoidDark,
          ],
        ),
      ),
      child: const Center(
        child: Icon(Icons.panorama_outlined, size: 40, color: Colors.white24),
      ),
    );
  }
}

class _TextEntryDialog extends StatelessWidget {
  final String title;
  final String hint;
  final TextEditingController controller;
  final String actionLabel;
  final int maxLength;
  final int maxLines;
  final String? Function(String value) onSave;

  const _TextEntryDialog({
    required this.title,
    required this.hint,
    required this.controller,
    required this.actionLabel,
    required this.maxLength,
    required this.onSave,
    this.maxLines = 1,
  });

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: const Color(0xFF13081E),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(color: EmergeColors.neonTeal.withValues(alpha: 0.3)),
      ),
      title: Text(
        title,
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.bold,
          fontSize: 18,
        ),
      ),
      content: TextField(
        controller: controller,
        maxLines: maxLines,
        maxLength: maxLength,
        autofocus: true,
        style: const TextStyle(color: Colors.white),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: const TextStyle(color: Colors.white38),
          filled: true,
          fillColor: Colors.white.withValues(alpha: 0.05),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          counterStyle: const TextStyle(color: Colors.white38, fontSize: 11),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel', style: TextStyle(color: Colors.white54)),
        ),
        FilledButton(
          style: FilledButton.styleFrom(
            backgroundColor: EmergeColors.neonTeal,
            foregroundColor: Colors.black,
          ),
          onPressed: () {
            final value = onSave(controller.text);
            if (value != null) Navigator.pop(context, value);
          },
          child: Text(actionLabel),
        ),
      ],
    );
  }
}
