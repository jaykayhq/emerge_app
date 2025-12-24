import 'package:emerge_app/core/presentation/widgets/emerge_branding.dart';
import 'package:emerge_app/core/theme/app_theme.dart';
import 'package:emerge_app/features/gamification/data/repositories/user_stats_repository.dart';
import 'package:emerge_app/features/gamification/data/services/avatar_configuration_service.dart';
import 'package:emerge_app/features/gamification/domain/models/avatar.dart';
import 'package:emerge_app/features/gamification/domain/models/enhanced_avatar.dart';
import 'package:emerge_app/features/gamification/presentation/providers/user_stats_providers.dart';
import 'package:emerge_app/features/gamification/presentation/screens/avatar_creator_webview.dart';
import 'package:emerge_app/features/gamification/presentation/widgets/enhanced_avatar_display.dart';
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
  late EnhancedAvatar _currentAvatar;
  bool _isInit = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 6, vsync: this);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_isInit) {
      // For backward compatibility, we'll create an enhanced avatar from the basic avatar
      // In a real implementation, you'd load the enhanced avatar directly
      _currentAvatar = _createEnhancedAvatarFromBasic();
      _isInit = true;
    }
  }

  // Create an enhanced avatar from the basic avatar for backward compatibility
  EnhancedAvatar _createEnhancedAvatarFromBasic() {
    final userProfile = ref.read(userStatsStreamProvider).valueOrNull;
    final basicAvatar = userProfile?.avatar;

    if (basicAvatar != null) {
      // Map basic avatar properties to enhanced avatar properties
      EnhancedAvatarBodyType enhancedBodyType =
          EnhancedAvatarBodyType.masculine;
      switch (basicAvatar.bodyType) {
        case AvatarBodyType.masculine:
          enhancedBodyType = EnhancedAvatarBodyType.masculine;
          break;
        case AvatarBodyType.feminine:
          enhancedBodyType = EnhancedAvatarBodyType.feminine;
          break;
      }

      EnhancedAvatarSkinTone enhancedSkinTone = EnhancedAvatarSkinTone.fair;
      switch (basicAvatar.skinTone) {
        case AvatarSkinTone.pale:
          enhancedSkinTone = EnhancedAvatarSkinTone.pale;
          break;
        case AvatarSkinTone.fair:
          enhancedSkinTone = EnhancedAvatarSkinTone.fair;
          break;
        case AvatarSkinTone.tan:
          enhancedSkinTone = EnhancedAvatarSkinTone.tan;
          break;
        case AvatarSkinTone.olive:
          enhancedSkinTone = EnhancedAvatarSkinTone.olive;
          break;
        case AvatarSkinTone.brown:
          enhancedSkinTone = EnhancedAvatarSkinTone.brown;
          break;
        case AvatarSkinTone.dark:
          enhancedSkinTone = EnhancedAvatarSkinTone.dark;
          break;
      }

      EnhancedAvatarHairStyle enhancedHairStyle = EnhancedAvatarHairStyle.short;
      switch (basicAvatar.hairStyle) {
        case AvatarHairStyle.short:
          enhancedHairStyle = EnhancedAvatarHairStyle.short;
          break;
        case AvatarHairStyle.long:
          enhancedHairStyle = EnhancedAvatarHairStyle.long;
          break;
        case AvatarHairStyle.buzz:
          enhancedHairStyle = EnhancedAvatarHairStyle.buzz;
          break;
        case AvatarHairStyle.bald:
          enhancedHairStyle = EnhancedAvatarHairStyle.bald;
          break;
        case AvatarHairStyle.pony:
          enhancedHairStyle = EnhancedAvatarHairStyle.pony;
          break;
        case AvatarHairStyle.bun:
          enhancedHairStyle = EnhancedAvatarHairStyle.bun;
          break;
      }

      EnhancedAvatarHairColor enhancedHairColor = EnhancedAvatarHairColor.brown;
      switch (basicAvatar.hairColor) {
        case AvatarHairColor.black:
          enhancedHairColor = EnhancedAvatarHairColor.black;
          break;
        case AvatarHairColor.brown:
          enhancedHairColor = EnhancedAvatarHairColor.brown;
          break;
        case AvatarHairColor.blonde:
          enhancedHairColor = EnhancedAvatarHairColor.blonde;
          break;
        case AvatarHairColor.red:
          enhancedHairColor = EnhancedAvatarHairColor.red;
          break;
        case AvatarHairColor.grey:
          enhancedHairColor = EnhancedAvatarHairColor.grey;
          break;
        case AvatarHairColor.white:
          enhancedHairColor = EnhancedAvatarHairColor.white;
          break;
        case AvatarHairColor.blue:
          enhancedHairColor = EnhancedAvatarHairColor.blue;
          break;
        case AvatarHairColor.pink:
          enhancedHairColor = EnhancedAvatarHairColor.pink;
          break;
      }

      EnhancedAvatarFaceShape enhancedFaceShape =
          EnhancedAvatarFaceShape.square;
      switch (basicAvatar.faceShape) {
        case AvatarFaceShape.round:
          enhancedFaceShape = EnhancedAvatarFaceShape.round;
          break;
        case AvatarFaceShape.square:
          enhancedFaceShape = EnhancedAvatarFaceShape.square;
          break;
        case AvatarFaceShape.oval:
          enhancedFaceShape = EnhancedAvatarFaceShape.oval;
          break;
      }

      EnhancedAvatarOutfit enhancedOutfit = EnhancedAvatarOutfit.casual;
      switch (basicAvatar.outfit) {
        case AvatarOutfit.casual:
          enhancedOutfit = EnhancedAvatarOutfit.casual;
          break;
        case AvatarOutfit.athletic:
          enhancedOutfit = EnhancedAvatarOutfit.athletic;
          break;
        case AvatarOutfit.robe:
          enhancedOutfit = EnhancedAvatarOutfit.robe;
          break;
        case AvatarOutfit.armor:
          enhancedOutfit = EnhancedAvatarOutfit.armor;
          break;
        case AvatarOutfit.suit:
          enhancedOutfit = EnhancedAvatarOutfit.suit;
          break;
      }

      return EnhancedAvatar(
        modelUrl: basicAvatar.modelUrl,
        bodyType: enhancedBodyType,
        skinTone: enhancedSkinTone,
        hairStyle: enhancedHairStyle,
        hairColor: enhancedHairColor,
        faceShape: enhancedFaceShape,
        outfit: enhancedOutfit,
        expression: AvatarExpression.neutral,
        pose: AvatarPose.standing,
        bodyScale: 1.0,
        headScale: 1.0,
        limbScale: 1.0,
        accessories: const [],
        outfitPrimaryColor: const Color(0xFF0000FF), // Default blue
        outfitSecondaryColor: const Color(0xFF000000), // Default black
        hairLength: 1.0,
        facialHairGrowth: 0.0,
        isAnimated: false,
        animationSpeed: 1.0,
      );
    }

    // Return default enhanced avatar if no basic avatar exists
    return const EnhancedAvatar();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _saveAvatar() async {
    final userProfile = ref.read(userStatsStreamProvider).valueOrNull;
    if (userProfile != null) {
      // For backward compatibility, we create a basic avatar with the most important properties
      // and save the full enhanced avatar to a separate service
      final updatedProfile = userProfile.copyWith(
        avatar: _createBasicAvatarFromEnhanced(),
      );
      await ref.read(userStatsRepositoryProvider).saveUserStats(updatedProfile);

      // Also save the enhanced avatar separately using the new service
      // In a real implementation, you'd probably inject this service
      final configService = AvatarConfigurationService();
      await configService.saveAvatarConfiguration(_currentAvatar);

      if (mounted) context.pop();
    }
  }

  // Create a basic avatar from the enhanced avatar for backward compatibility
  Avatar _createBasicAvatarFromEnhanced() {
    AvatarBodyType basicBodyType = AvatarBodyType.masculine;
    switch (_currentAvatar.bodyType) {
      case EnhancedAvatarBodyType.masculine:
        basicBodyType = AvatarBodyType.masculine;
        break;
      case EnhancedAvatarBodyType.feminine:
        basicBodyType = AvatarBodyType.feminine;
        break;
      default:
        basicBodyType = AvatarBodyType.masculine;
        break;
    }

    AvatarSkinTone basicSkinTone = AvatarSkinTone.fair;
    switch (_currentAvatar.skinTone) {
      case EnhancedAvatarSkinTone.pale:
        basicSkinTone = AvatarSkinTone.pale;
        break;
      case EnhancedAvatarSkinTone.fair:
        basicSkinTone = AvatarSkinTone.fair;
        break;
      case EnhancedAvatarSkinTone.tan:
        basicSkinTone = AvatarSkinTone.tan;
        break;
      case EnhancedAvatarSkinTone.olive:
        basicSkinTone = AvatarSkinTone.olive;
        break;
      case EnhancedAvatarSkinTone.brown:
        basicSkinTone = AvatarSkinTone.brown;
        break;
      case EnhancedAvatarSkinTone.dark:
        basicSkinTone = AvatarSkinTone.dark;
        break;
      default:
        basicSkinTone = AvatarSkinTone.fair;
        break;
    }

    AvatarHairStyle basicHairStyle = AvatarHairStyle.short;
    switch (_currentAvatar.hairStyle) {
      case EnhancedAvatarHairStyle.short:
        basicHairStyle = AvatarHairStyle.short;
        break;
      case EnhancedAvatarHairStyle.long:
        basicHairStyle = AvatarHairStyle.long;
        break;
      case EnhancedAvatarHairStyle.buzz:
        basicHairStyle = AvatarHairStyle.buzz;
        break;
      case EnhancedAvatarHairStyle.bald:
        basicHairStyle = AvatarHairStyle.bald;
        break;
      case EnhancedAvatarHairStyle.pony:
        basicHairStyle = AvatarHairStyle.pony;
        break;
      case EnhancedAvatarHairStyle.bun:
        basicHairStyle = AvatarHairStyle.bun;
        break;
      default:
        basicHairStyle = AvatarHairStyle.short;
        break;
    }

    AvatarHairColor basicHairColor = AvatarHairColor.brown;
    switch (_currentAvatar.hairColor) {
      case EnhancedAvatarHairColor.black:
        basicHairColor = AvatarHairColor.black;
        break;
      case EnhancedAvatarHairColor.brown:
        basicHairColor = AvatarHairColor.brown;
        break;
      case EnhancedAvatarHairColor.blonde:
        basicHairColor = AvatarHairColor.blonde;
        break;
      case EnhancedAvatarHairColor.red:
        basicHairColor = AvatarHairColor.red;
        break;
      case EnhancedAvatarHairColor.grey:
        basicHairColor = AvatarHairColor.grey;
        break;
      case EnhancedAvatarHairColor.white:
        basicHairColor = AvatarHairColor.white;
        break;
      case EnhancedAvatarHairColor.blue:
        basicHairColor = AvatarHairColor.blue;
        break;
      case EnhancedAvatarHairColor.pink:
        basicHairColor = AvatarHairColor.pink;
        break;
      default:
        basicHairColor = AvatarHairColor.brown;
        break;
    }

    AvatarFaceShape basicFaceShape = AvatarFaceShape.square;
    switch (_currentAvatar.faceShape) {
      case EnhancedAvatarFaceShape.round:
        basicFaceShape = AvatarFaceShape.round;
        break;
      case EnhancedAvatarFaceShape.square:
        basicFaceShape = AvatarFaceShape.square;
        break;
      case EnhancedAvatarFaceShape.oval:
        basicFaceShape = AvatarFaceShape.oval;
        break;
      default:
        basicFaceShape = AvatarFaceShape.square;
        break;
    }

    AvatarOutfit basicOutfit = AvatarOutfit.casual;
    switch (_currentAvatar.outfit) {
      case EnhancedAvatarOutfit.casual:
        basicOutfit = AvatarOutfit.casual;
        break;
      case EnhancedAvatarOutfit.athletic:
        basicOutfit = AvatarOutfit.athletic;
        break;
      case EnhancedAvatarOutfit.robe:
        basicOutfit = AvatarOutfit.robe;
        break;
      case EnhancedAvatarOutfit.armor:
        basicOutfit = AvatarOutfit.armor;
        break;
      case EnhancedAvatarOutfit.suit:
        basicOutfit = AvatarOutfit.suit;
        break;
      default:
        basicOutfit = AvatarOutfit.casual;
        break;
    }

    return Avatar(
      modelUrl: _currentAvatar.modelUrl,
      bodyType: basicBodyType,
      skinTone: basicSkinTone,
      hairStyle: basicHairStyle,
      hairColor: basicHairColor,
      faceShape: basicFaceShape,
      outfit: basicOutfit,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: EmergeColors.background,
      appBar: AppBar(
        title: Text(
          'Customize Avatar',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            color: AppTheme.textMainDark,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppTheme.textMainDark),
          onPressed: () => context.pop(),
        ),
        actions: [
          TextButton(
            onPressed: () async {
              final url = await Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => const AvatarCreatorWebView(),
                ),
              );
              if (url != null && url is String) {
                setState(() {
                  _currentAvatar = _currentAvatar.copyWith(modelUrl: url);
                });
              }
            },
            child: const Text(
              'Create 3D',
              style: TextStyle(
                color: EmergeColors.teal,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          TextButton(
            onPressed: _saveAvatar,
            child: const Text(
              'Save',
              style: TextStyle(
                color: EmergeColors.teal,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
      body: Stack(
        children: [
          // Background
          const Positioned.fill(child: HexMeshBackground()),

          Column(
            children: [
              // Preview Area
              Expanded(
                flex: 3,
                child: Container(
                  margin: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppTheme.surfaceDark.withValues(alpha: 0.5),
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(color: EmergeColors.hexLine),
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
                    border: Border.all(color: EmergeColors.hexLine),
                  ),
                  child: Column(
                    children: [
                      TabBar(
                        controller: _tabController,
                        indicatorColor: EmergeColors.teal,
                        labelColor: EmergeColors.teal,
                        unselectedLabelColor: AppTheme.textSecondaryDark,
                        tabs: const [
                          Tab(text: 'Body'),
                          Tab(text: 'Hair'),
                          Tab(text: 'Face'),
                          Tab(text: 'Outfit'),
                          Tab(text: 'Accessories'),
                          Tab(text: 'Advanced'),
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
                            _buildAccessoriesTab(),
                            _buildAdvancedTab(),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAvatarPreview(EnhancedAvatar avatar) {
    return LayoutBuilder(
      builder: (context, constraints) {
        // Calculate dynamic size based on available height - more conservative clamping
        final availableHeight = constraints.maxHeight;
        final size = (availableHeight * 0.65).clamp(80.0, 220.0);
        final showLabel = availableHeight > 200;

        return Column(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            EnhancedAvatarDisplay(
              avatar: avatar,
              size: size,
              animate: avatar.isAnimated,
            ),
            if (showLabel) ...[
              const Gap(12),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '${avatar.bodyType.name.toUpperCase()} • ${avatar.hairStyle.name.toUpperCase()}',
                  style: const TextStyle(
                    color: Colors.white70,
                    fontWeight: FontWeight.w600,
                    fontSize: 12,
                    letterSpacing: 1.2,
                  ),
                ),
              ),
            ],
          ],
        );
      },
    );
  }

  Color _getSkinColor(EnhancedAvatarSkinTone tone) {
    switch (tone) {
      case EnhancedAvatarSkinTone.pale:
        return const Color(0xFFFFE0BD);
      case EnhancedAvatarSkinTone.fair:
        return const Color(0xFFFFCD94);
      case EnhancedAvatarSkinTone.tan:
        return const Color(0xFFEAC086);
      case EnhancedAvatarSkinTone.olive:
        return const Color(0xFFFFAD60);
      case EnhancedAvatarSkinTone.brown:
        return const Color(0xFF8D5524);
      case EnhancedAvatarSkinTone.dark:
        return const Color(0xFF3B2219);
      case EnhancedAvatarSkinTone.lightBeige:
        return const Color(0xFFF1C27D);
      case EnhancedAvatarSkinTone.mediumBeige:
        return const Color(0xFFE0AC69);
      case EnhancedAvatarSkinTone.darkBeige:
        return const Color(0xFFC68642);
      case EnhancedAvatarSkinTone.lightWarm:
        return const Color(0xFF8D5524);
      case EnhancedAvatarSkinTone.mediumWarm:
        return const Color(0xFF6B4423);
      case EnhancedAvatarSkinTone.darkWarm:
        return const Color(0xFF4D291C);
      case EnhancedAvatarSkinTone.lightCool:
        return const Color(0xFFCA8546);
      case EnhancedAvatarSkinTone.mediumCool:
        return const Color(0xFFA46A29);
      case EnhancedAvatarSkinTone.darkCool:
        return const Color(0xFF704214);
    }
  }

  Widget _buildBodyTab() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _buildSectionTitle('Body Type'),
        Wrap(
          spacing: 12,
          children: EnhancedAvatarBodyType.values.map((type) {
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
              selectedColor: EmergeColors.teal,
              labelStyle: TextStyle(
                color: isSelected ? Colors.black : AppTheme.textSecondaryDark,
                fontWeight: FontWeight.bold,
              ),
              backgroundColor: AppTheme.surfaceDark.withValues(alpha: 0.5),
              side: BorderSide(
                color: isSelected ? EmergeColors.teal : EmergeColors.hexLine,
              ),
            );
          }).toList(),
        ),
        const Gap(24),
        _buildSectionTitle('Skin Tone'),
        Wrap(
          spacing: 16,
          runSpacing: 16,
          children: EnhancedAvatarSkinTone.values.map((tone) {
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
                      ? Border.all(color: EmergeColors.teal, width: 4)
                      : Border.all(color: Colors.white24, width: 2),
                  boxShadow: isSelected
                      ? [
                          BoxShadow(
                            color: EmergeColors.teal.withValues(alpha: 0.4),
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
        const Gap(24),
        _buildSectionTitle('Body Proportions'),
        _buildSlider(
          label: 'Body Scale',
          value: _currentAvatar.bodyScale,
          min: 0.5,
          max: 1.5,
          onChanged: (value) {
            setState(() {
              _currentAvatar = _currentAvatar.copyWith(bodyScale: value);
            });
          },
        ),
        _buildSlider(
          label: 'Head Scale',
          value: _currentAvatar.headScale,
          min: 0.7,
          max: 1.3,
          onChanged: (value) {
            setState(() {
              _currentAvatar = _currentAvatar.copyWith(headScale: value);
            });
          },
        ),
        _buildSlider(
          label: 'Limb Scale',
          value: _currentAvatar.limbScale,
          min: 0.5,
          max: 1.5,
          onChanged: (value) {
            setState(() {
              _currentAvatar = _currentAvatar.copyWith(limbScale: value);
            });
          },
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
          children: EnhancedAvatarHairStyle.values.map((style) {
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
              selectedColor: EmergeColors.teal,
              labelStyle: TextStyle(
                color: isSelected ? Colors.black : AppTheme.textSecondaryDark,
                fontWeight: FontWeight.bold,
              ),
              backgroundColor: AppTheme.surfaceDark.withValues(alpha: 0.5),
              side: BorderSide(
                color: isSelected ? EmergeColors.teal : EmergeColors.hexLine,
              ),
            );
          }).toList(),
        ),
        const Gap(24),
        _buildSectionTitle('Hair Color'),
        Wrap(
          spacing: 16,
          runSpacing: 16,
          children: EnhancedAvatarHairColor.values.map((color) {
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
                      ? Border.all(color: EmergeColors.teal, width: 4)
                      : Border.all(color: Colors.white24, width: 2),
                  boxShadow: isSelected
                      ? [
                          BoxShadow(
                            color: EmergeColors.teal.withValues(alpha: 0.4),
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
        const Gap(24),
        _buildSectionTitle('Hair Length'),
        _buildSlider(
          label: 'Hair Length',
          value: _currentAvatar.hairLength,
          min: 0.3,
          max: 1.5,
          onChanged: (value) {
            setState(() {
              _currentAvatar = _currentAvatar.copyWith(hairLength: value);
            });
          },
        ),
      ],
    );
  }

  Color _getHairColor(EnhancedAvatarHairColor color) {
    switch (color) {
      case EnhancedAvatarHairColor.black:
        return Colors.black;
      case EnhancedAvatarHairColor.brown:
        return Colors.brown;
      case EnhancedAvatarHairColor.blonde:
        return Colors.amber.shade200;
      case EnhancedAvatarHairColor.red:
        return Colors.red.shade900;
      case EnhancedAvatarHairColor.grey:
        return Colors.grey;
      case EnhancedAvatarHairColor.white:
        return Colors.white;
      case EnhancedAvatarHairColor.blue:
        return Colors.blue;
      case EnhancedAvatarHairColor.pink:
        return Colors.pink;
      case EnhancedAvatarHairColor.purple:
        return Colors.purple;
      case EnhancedAvatarHairColor.green:
        return Colors.green;
      case EnhancedAvatarHairColor.orange:
        return Colors.orange;
      case EnhancedAvatarHairColor.auburn:
        return Colors.red.shade700;
      case EnhancedAvatarHairColor.chestnut:
        return const Color(0xFFD2691E);
      case EnhancedAvatarHairColor.golden:
        return Colors.amber.shade300;
      case EnhancedAvatarHairColor.silver:
        return Colors.grey.shade300;
      case EnhancedAvatarHairColor.rainbow:
        return Colors.purple; // Will be handled specially in the painter
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
          children: EnhancedAvatarFaceShape.values.map((shape) {
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
              selectedColor: EmergeColors.teal,
              labelStyle: TextStyle(
                color: isSelected ? Colors.black : AppTheme.textSecondaryDark,
                fontWeight: FontWeight.bold,
              ),
              backgroundColor: AppTheme.surfaceDark.withValues(alpha: 0.5),
              side: BorderSide(
                color: isSelected ? EmergeColors.teal : EmergeColors.hexLine,
              ),
              avatar: isSelected
                  ? const Icon(Icons.check, size: 18, color: Colors.black)
                  : null,
            );
          }).toList(),
        ),
        const Gap(24),
        _buildSectionTitle('Expression'),
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: AvatarExpression.values.map((expression) {
            final isSelected = _currentAvatar.expression == expression;
            return ChoiceChip(
              label: Text(expression.name.toUpperCase()),
              selected: isSelected,
              onSelected: (selected) {
                if (selected) {
                  setState(() {
                    _currentAvatar = _currentAvatar.copyWith(
                      expression: expression,
                    );
                  });
                }
              },
              selectedColor: EmergeColors.teal,
              labelStyle: TextStyle(
                color: isSelected ? Colors.black : AppTheme.textSecondaryDark,
                fontWeight: FontWeight.bold,
              ),
              backgroundColor: AppTheme.surfaceDark.withValues(alpha: 0.5),
              side: BorderSide(
                color: isSelected ? EmergeColors.teal : EmergeColors.hexLine,
              ),
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
          children: EnhancedAvatarOutfit.values.map((outfit) {
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
              selectedColor: EmergeColors.teal,
              labelStyle: TextStyle(
                color: isSelected ? Colors.black : AppTheme.textSecondaryDark,
                fontWeight: FontWeight.bold,
              ),
              backgroundColor: AppTheme.surfaceDark.withValues(alpha: 0.5),
              side: BorderSide(
                color: isSelected ? EmergeColors.teal : EmergeColors.hexLine,
              ),
              avatar: isSelected
                  ? const Icon(Icons.check, size: 18, color: Colors.black)
                  : null,
            );
          }).toList(),
        ),
        const Gap(24),
        _buildSectionTitle('Outfit Colors'),
        Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Primary Color',
                    style: TextStyle(
                      color: AppTheme.textSecondaryDark,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Gap(8),
                  GestureDetector(
                    onTap: () => _showColorPicker(
                      context,
                      _currentAvatar.outfitPrimaryColor,
                      (color) {
                        setState(() {
                          _currentAvatar = _currentAvatar.copyWith(
                            outfitPrimaryColor: color,
                          );
                        });
                      },
                    ),
                    child: Container(
                      height: 40,
                      decoration: BoxDecoration(
                        color: _currentAvatar.outfitPrimaryColor,
                        border: Border.all(color: Colors.white24, width: 2),
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const Gap(16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Secondary Color',
                    style: TextStyle(
                      color: AppTheme.textSecondaryDark,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Gap(8),
                  GestureDetector(
                    onTap: () => _showColorPicker(
                      context,
                      _currentAvatar.outfitSecondaryColor,
                      (color) {
                        setState(() {
                          _currentAvatar = _currentAvatar.copyWith(
                            outfitSecondaryColor: color,
                          );
                        });
                      },
                    ),
                    child: Container(
                      height: 40,
                      decoration: BoxDecoration(
                        color: _currentAvatar.outfitSecondaryColor,
                        border: Border.all(color: Colors.white24, width: 2),
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildAccessoriesTab() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _buildSectionTitle('Accessories'),
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: AvatarAccessory.values
              .where((accessory) => accessory != AvatarAccessory.none)
              .map((accessory) {
                final hasAccessory = _currentAvatar.accessories.contains(
                  accessory,
                );
                return FilterChip(
                  label: Text(accessory.name.toUpperCase()),
                  selected: hasAccessory,
                  onSelected: (selected) {
                    List<AvatarAccessory> newAccessories;
                    if (selected) {
                      newAccessories = [
                        ..._currentAvatar.accessories,
                        if (!_currentAvatar.accessories.contains(accessory))
                          accessory,
                      ];
                    } else {
                      newAccessories = [
                        ..._currentAvatar.accessories..remove(accessory),
                      ];
                    }
                    setState(() {
                      _currentAvatar = _currentAvatar.copyWith(
                        accessories: newAccessories,
                      );
                    });
                  },
                  selectedColor: EmergeColors.teal,
                  labelStyle: TextStyle(
                    color: hasAccessory
                        ? Colors.black
                        : AppTheme.textSecondaryDark,
                    fontWeight: FontWeight.bold,
                  ),
                  backgroundColor: AppTheme.surfaceDark.withValues(alpha: 0.5),
                  side: BorderSide(
                    color: hasAccessory
                        ? EmergeColors.teal
                        : EmergeColors.hexLine,
                  ),
                );
              })
              .toList(),
        ),
        const Gap(24),
        if (_currentAvatar.accessories.contains(AvatarAccessory.beard) ||
            _currentAvatar.accessories.contains(AvatarAccessory.mustache))
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildSectionTitle('Facial Hair Growth'),
              _buildSlider(
                label: 'Growth Level',
                value: _currentAvatar.facialHairGrowth,
                min: 0.0,
                max: 1.0,
                onChanged: (value) {
                  setState(() {
                    _currentAvatar = _currentAvatar.copyWith(
                      facialHairGrowth: value,
                    );
                  });
                },
              ),
            ],
          ),
      ],
    );
  }

  Widget _buildAdvancedTab() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _buildSectionTitle('Pose & Animation'),
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: AvatarPose.values.map((pose) {
            final isSelected = _currentAvatar.pose == pose;
            return ChoiceChip(
              label: Text(pose.name.toUpperCase()),
              selected: isSelected,
              onSelected: (selected) {
                if (selected) {
                  setState(() {
                    _currentAvatar = _currentAvatar.copyWith(pose: pose);
                  });
                }
              },
              selectedColor: EmergeColors.teal,
              labelStyle: TextStyle(
                color: isSelected ? Colors.black : AppTheme.textSecondaryDark,
                fontWeight: FontWeight.bold,
              ),
              backgroundColor: AppTheme.surfaceDark.withValues(alpha: 0.5),
              side: BorderSide(
                color: isSelected ? EmergeColors.teal : EmergeColors.hexLine,
              ),
            );
          }).toList(),
        ),
        const Gap(24),
        SwitchListTile(
          title: const Text(
            'Enable Animations',
            style: TextStyle(
              color: AppTheme.textSecondaryDark,
              fontWeight: FontWeight.bold,
            ),
          ),
          value: _currentAvatar.isAnimated,
          onChanged: (value) {
            setState(() {
              _currentAvatar = _currentAvatar.copyWith(isAnimated: value);
            });
          },
          thumbColor: WidgetStateProperty.resolveWith<Color?>((
            Set<WidgetState> states,
          ) {
            return EmergeColors.teal;
          }),
        ),
        if (_currentAvatar.isAnimated)
          _buildSlider(
            label: 'Animation Speed',
            value: _currentAvatar.animationSpeed,
            min: 0.0,
            max: 2.0,
            onChanged: (value) {
              setState(() {
                _currentAvatar = _currentAvatar.copyWith(animationSpeed: value);
              });
            },
          ),
      ],
    );
  }

  Widget _buildSlider({
    required String label,
    required double value,
    required double min,
    required double max,
    required ValueChanged<double> onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: AppTheme.textSecondaryDark,
            fontWeight: FontWeight.bold,
          ),
        ),
        const Gap(8),
        Slider(
          value: value,
          min: min,
          max: max,
          divisions: 100,
          label: value.toStringAsFixed(2),
          onChanged: onChanged,
          thumbColor: EmergeColors.teal,
        ),
        Text(
          value.toStringAsFixed(2),
          style: const TextStyle(color: AppTheme.textSecondaryDark),
        ),
      ],
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Text(
        title,
        style: Theme.of(context).textTheme.titleMedium?.copyWith(
          color: AppTheme.textSecondaryDark,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  void _showColorPicker(
    BuildContext context,
    Color initialColor,
    ValueChanged<Color> onColorSelected,
  ) {
    // This would be a proper color picker implementation
    // For now, showing a basic implementation
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Select Color'),
        content: SizedBox(
          height: 300,
          child: GridView.builder(
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 4,
              crossAxisSpacing: 8,
              mainAxisSpacing: 8,
            ),
            itemCount: AvatarColor.outfitColors.length,
            itemBuilder: (context, index) {
              final colorOption = AvatarColor.outfitColors[index];
              return GestureDetector(
                onTap: () {
                  Navigator.of(context).pop();
                  onColorSelected(colorOption.color);
                },
                child: Container(
                  decoration: BoxDecoration(
                    color: colorOption.color,
                    border: Border.all(color: Colors.grey, width: 2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Center(
                    child: Text(
                      colorOption.name,
                      style: TextStyle(
                        color:
                            ThemeData.estimateBrightnessForColor(
                                  colorOption.color,
                                ) ==
                                Brightness.dark
                            ? Colors.white
                            : Colors.black,
                        fontSize: 10,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
              );
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
  }
}
