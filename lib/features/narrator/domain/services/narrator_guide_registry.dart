/// One narrator-voiced guide step: a script the narrator types while the
/// spotlight highlights the section [targetKey] points at.
class NarratorGuideStep {
  final String script;
  final String targetKey;

  const NarratorGuideStep({required this.script, required this.targetKey});
}

/// Static configuration for a first-visit narrator guide on one screen.
///
/// [targetKey] values must match the keys of the `targets` map passed to
/// `NarratorGuideHost` on the corresponding screen (see the guide registry
/// test and the screen tasks in the plan).
class NarratorGuideDefinition {
  final String nodeId;
  final List<NarratorGuideStep> steps;

  const NarratorGuideDefinition({required this.nodeId, required this.steps});
}

/// Pure registry of all narrator guides.
///
/// One entry per live, front-facing screen. Scripts are first-person
/// narrator voice: they name the section they explain, because the
/// spotlight points at it while the line types.
class NarratorGuideRegistry {
  static const List<NarratorGuideDefinition> all = [
    NarratorGuideDefinition(nodeId: 'timeline', steps: [
      NarratorGuideStep(
        script: "See the + down there? That's where habits are born.",
        targetKey: 'fab',
      ),
      NarratorGuideStep(
        script:
            "The ring around it is today's score — green when you're on track.",
        targetKey: 'ring',
      ),
      NarratorGuideStep(
        script:
            "This card is me. It tells you what's left today — and you can ask me anything.",
        targetKey: 'card',
      ),
    ]),
    NarratorGuideDefinition(nodeId: 'habit_create', steps: [
      NarratorGuideStep(
        script:
            "Start here — a habit is a promise with a name you'll keep.",
        targetKey: 'name_field',
      ),
      NarratorGuideStep(
        script: "When it feels real, press this. Small steps, on purpose.",
        targetKey: 'create_button',
      ),
    ]),
    NarratorGuideDefinition(nodeId: 'streak_recovery', steps: [
      NarratorGuideStep(
        script:
            "One miss is a slip, not a fall. This is where your momentum rebuilds.",
        targetKey: 'momentum_visual',
      ),
      NarratorGuideStep(
        script: "The smallest step first — that's how a streak comes back.",
        targetKey: 'restart_cta',
      ),
    ]),
    NarratorGuideDefinition(nodeId: 'world_map', steps: [
      NarratorGuideStep(
        script:
            "This is your world. It thrives when you do — every habit you keep keeps it alive.",
        targetKey: 'map_body',
      ),
      NarratorGuideStep(
        script: "Your realm, your rules. Explore as you grow.",
        targetKey: 'map_header',
      ),
    ]),
    NarratorGuideDefinition(nodeId: 'leveling', steps: [
      NarratorGuideStep(
        script:
            "Every completed habit feeds this — your level is the sum of your days.",
        targetKey: 'level_header',
      ),
      NarratorGuideStep(
        script: "Watch it fill. XP is just proof you showed up.",
        targetKey: 'level_bar',
      ),
    ]),
    NarratorGuideDefinition(nodeId: 'future_self', steps: [
      NarratorGuideStep(
        script:
            "This is who you're becoming. Give them a face, a name, a reason.",
        targetKey: 'studio_header',
      ),
      NarratorGuideStep(
        script: "Press this when the vision is ready — I'll hold you to it.",
        targetKey: 'generate_button',
      ),
    ]),
    NarratorGuideDefinition(nodeId: 'challenges', steps: [
      NarratorGuideStep(
        script: "A public challenge is a promise with witnesses. Join one.",
        targetKey: 'join_fab',
      ),
      NarratorGuideStep(
        script:
            "Compete on progress, not perfection — the leaderboard knows.",
        targetKey: 'challenge_list',
      ),
    ]),
    NarratorGuideDefinition(nodeId: 'all_tribes', steps: [
      NarratorGuideStep(
        script: "These are your people — tribes sorted by how you grow.",
        targetKey: 'tribes_header',
      ),
      NarratorGuideStep(
        script:
            "Pick one. You can switch anytime; belonging should feel chosen.",
        targetKey: 'tribe_list',
      ),
    ]),
    NarratorGuideDefinition(nodeId: 'tribe_lobby', steps: [
      NarratorGuideStep(
        script:
            "Your circle, your partners, your tribe's pulse — it all lives here.",
        targetKey: 'member_list',
      ),
      NarratorGuideStep(
        script:
            "Jump to challenges, or find a new tribe — the door's always open.",
        targetKey: 'lobby_actions',
      ),
    ]),
  ];

  static NarratorGuideDefinition? forNode(String nodeId) {
    for (final d in all) {
      if (d.nodeId == nodeId) return d;
    }
    return null;
  }
}
