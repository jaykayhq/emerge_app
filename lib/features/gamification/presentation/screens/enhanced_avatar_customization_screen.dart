import 'package:emerge_app/core/presentation/widgets/emerge_branding.dart';
import 'package:emerge_app/core/theme/app_theme.dart';
import 'package:emerge_app/features/gamification/domain/models/enhanced_avatar.dart';
import 'package:emerge_app/features/gamification/presentation/screens/avatar_creator_webview.dart';
import 'package:emerge_app/features/gamification/presentation/widgets/enhanced_avatar_display.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';
import 'package:go_router/go_router.dart';

class EnhancedAvatarCustomizationScreen extends ConsumerStatefulWidget {
  const EnhancedAvatarCustomizationScreen({super.key});

  @override
  ConsumerState<EnhancedAvatarCustomizationScreen> createState() =>
      _EnhancedAvatarCustomizationScreenState();
}

class _EnhancedAvatarCustomizationScreenState
    extends ConsumerState<EnhancedAvatarCustomizationScreen>
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
      // In a real implementation, you would get the enhanced avatar from user stats
      // For now, create a default one
      _currentAvatar = const EnhancedAvatar();
      _isInit = true;
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _saveAvatar() async {
    // In a real implementation, you would save the enhanced avatar to user stats
    // This is a placeholder for now
    if (mounted) context.pop();
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
                  child: Center(
                    child: LayoutBuilder(
                      builder: (context, constraints) {
                        // Calculate dynamic size based on available height - more conservative clamping
                        final availableHeight = constraints.maxHeight;
                        final size = (availableHeight * 0.65).clamp(
                          80.0,
                          220.0,
                        );
                        final showLabel = availableHeight > 200;

                        return Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            EnhancedAvatarDisplay(
                              avatar: _currentAvatar,
                              size: size,
                              animate: _currentAvatar.isAnimated,
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
                                  '${_currentAvatar.bodyType.name.toUpperCase()} • ${_currentAvatar.hairStyle.name.toUpperCase()}',
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
                    ),
                  ),
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
