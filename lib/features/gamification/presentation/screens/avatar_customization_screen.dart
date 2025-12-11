import 'package:emerge_app/core/theme/app_theme.dart';
import 'package:emerge_app/features/gamification/data/repositories/user_stats_repository.dart';
import 'package:emerge_app/features/gamification/domain/models/avatar.dart';
import 'package:emerge_app/features/gamification/presentation/providers/user_stats_providers.dart';
import 'package:emerge_app/features/gamification/presentation/widgets/avatar_display.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';
import 'package:go_router/go_router.dart';

class AvatarCustomizationScreen extends ConsumerStatefulWidget {
  const AvatarCustomizationScreen({super.key});

  @override
  ConsumerState<AvatarCustomizationScreen> createState() =>
      _AvatarCustomizationScreenState();
}

class _AvatarCustomizationScreenState
    extends ConsumerState<AvatarCustomizationScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  late Avatar _currentAvatar;
  bool _isInit = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_isInit) {
      final userProfile = ref.read(userStatsStreamProvider).valueOrNull;
      _currentAvatar = userProfile?.avatar ?? const Avatar();
      _isInit = true;
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _saveAvatar() async {
    final userProfile = ref.read(userStatsStreamProvider).valueOrNull;
    if (userProfile != null) {
      final updatedProfile = userProfile.copyWith(avatar: _currentAvatar);
      await ref.read(userStatsRepositoryProvider).saveUserStats(updatedProfile);
      if (mounted) context.pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundDark,
      appBar: AppBar(
        title: const Text('Customize Avatar'),
        backgroundColor: Colors.transparent,
        actions: [
          TextButton(
            onPressed: _saveAvatar,
            child: const Text(
              'Save',
              style: TextStyle(color: AppTheme.primary),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          // Preview Area
          Expanded(
            flex: 3,
            child: Container(
              margin: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppTheme.surfaceDark,
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.3),
                    blurRadius: 20,
                  ),
                ],
              ),
              child: Center(child: _buildAvatarPreview(_currentAvatar)),
            ),
          ),

          // Controls Area
          Expanded(
            flex: 4,
            child: Container(
              decoration: BoxDecoration(
                color: AppTheme.surfaceDark,
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(24),
                ),
              ),
              child: Column(
                children: [
                  TabBar(
                    controller: _tabController,
                    indicatorColor: AppTheme.primary,
                    labelColor: Colors.white,
                    unselectedLabelColor: Colors.grey,
                    tabs: const [
                      Tab(text: 'Body'),
                      Tab(text: 'Hair'),
                      Tab(text: 'Face'),
                      Tab(text: 'Outfit'),
                    ],
                  ),
                  Expanded(
                    child: TabBarView(
                      controller: _tabController,
                      children: [
                        _buildBodyTab(),
                        _buildHairTab(),
                        _buildFaceTab(),
                        _buildOutfitTab(),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAvatarPreview(Avatar avatar) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        AvatarDisplay(avatar: avatar, size: 250),
        const Gap(24),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            '${avatar.bodyType.name.toUpperCase()} • ${avatar.hairStyle.name.toUpperCase()}',
            style: const TextStyle(
              color: Colors.white70,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.2,
            ),
          ),
        ),
      ],
    );
  }

  Color _getSkinColor(AvatarSkinTone tone) {
    switch (tone) {
      case AvatarSkinTone.pale:
        return const Color(0xFFFFE0BD);
      case AvatarSkinTone.fair:
        return const Color(0xFFFFCD94);
      case AvatarSkinTone.tan:
        return const Color(0xFFEAC086);
      case AvatarSkinTone.olive:
        return const Color(0xFFFFAD60);
      case AvatarSkinTone.brown:
        return const Color(0xFF8D5524);
      case AvatarSkinTone.dark:
        return const Color(0xFF3B2219);
    }
  }

  Widget _buildBodyTab() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _buildSectionTitle('Body Type'),
        Wrap(
          spacing: 12,
          children: AvatarBodyType.values.map((type) {
            final isSelected = _currentAvatar.bodyType == type;
            return ChoiceChip(
              label: Text(type.name.toUpperCase()),
              selected: isSelected,
              onSelected: (selected) {
                if (selected) {
                  setState(() {
                    _currentAvatar = _currentAvatar.copyWith(bodyType: type);
                  });
                }
              },
              selectedColor: AppTheme.primary,
              labelStyle: TextStyle(
                color: isSelected ? AppTheme.backgroundDark : Colors.white,
                fontWeight: FontWeight.bold,
              ),
              backgroundColor: AppTheme.surfaceDark,
            );
          }).toList(),
        ),
        const Gap(24),
        _buildSectionTitle('Skin Tone'),
        Wrap(
          spacing: 16,
          runSpacing: 16,
          children: AvatarSkinTone.values.map((tone) {
            final isSelected = _currentAvatar.skinTone == tone;
            return GestureDetector(
              onTap: () {
                setState(() {
                  _currentAvatar = _currentAvatar.copyWith(skinTone: tone);
                });
              },
              child: Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: _getSkinColor(tone),
                  shape: BoxShape.circle,
                  border: isSelected
                      ? Border.all(color: AppTheme.primary, width: 4)
                      : Border.all(color: Colors.white24, width: 2),
                  boxShadow: isSelected
                      ? [
                          BoxShadow(
                            color: AppTheme.primary.withValues(alpha: 0.4),
                            blurRadius: 12,
                            spreadRadius: 2,
                          ),
                        ]
                      : [],
                ),
                child: isSelected
                    ? const Icon(Icons.check, color: Colors.white, size: 32)
                    : null,
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildHairTab() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _buildSectionTitle('Hair Style'),
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: AvatarHairStyle.values.map((style) {
            final isSelected = _currentAvatar.hairStyle == style;
            return ChoiceChip(
              label: Text(style.name.toUpperCase()),
              selected: isSelected,
              onSelected: (selected) {
                if (selected) {
                  setState(() {
                    _currentAvatar = _currentAvatar.copyWith(hairStyle: style);
                  });
                }
              },
              selectedColor: AppTheme.primary,
              labelStyle: TextStyle(
                color: isSelected ? AppTheme.backgroundDark : Colors.white,
                fontWeight: FontWeight.bold,
              ),
              backgroundColor: AppTheme.surfaceDark,
            );
          }).toList(),
        ),
        const Gap(24),
        _buildSectionTitle('Hair Color'),
        Wrap(
          spacing: 16,
          runSpacing: 16,
          children: AvatarHairColor.values.map((color) {
            final isSelected = _currentAvatar.hairColor == color;
            return GestureDetector(
              onTap: () {
                setState(() {
                  _currentAvatar = _currentAvatar.copyWith(hairColor: color);
                });
              },
              child: Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: _getHairColor(color),
                  shape: BoxShape.circle,
                  border: isSelected
                      ? Border.all(color: AppTheme.primary, width: 4)
                      : Border.all(color: Colors.white24, width: 2),
                  boxShadow: isSelected
                      ? [
                          BoxShadow(
                            color: AppTheme.primary.withValues(alpha: 0.4),
                            blurRadius: 12,
                            spreadRadius: 2,
                          ),
                        ]
                      : [],
                ),
                child: isSelected
                    ? const Icon(Icons.check, color: Colors.white, size: 32)
                    : null,
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Color _getHairColor(AvatarHairColor color) {
    switch (color) {
      case AvatarHairColor.black:
        return Colors.black;
      case AvatarHairColor.brown:
        return Colors.brown;
      case AvatarHairColor.blonde:
        return Colors.amber.shade200;
      case AvatarHairColor.red:
        return Colors.red.shade900;
      case AvatarHairColor.grey:
        return Colors.grey;
      case AvatarHairColor.white:
        return Colors.white;
      case AvatarHairColor.blue:
        return Colors.blue;
      case AvatarHairColor.pink:
        return Colors.pink;
    }
  }

  Widget _buildFaceTab() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _buildSectionTitle('Face Shape'),
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: AvatarFaceShape.values.map((shape) {
            final isSelected = _currentAvatar.faceShape == shape;
            return ChoiceChip(
              label: Text(shape.name.toUpperCase()),
              selected: isSelected,
              onSelected: (selected) {
                if (selected) {
                  setState(() {
                    _currentAvatar = _currentAvatar.copyWith(faceShape: shape);
                  });
                }
              },
              selectedColor: AppTheme.primary,
              labelStyle: TextStyle(
                color: isSelected ? AppTheme.backgroundDark : Colors.white,
                fontWeight: FontWeight.bold,
              ),
              backgroundColor: AppTheme.surfaceDark,
              avatar: isSelected
                  ? const Icon(
                      Icons.check,
                      size: 18,
                      color: AppTheme.backgroundDark,
                    )
                  : null,
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildOutfitTab() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _buildSectionTitle('Outfit Style'),
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: AvatarOutfit.values.map((outfit) {
            final isSelected = _currentAvatar.outfit == outfit;
            return ChoiceChip(
              label: Text(outfit.name.toUpperCase()),
              selected: isSelected,
              onSelected: (selected) {
                if (selected) {
                  setState(() {
                    _currentAvatar = _currentAvatar.copyWith(outfit: outfit);
                  });
                }
              },
              selectedColor: AppTheme.primary,
              labelStyle: TextStyle(
                color: isSelected ? AppTheme.backgroundDark : Colors.white,
                fontWeight: FontWeight.bold,
              ),
              backgroundColor: AppTheme.surfaceDark,
              avatar: isSelected
                  ? const Icon(
                      Icons.check,
                      size: 18,
                      color: AppTheme.backgroundDark,
                    )
                  : null,
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Text(
        title,
        style: const TextStyle(
          color: Colors.white70,
          fontSize: 16,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}
