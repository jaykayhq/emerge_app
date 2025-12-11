import 'package:emerge_app/core/presentation/widgets/growth_background.dart';
import 'package:emerge_app/core/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:go_router/go_router.dart';

class GatekeeperScreen extends StatefulWidget {
  const GatekeeperScreen({super.key});

  @override
  State<GatekeeperScreen> createState() => _GatekeeperScreenState();
}

class _GatekeeperScreenState extends State<GatekeeperScreen> {
  final _rewardController = TextEditingController();
  final _keyController = TextEditingController();
  bool _isLocked = false;

  @override
  void dispose() {
    _rewardController.dispose();
    _keyController.dispose();
    super.dispose();
  }

  void _toggleLock() {
    if (_rewardController.text.isEmpty || _keyController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter both a reward and a key.')),
      );
      return;
    }

    setState(() {
      _isLocked = !_isLocked;
    });
  }

  @override
  Widget build(BuildContext context) {
    return GrowthBackground(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        title: const Text('The Gatekeeper'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Lock your rewards behind your habits.',
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: AppTheme.textSecondaryDark,
                ),
                textAlign: TextAlign.center,
              ),
              const Gap(48),

              // Lock Status
              Center(
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 500),
                  padding: const EdgeInsets.all(32),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: _isLocked
                        ? Colors.red.withValues(alpha: 0.1)
                        : AppTheme.primary.withValues(alpha: 0.1),
                    border: Border.all(
                      color: _isLocked ? Colors.red : AppTheme.primary,
                      width: 2,
                    ),
                  ),
                  child: Icon(
                    _isLocked ? Icons.lock : Icons.lock_open,
                    size: 64,
                    color: _isLocked ? Colors.red : AppTheme.primary,
                  ),
                ),
              ),
              const Gap(48),

              // Form
              TextField(
                controller: _rewardController,
                enabled: !_isLocked,
                decoration: const InputDecoration(
                  labelText: 'The Reward (What you want)',
                  hintText: 'e.g., YouTube, Netflix, Video Games',
                  prefixIcon: Icon(Icons.card_giftcard),
                  border: OutlineInputBorder(),
                ),
              ),
              const Gap(24),
              TextField(
                controller: _keyController,
                enabled: !_isLocked,
                decoration: const InputDecoration(
                  labelText: 'The Key (What you must do)',
                  hintText: 'e.g., Read 10 pages, 10 Pushups',
                  prefixIcon: Icon(Icons.vpn_key),
                  border: OutlineInputBorder(),
                ),
              ),

              const Spacer(),

              SizedBox(
                height: 56,
                child: ElevatedButton(
                  onPressed: _toggleLock,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _isLocked ? Colors.red : AppTheme.primary,
                    foregroundColor: AppTheme.backgroundDark,
                  ),
                  child: Text(_isLocked ? 'Unlock' : 'Lock Reward'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
