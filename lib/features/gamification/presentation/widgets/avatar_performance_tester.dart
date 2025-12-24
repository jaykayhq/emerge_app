import 'package:emerge_app/features/gamification/domain/models/enhanced_avatar.dart';
import 'package:emerge_app/features/gamification/presentation/widgets/enhanced_avatar_display.dart';
import 'package:flutter/material.dart';
import 'dart:math';

/// A utility widget for testing avatar rendering performance
class AvatarPerformanceTester extends StatefulWidget {
  const AvatarPerformanceTester({super.key});

  @override
  State<AvatarPerformanceTester> createState() => _AvatarPerformanceTesterState();
}

class _AvatarPerformanceTesterState extends State<AvatarPerformanceTester> {
  final List<EnhancedAvatar> _avatars = [];
  final Random _random = Random();
  int _frameCount = 0;
  DateTime _lastFrameTime = DateTime.now();
  double _fps = 0.0;
  bool _isTesting = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Avatar Performance Test'),
      ),
      body: Column(
        children: [
          // Controls
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ElevatedButton(
                  onPressed: _startTest,
                  child: const Text('Start Test'),
                ),
                ElevatedButton(
                  onPressed: _stopTest,
                  child: const Text('Stop Test'),
                ),
                ElevatedButton(
                  onPressed: _generateAvatars,
                  child: const Text('Generate Avatars'),
                ),
              ],
            ),
          ),
          
          // Stats
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                Text('FPS: ${_fps.toStringAsFixed(1)}'),
                Text('Avatars: ${_avatars.length}'),
                Text('Frame: $_frameCount'),
              ],
            ),
          ),
          
          // Avatar Grid
          Expanded(
            child: _isTesting 
                ? _buildAnimatedGrid() 
                : _buildStaticGrid(),
          ),
        ],
      ),
    );
  }

  Widget _buildStaticGrid() {
    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 8,
        mainAxisSpacing: 8,
      ),
      itemCount: _avatars.length,
      itemBuilder: (context, index) {
        return Container(
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey),
            borderRadius: BorderRadius.circular(8),
          ),
          child: EnhancedAvatarDisplay(
            avatar: _avatars[index],
            size: 80,
          ),
        );
      },
    );
  }

  Widget _buildAnimatedGrid() {
    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 8,
        mainAxisSpacing: 8,
      ),
      itemCount: _avatars.length,
      itemBuilder: (context, index) {
        // Animate some properties for performance testing
        final animatedAvatar = _avatars[index].copyWith(
          expression: _frameCount % 60 < 30
              ? AvatarExpression.happy
              : AvatarExpression.neutral,
          pose: _frameCount % 120 < 60
              ? AvatarPose.standing
              : AvatarPose.waving,
          isAnimated: true,
        );

        return Container(
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey),
            borderRadius: BorderRadius.circular(8),
          ),
          child: EnhancedAvatarDisplay(
            avatar: animatedAvatar,
            size: 80,
            animate: true,
          ),
        );
      },
    );
  }

  void _startTest() {
    setState(() {
      _isTesting = true;
    });
    
    // Start frame counting
    _frameCount = 0;
    _lastFrameTime = DateTime.now();
    
    // Schedule frame updates
    _scheduleFrame();
  }

  void _stopTest() {
    setState(() {
      _isTesting = false;
    });
  }

  void _scheduleFrame() {
    if (!_isTesting) return;
    
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final now = DateTime.now();
      final elapsed = now.difference(_lastFrameTime).inMilliseconds / 1000.0;
      
      _frameCount++;
      
      // Update FPS every 10 frames
      if (_frameCount % 10 == 0) {
        _fps = 1.0 / elapsed;
        _lastFrameTime = now;
      }
      
      if (_isTesting) {
        setState(() {}); // Trigger rebuild
        _scheduleFrame(); // Schedule next frame
      }
    });
  }

  void _generateAvatars() {
    final newAvatars = <EnhancedAvatar>[];
    
    for (int i = 0; i < 20; i++) {
      newAvatars.add(
        EnhancedAvatar(
          bodyType: EnhancedAvatarBodyType.values[_random.nextInt(EnhancedAvatarBodyType.values.length)],
          skinTone: EnhancedAvatarSkinTone.values[_random.nextInt(EnhancedAvatarSkinTone.values.length)],
          hairStyle: EnhancedAvatarHairStyle.values[_random.nextInt(EnhancedAvatarHairStyle.values.length)],
          hairColor: EnhancedAvatarHairColor.values[_random.nextInt(EnhancedAvatarHairColor.values.length)],
          faceShape: EnhancedAvatarFaceShape.values[_random.nextInt(EnhancedAvatarFaceShape.values.length)],
          outfit: EnhancedAvatarOutfit.values[_random.nextInt(EnhancedAvatarOutfit.values.length)],
          expression: AvatarExpression.values[_random.nextInt(AvatarExpression.values.length)],
          pose: AvatarPose.values[_random.nextInt(AvatarPose.values.length)],
          bodyScale: 0.5 + _random.nextDouble() * 0.5, // 0.5 to 1.0
          headScale: 0.7 + _random.nextDouble() * 0.3, // 0.7 to 1.0
          limbScale: 0.5 + _random.nextDouble() * 0.5, // 0.5 to 1.0
          accessories: _getRandomAccessories(_random),
          outfitPrimaryColor: Color.fromARGB(
            255,
            _random.nextInt(256),
            _random.nextInt(256),
            _random.nextInt(256),
          ),
          outfitSecondaryColor: Color.fromARGB(
            255,
            _random.nextInt(256),
            _random.nextInt(256),
            _random.nextInt(256),
          ),
          hairLength: 0.3 + _random.nextDouble() * 1.2, // 0.3 to 1.5
          facialHairGrowth: _random.nextDouble(), // 0.0 to 1.0
          isAnimated: false,
        ),
      );
    }
    
    setState(() {
      _avatars.clear();
      _avatars.addAll(newAvatars);
    });
  }

  List<AvatarAccessory> _getRandomAccessories(Random random) {
    final accessories = <AvatarAccessory>[];
    final possibleAccessories = AvatarAccessory.values
        .where((a) => a != AvatarAccessory.none)
        .toList();
    
    // Add 0-3 random accessories
    final count = random.nextInt(4);
    for (int i = 0; i < count; i++) {
      final accessory = possibleAccessories[random.nextInt(possibleAccessories.length)];
      if (!accessories.contains(accessory)) {
        accessories.add(accessory);
      }
    }
    
    return accessories;
  }
}