import 'package:emerge_app/features/narrator/domain/models/narrator_trigger.dart';
import 'package:equatable/equatable.dart';

/// Represents what the Narrator says and shows when appearing.
///
/// This is the output of the Narrator engine — a fully-formed "appearance"
/// with the text to display, button labels, and any contextual slot data.
class NarratorAppearance extends Equatable {
  /// What triggered this appearance
  final NarratorTrigger trigger;

  /// The main text the Narrator will speak (typewriter-rendered)
  final String shellText;

  /// Label for the primary action button
  final String buttonA;

  /// Label for the secondary action button
  final String buttonB;

  /// Optional slot keys (habit IDs, node IDs, etc.) for contextual actions
  final List<String>? slotKeys;

  /// Whether this appearance includes a text input field
  /// (only used by eveningReflection)
  final bool hasTextField;

  /// Optional contextual data map (XP amounts, streak counts, etc.)
  final Map<String, dynamic>? context;

  const NarratorAppearance({
    required this.trigger,
    required this.shellText,
    required this.buttonA,
    required this.buttonB,
    this.slotKeys,
    this.hasTextField = false,
    this.context,
  });

  @override
  List<Object?> get props => [
        trigger,
        shellText,
        buttonA,
        buttonB,
        slotKeys,
        hasTextField,
        context,
      ];

  /// Creates a copy of this appearance with the given fields replaced.
  NarratorAppearance copyWith({
    NarratorTrigger? trigger,
    String? shellText,
    String? buttonA,
    String? buttonB,
    List<String>? slotKeys,
    bool? hasTextField,
    Map<String, dynamic>? context,
  }) {
    return NarratorAppearance(
      trigger: trigger ?? this.trigger,
      shellText: shellText ?? this.shellText,
      buttonA: buttonA ?? this.buttonA,
      buttonB: buttonB ?? this.buttonB,
      slotKeys: slotKeys ?? this.slotKeys,
      hasTextField: hasTextField ?? this.hasTextField,
      context: context ?? this.context,
    );
  }
}
