import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:emerge_app/core/theme/app_theme.dart';
import 'package:emerge_app/core/theme/emerge_colors.dart';
import 'package:emerge_app/features/auth/presentation/providers/auth_providers.dart';
import 'package:emerge_app/features/gamification/presentation/providers/user_stats_providers.dart';
import 'package:emerge_app/features/habits/presentation/providers/habit_providers.dart';
import 'package:emerge_app/features/monetization/data/services/manage_premium_service.dart';
import 'package:emerge_app/features/monetization/presentation/providers/subscription_provider.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';
import 'package:go_router/go_router.dart';

/// Web-only "Premium since" tenure date from `users/{uid}.premium_since`.
/// Never blocks the status step — any failure degrades to no tenure line.
final _premiumSinceProvider = FutureProvider.autoDispose<DateTime?>((
  ref,
) async {
  if (!kIsWeb) return null;
  final user = ref.watch(authStateChangesProvider).value;
  if (user == null) return null;
  try {
    final firestore = ref.watch(firestoreProvider);
    final snap = await firestore.collection('users').doc(user.id).get();
    final raw = snap.data()?['premium_since'];
    if (raw is Timestamp) return raw.toDate();
    return DateTime.tryParse(raw.toString());
  } catch (e) {
    return null;
  }
});

/// Premium price string (`premiumPriceString` is async) — null-safe for the
/// status/recap lines; missing price degrades to no price mention.
final _premiumPriceProvider = FutureProvider.autoDispose<String?>((ref) {
  return ref.watch(monetizationRepositoryProvider).premiumPriceString;
});

/// Manage Premium — plan status + retention-focused cancel flow.
///
/// Entry: plan status view (the "Cancel subscription" entry). Then three
/// steps: (1) endowment recap + loss framing, (2) pause/save step,
/// (3) confirm. Web cancellation revokes the grant via the `managePremium`
/// callable (Paystack charges are one-time); Android cancellation opens the
/// Google Play manage page via RevenueCat's `managementURL` — the only
/// policy-compliant path. No iOS configuration (platform scope decision).
class ManagePremiumScreen extends ConsumerStatefulWidget {
  const ManagePremiumScreen({super.key});

  @override
  ConsumerState<ManagePremiumScreen> createState() =>
      _ManagePremiumScreenState();
}

enum _CancelStep { status, recap, pause, confirm, done }

class _ManagePremiumScreenState extends ConsumerState<ManagePremiumScreen> {
  _CancelStep _step = _CancelStep.status;
  bool _busy = false;

  Future<void> _continueCancelling() async {
    setState(() => _step = _CancelStep.pause);
  }

  /// Pause-step exit. On web the confirm step runs the callable; on native
  /// the Google Play manage page IS the confirmation surface (store policy —
  /// no in-app button disables auto-renew), so opening it is the action and
  /// the confirm step's inert CTA just points back at the store.
  Future<void> _cancelAnyway() async {
    if (kIsWeb) {
      setState(() => _step = _CancelStep.confirm);
      return;
    }
    setState(() => _busy = true);
    final messenger = ScaffoldMessenger.of(context);
    try {
      final result = await ref
          .read(monetizationRepositoryProvider)
          .openManageSubscription();
      if (!mounted) return;
      result.fold(
        (error) => messenger.showSnackBar(
          SnackBar(
            content: Text('Could not open subscription settings: $error'),
          ),
        ),
        (_) => setState(() => _step = _CancelStep.confirm),
      );
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  /// Confirm-step action. Web runs the callable; on native the Google Play
  /// manage page already opened and IS the cancellation surface (store policy
  /// — no in-app button disables auto-renew), so the CTA is disabled there.
  /// This branch is defensive only: never open the store a second time.
  Future<void> _confirmCancel() async {
    if (!kIsWeb) return;
    setState(() => _busy = true);
    final messenger = ScaffoldMessenger.of(context);
    try {
      final result = await ref.read(managePremiumServiceProvider).cancel();
      result.fold(
        (error) => messenger.showSnackBar(
          SnackBar(content: Text('Could not cancel premium: $error')),
        ),
        (_) {
          if (mounted) setState(() => _step = _CancelStep.done);
        },
      );
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _pauseInstead() async {
    setState(() => _busy = true);
    final messenger = ScaffoldMessenger.of(context);
    try {
      if (kIsWeb) {
        final result = await ref.read(managePremiumServiceProvider).pause();
        result.fold(
          (error) => messenger.showSnackBar(
            SnackBar(content: Text('Could not pause premium: $error')),
          ),
          (_) => messenger.showSnackBar(
            const SnackBar(
              content: Text(
                'Premium paused — your data stays safe. Resume anytime.',
              ),
            ),
          ),
        );
      } else {
        final result = await ref
            .read(monetizationRepositoryProvider)
            .openManageSubscription();
        result.fold(
          (error) => messenger.showSnackBar(
            SnackBar(content: Text('Could not open pause options: $error')),
          ),
          (_) => messenger.showSnackBar(
            const SnackBar(
              content: Text(
                'Google Play pause options opened — you can pause there.',
              ),
            ),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Manage Premium')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: switch (_step) {
            _CancelStep.status => _buildStatusStep(),
            _CancelStep.recap => _buildRecap(),
            _CancelStep.pause => _buildPauseStep(),
            _CancelStep.confirm => _buildConfirmStep(),
            _CancelStep.done => _buildDoneState(),
          },
        ),
      ),
    );
  }

  Widget _buildStatusStep() {
    final isPremium = ref.watch(isPremiumProvider).value ?? false;
    final premiumState = ref.watch(premiumStateProvider);
    final isPaused = premiumState?.isPaused ?? false;
    final price = ref.watch(_premiumPriceProvider).value;
    final premiumSince = ref.watch(_premiumSinceProvider).value;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          isPaused
              ? 'Premium paused'
              : (isPremium ? 'Premium is active' : 'Free plan'),
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
            color: AppTheme.textMainDark,
            fontWeight: FontWeight.bold,
          ),
        ),
        const Gap(8),
        if (isPaused)
          Text(
            premiumState?.premiumEndsAt != null
                ? 'Resumes on ${_formatDate(premiumState!.premiumEndsAt!)} — no charges while paused.'
                : 'No charges while paused. Your plan resumes automatically.',
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(color: AppTheme.textSecondaryDark),
          )
        else if (isPremium)
          Text(
            [
              if (price != null) 'Billed at $price',
              kIsWeb ? 'via Paystack' : 'via Google Play',
            ].join(' — '),
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(color: AppTheme.textSecondaryDark),
          )
        else
          Text(
            'Free plan — no charges, upgrade anytime',
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(color: AppTheme.textSecondaryDark),
          ),
        if (isPremium && !isPaused && premiumSince != null) ...[
          const Gap(8),
          Text(
            'Premium since ${_formatDate(premiumSince)}',
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(color: AppTheme.textSecondaryDark),
          ),
        ],
        const Gap(32),
        if (isPaused)
          // Paused: no cancel/pause flow — resuming is automatic, and the
          // pause CTA must not be re-offered to a paused user.
          Text(
            'Your plan resumes automatically — nothing to do.',
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(color: AppTheme.textSecondaryDark),
          )
        else if (isPremium)
          _PrimaryButton(
            label: 'Cancel subscription',
            onPressed: _busy
                ? null
                : () => setState(() => _step = _CancelStep.recap),
          )
        else
          _PrimaryButton(
            label: 'Go Premium',
            onPressed: () => context.push('/paywall'),
          ),
      ],
    );
  }

  Widget _buildRecap() {
    final streak = ref.watch(userStreakProvider).value ?? 0;
    final habits = ref.watch(habitsProvider).value ?? const [];
    final activeHabits = habits.where((h) => !h.isArchived).length;
    final isPremium = ref.watch(isPremiumProvider).value ?? false;
    final price = ref.watch(_premiumPriceProvider).value;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          "You're about to lose",
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
            color: AppTheme.textMainDark,
            fontWeight: FontWeight.bold,
          ),
        ),
        const Gap(8),
        Text(
          isPremium
              ? 'Your Premium plan${price != null ? ' ($price)' : ''} includes:'
              : 'Your Premium plan includes:',
          style: Theme.of(
            context,
          ).textTheme.bodyMedium?.copyWith(color: AppTheme.textSecondaryDark),
        ),
        const Gap(16),
        const _BenefitRow('Unlimited active habits'),
        const _BenefitRow('Your Pro World'),
        const _BenefitRow('Daily AI coaching'),
        const _BenefitRow('Ad-free experience'),
        const Gap(24),
        if (streak > 0 || activeHabits > 0) ...[
          Text(
            'What you have built',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: EmergeColors.teal,
              fontWeight: FontWeight.w600,
            ),
          ),
          const Gap(8),
          if (streak > 0)
            Text(
              'A $streak-day streak',
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(color: AppTheme.textMainDark),
            ),
          if (activeHabits > 0)
            Text(
              '$activeHabits active ${activeHabits == 1 ? 'habit' : 'habits'}',
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(color: AppTheme.textMainDark),
            ),
          const Gap(24),
        ],
        _PrimaryButton(label: 'Keep Premium', onPressed: () => context.pop()),
        const Gap(12),
        OutlinedButton(
          onPressed: _busy ? null : _continueCancelling,
          child: const Text('Continue cancelling'),
        ),
      ],
    );
  }

  Widget _buildPauseStep() {
    final isWeb = kIsWeb;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'Pause instead?',
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
            color: AppTheme.textMainDark,
            fontWeight: FontWeight.bold,
          ),
        ),
        const Gap(8),
        Text(
          isWeb
              ? 'Pause keeps everything safe — your streak, habits, and world. '
                    'Resume anytime within 30 days.'
              : 'Pause keeps everything safe — your streak, habits, and world. '
                    'Google Play pause options open next.',
          style: Theme.of(
            context,
          ).textTheme.bodyMedium?.copyWith(color: AppTheme.textSecondaryDark),
        ),
        const Gap(24),
        _PrimaryButton(
          label: isWeb ? 'Pause for 30 days' : 'Continue to pause options',
          onPressed: _busy ? null : _pauseInstead,
        ),
        const Gap(12),
        OutlinedButton(
          onPressed: _busy ? null : _cancelAnyway,
          child: const Text('Cancel anyway'),
        ),
        const Gap(12),
        TextButton(
          onPressed: () => setState(() => _step = _CancelStep.recap),
          child: const Text('Back'),
        ),
      ],
    );
  }

  Widget _buildConfirmStep() {
    final isWeb = kIsWeb;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'Cancel Premium',
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
            color: AppTheme.textMainDark,
            fontWeight: FontWeight.bold,
          ),
        ),
        const Gap(8),
        Text(
          isWeb
              ? 'Cancelling ends your premium access now. Your account stays free — your data and world are safe.'
              : 'Finish cancelling in Google Play. Your account stays free — your data and world are safe.',
          style: Theme.of(
            context,
          ).textTheme.bodyMedium?.copyWith(color: AppTheme.textSecondaryDark),
        ),
        const Gap(24),
        _PrimaryButton(
          // On native the store page already opened — the CTA just points back
          // at it. Inert: Google Play is the only cancellation surface.
          label: isWeb ? 'Confirm cancellation' : 'Finish in Google Play',
          onPressed: isWeb ? (_busy ? null : _confirmCancel) : null,
        ),
        const Gap(12),
        TextButton(
          onPressed: () => setState(() => _step = _CancelStep.pause),
          child: const Text('Back'),
        ),
      ],
    );
  }

  Widget _buildDoneState() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Icon(Icons.check_circle, size: 64, color: EmergeColors.teal),
        const Gap(16),
        Text(
          'Premium cancelled',
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
            color: AppTheme.textMainDark,
            fontWeight: FontWeight.bold,
          ),
          textAlign: TextAlign.center,
        ),
        const Gap(8),
        Text(
          'Your account stays free — your data and world are safe.',
          style: Theme.of(
            context,
          ).textTheme.bodyMedium?.copyWith(color: AppTheme.textSecondaryDark),
          textAlign: TextAlign.center,
        ),
        const Gap(24),
        _PrimaryButton(label: 'Done', onPressed: () => context.pop()),
      ],
    );
  }

  /// yyyy-MM-dd — no intl dependency needed for a single status line.
  String _formatDate(DateTime date) {
    final month = date.month.toString().padLeft(2, '0');
    final day = date.day.toString().padLeft(2, '0');
    return '${date.year}-$month-$day';
  }
}

class _BenefitRow extends StatelessWidget {
  const _BenefitRow(this.label);
  final String label;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          const Icon(Icons.close, size: 16, color: EmergeColors.teal),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              label,
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(color: AppTheme.textMainDark),
            ),
          ),
        ],
      ),
    );
  }
}

class _PrimaryButton extends StatelessWidget {
  const _PrimaryButton({required this.label, required this.onPressed});
  final String label;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 50,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: EmergeColors.teal,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: Text(label, style: const TextStyle(fontWeight: FontWeight.bold)),
      ),
    );
  }
}
