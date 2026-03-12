import 'package:emerge_app/features/auth/presentation/providers/auth_providers.dart';
import 'package:emerge_app/features/social/presentation/providers/friend_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';

import 'package:emerge_app/core/presentation/widgets/emerge_branding.dart';

class InviteCodeDialog extends ConsumerStatefulWidget {
  const InviteCodeDialog({super.key});

  @override
  ConsumerState<InviteCodeDialog> createState() => _InviteCodeDialogState();
}

class _InviteCodeDialogState extends ConsumerState<InviteCodeDialog> {
  final TextEditingController _codeController = TextEditingController();
  bool _isLoading = false;
  String? _generatedCode;
  String? _errorMessage;

  @override
  void dispose() {
    _codeController.dispose();
    super.dispose();
  }

  Future<void> _generateCode() async {
    final user = ref.read(authStateChangesProvider).value;
    if (user == null) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final code = await ref
          .read(friendRepositoryProvider)
          .generateInviteCode(user.id);
      setState(() {
        _generatedCode = code;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _redeemCode() async {
    final code = _codeController.text.trim();
    if (code.isEmpty) return;

    final user = ref.read(authStateChangesProvider).value;
    if (user == null) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      await ref.read(friendRepositoryProvider).redeemInviteCode(user.id, code);

      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Partnership established!'),
            backgroundColor: EmergeColors.teal,
          ),
        );
      }
    } catch (e) {
      setState(() {
        _errorMessage = e.toString().replaceAll('Exception: ', '');
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 24),
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: const Color(0xFF1A1A2E), // Deep cosmic background
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: EmergeColors.glassBorder),
          boxShadow: [
            BoxShadow(
              color: EmergeColors.teal.withValues(alpha: 0.2),
              blurRadius: 30,
              spreadRadius: 5,
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Icon
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: EmergeColors.teal.withValues(alpha: 0.1),
                shape: BoxShape.circle,
                border: Border.all(
                  color: EmergeColors.teal.withValues(alpha: 0.3),
                ),
              ),
              child: const Icon(
                Icons.people_alt_outlined,
                size: 32,
                color: EmergeColors.teal,
              ),
            ),
            const Gap(16),

            const Text(
              'Form a Partnership',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Colors.white,
                letterSpacing: 0.5,
              ),
            ),
            const Gap(8),
            Text(
              'Connect with another traveler on the same path. Only one can walk beside you.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: Colors.white.withValues(alpha: 0.7),
              ),
            ),
            const Gap(24),

            if (_errorMessage != null)
              Container(
                margin: const EdgeInsets.only(bottom: 16),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.red.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.red.withValues(alpha: 0.3)),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.error_outline,
                      color: Colors.red,
                      size: 16,
                    ),
                    const Gap(8),
                    Expanded(
                      child: Text(
                        _errorMessage!,
                        style: const TextStyle(color: Colors.red, fontSize: 12),
                      ),
                    ),
                  ],
                ),
              ),

            // Tabs/Toggle for Invite vs Redeem
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const Text(
                        'HAVE A CODE?',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: EmergeColors.teal,
                          letterSpacing: 1,
                        ),
                      ),
                      const Gap(8),
                      TextField(
                        controller: _codeController,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          letterSpacing: 4,
                          fontWeight: FontWeight.bold,
                        ),
                        textCapitalization: TextCapitalization.characters,
                        inputFormatters: [LengthLimitingTextInputFormatter(6)],
                        decoration: InputDecoration(
                          hintText: 'XXXXXX',
                          hintStyle: TextStyle(
                            color: Colors.white.withValues(alpha: 0.2),
                          ),
                          filled: true,
                          fillColor: Colors.black.withValues(alpha: 0.3),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(
                              color: EmergeColors.glassBorder,
                            ),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(
                              color: EmergeColors.teal,
                            ),
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 16,
                          ),
                        ),
                        onChanged: (val) {
                          _codeController.value = TextEditingValue(
                            text: val.toUpperCase(),
                            selection: _codeController.selection,
                          );
                        },
                      ),
                      const Gap(16),
                      ElevatedButton(
                        onPressed: _isLoading ? null : _redeemCode,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: EmergeColors.teal,
                          foregroundColor: Colors.black,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 0,
                        ),
                        child: _isLoading && _codeController.text.isNotEmpty
                            ? const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation(
                                    Colors.black,
                                  ),
                                ),
                              )
                            : const Text(
                                'Redeem Code',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 15,
                                  letterSpacing: 0.5,
                                ),
                              ),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            const Gap(24),
            Row(
              children: [
                Expanded(child: Divider(color: EmergeColors.glassBorder)),
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 12),
                  child: Text(
                    'OR',
                    style: TextStyle(
                      color: Colors.white54,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                Expanded(child: Divider(color: EmergeColors.glassBorder)),
              ],
            ),
            const Gap(24),

            // Generation Section
            if (_generatedCode == null)
              OutlinedButton.icon(
                onPressed: _isLoading ? null : _generateCode,
                icon: _isLoading && _codeController.text.isEmpty
                    ? const SizedBox(
                        height: 16,
                        width: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation(
                            EmergeColors.coral,
                          ),
                        ),
                      )
                    : const Icon(Icons.generating_tokens_outlined, size: 18),
                label: const Text('Generate My Code'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: EmergeColors.coral,
                  side: const BorderSide(color: EmergeColors.coral),
                  padding: const EdgeInsets.symmetric(
                    vertical: 16,
                    horizontal: 24,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              )
            else
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: EmergeColors.coral.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: EmergeColors.coral.withValues(alpha: 0.3),
                  ),
                ),
                child: Column(
                  children: [
                    const Text(
                      'YOUR INVITE CODE',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: EmergeColors.coral,
                        letterSpacing: 1,
                      ),
                    ),
                    const Gap(8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          _generatedCode!,
                          style: const TextStyle(
                            fontSize: 32,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                            letterSpacing: 8,
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.copy, color: Colors.white70),
                          onPressed: () {
                            Clipboard.setData(
                              ClipboardData(text: _generatedCode!),
                            );
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Code copied to clipboard'),
                                behavior: SnackBarBehavior.floating,
                                duration: Duration(seconds: 2),
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                    const Gap(4),
                    Text(
                      'Share this code. It works for one use only.',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.white.withValues(alpha: 0.6),
                      ),
                    ),
                  ],
                ),
              ),

            const Gap(16),
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text(
                'Cancel',
                style: TextStyle(color: Colors.white54),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
