import os
import re

def fix_files(root_dir):
    # Pattern to match .withOpacity(0.5) or .withOpacity(opacity)
    with_opacity_pattern = re.compile(r'\.withOpacity\s*\(\s*([^)]+)\s*\)')
    
    # Imports to ensure
    import_emerge_colors = "import 'package:emerge_app/core/theme/emerge_colors.dart';"
    import_world_background = "import 'package:emerge_app/core/presentation/widgets/world_background.dart';"
    
    for root, dirs, files in os.walk(root_dir):
        # Skip hidden directories and specific ignored paths
        if any(ignored in root for ignored in ['.planning', '.git', '.gemini', 'build']):
            continue
            
        for file in files:
            if file.endswith('.dart'):
                filepath = os.path.join(root, file)
                try:
                    with open(filepath, 'r', encoding='utf-8') as f:
                        content = f.read()
                except Exception as e:
                    print(f"Error reading {filepath}: {e}")
                    continue

                original_content = content
                
                # 1. Replace withOpacity with withValues(alpha: ...)
                # This fixes the Flutter 3.27+ deprecation
                content = with_opacity_pattern.sub(r'.withValues(alpha: \1)', content)
                
                # 2. Fix broken skeleton loader imports
                # Looking for: import '../../../core/presentation/widgets/emerge_loading_skeleton.dart';
                # and replacing with absolute import for safety
                content = content.replace(
                    "import '../../../core/presentation/widgets/emerge_loading_skeleton.dart';",
                    "import 'package:emerge_app/core/presentation/widgets/emerge_loading_skeleton.dart';"
                )
                content = content.replace(
                    "import '../../core/presentation/widgets/emerge_loading_skeleton.dart';",
                    "import 'package:emerge_app/core/presentation/widgets/emerge_loading_skeleton.dart';"
                )

                # 3. Fix TribeQuestsSection provider import
                if "tribe_quests_section.dart" in filepath:
                    content = content.replace(
                        "import '../../social/presentation/providers/challenge_bundle_provider.dart';",
                        "import 'package:emerge_app/features/social/presentation/providers/challenge_bundle_provider.dart';"
                    )

                if content != original_content:
                    try:
                        with open(filepath, 'w', encoding='utf-8') as f:
                            f.write(content)
                        print(f"Fixed {filepath}")
                    except Exception as e:
                        print(f"Error writing {filepath}: {e}")

if __name__ == "__main__":
    # Run on lib directory
    fix_files("lib")
