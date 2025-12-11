import 'package:emerge_app/features/social/domain/models/challenge.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class ChallengeNotifier extends StateNotifier<List<Challenge>> {
  ChallengeNotifier() : super(_initialChallenges);

  static final List<Challenge> _initialChallenges = [
    Challenge(
      id: '1',
      title: 'The 30-Day Running Streak',
      description: 'Run 1 mile every day to build endurance and discipline.',
      imageUrl:
          'https://images.unsplash.com/photo-1455390582262-044cdead277a?auto=format&fit=crop&q=80&w=300',
      reward: '20% Off Running Shoes',
      participants: 1500,
      daysLeft: 8,
      totalDays: 30,
      currentDay: 0,
      status: ChallengeStatus.featured,
      steps: List.generate(
        30,
        (index) => ChallengeStep(
          day: index + 1,
          title: 'Run 1 Mile',
          description: 'Complete a 1-mile run.',
        ),
      ),
    ),
    Challenge(
      id: '2',
      title: 'The Morning Meditation Quest',
      description: 'Start your day with 10 minutes of mindfulness.',
      imageUrl:
          'https://images.unsplash.com/photo-1593811167562-9cef47bfc4d7?auto=format&fit=crop&q=80&w=300',
      reward: '3-Months Premium Free',
      participants: 2100,
      daysLeft: 12,
      totalDays: 30,
      currentDay: 0,
      status: ChallengeStatus.featured,
      steps: List.generate(
        30,
        (index) => ChallengeStep(
          day: index + 1,
          title: 'Meditate 10 Mins',
          description: 'Practice mindfulness.',
        ),
      ),
    ),
    Challenge(
      id: '3',
      title: 'The Unbroken Reading Chain',
      description: 'Read 10 pages of a non-fiction book daily.',
      imageUrl:
          'https://images.unsplash.com/photo-1495446815901-a7297e633e8d?auto=format&fit=crop&q=80&w=300',
      reward: '\$10 Bookstore Credit',
      participants: 876,
      daysLeft: 21,
      totalDays: 30,
      currentDay: 0,
      status: ChallengeStatus.featured,
      steps: List.generate(
        30,
        (index) => ChallengeStep(
          day: index + 1,
          title: 'Read 10 Pages',
          description: 'Read 10 pages.',
        ),
      ),
    ),
    Challenge(
      id: '4',
      title: 'No Sugar September',
      description: 'Eliminate added sugar for 30 days.',
      imageUrl:
          'https://images.unsplash.com/photo-1576092768241-dec231879fc3?auto=format&fit=crop&q=80&w=300',
      reward: 'Healthy Recipe E-Book',
      participants: 3200,
      daysLeft: 25,
      totalDays: 30,
      currentDay: 0,
      status: ChallengeStatus.active,
      steps: List.generate(
        30,
        (index) => ChallengeStep(
          day: index + 1,
          title: 'No Sugar',
          description: 'Avoid added sugar today.',
        ),
      ),
    ),
    Challenge(
      id: '5',
      title: '10k Steps Daily',
      description: 'Walk 10,000 steps every day.',
      imageUrl:
          'https://images.unsplash.com/photo-1476480862126-209bfaa8edc8?auto=format&fit=crop&q=80&w=300',
      reward: 'Fitness Tracker Discount',
      participants: 5000,
      daysLeft: 15,
      totalDays: 30,
      currentDay: 0,
      status: ChallengeStatus.active,
      steps: List.generate(
        30,
        (index) => ChallengeStep(
          day: index + 1,
          title: '10k Steps',
          description: 'Walk 10,000 steps.',
        ),
      ),
    ),
    Challenge(
      id: '6',
      title: 'Cold Shower Challenge',
      description: 'Take a cold shower every morning.',
      imageUrl:
          'https://images.unsplash.com/photo-1520206183501-b80df61043c2?auto=format&fit=crop&q=80&w=300',
      reward: 'Wim Hof Method Guide',
      participants: 1200,
      daysLeft: 10,
      totalDays: 30,
      currentDay: 0,
      status: ChallengeStatus.active,
      steps: List.generate(
        30,
        (index) => ChallengeStep(
          day: index + 1,
          title: 'Cold Shower',
          description: 'Take a cold shower.',
        ),
      ),
    ),
    Challenge(
      id: '7',
      title: 'Journaling Journey',
      description: 'Write in your journal for 15 minutes daily.',
      imageUrl:
          'https://images.unsplash.com/photo-1517842645767-c639042777db?auto=format&fit=crop&q=80&w=300',
      reward: 'Premium Journal',
      participants: 1800,
      daysLeft: 20,
      totalDays: 30,
      currentDay: 0,
      status: ChallengeStatus.active,
      steps: List.generate(
        30,
        (index) => ChallengeStep(
          day: index + 1,
          title: 'Journal',
          description: 'Write for 15 minutes.',
        ),
      ),
    ),
    Challenge(
      id: '8',
      title: 'Digital Detox Weekend',
      description: 'No screens for 48 hours.',
      imageUrl:
          'https://images.unsplash.com/photo-1516321318423-f06f85e504b3?auto=format&fit=crop&q=80&w=300',
      reward: 'Mindfulness App Subscription',
      participants: 900,
      daysLeft: 2,
      totalDays: 2,
      currentDay: 0,
      status: ChallengeStatus.active,
      steps: List.generate(
        2,
        (index) => ChallengeStep(
          day: index + 1,
          title: 'No Screens',
          description: 'Avoid screens today.',
        ),
      ),
    ),
    Challenge(
      id: '9',
      title: 'Sleep Hygiene Master',
      description: 'Sleep 8 hours every night.',
      imageUrl:
          'https://images.unsplash.com/photo-1541781777621-735356cd3672?auto=format&fit=crop&q=80&w=300',
      reward: 'Sleep Mask',
      participants: 2500,
      daysLeft: 18,
      totalDays: 30,
      currentDay: 0,
      status: ChallengeStatus.active,
      steps: List.generate(
        30,
        (index) => ChallengeStep(
          day: index + 1,
          title: '8 Hours Sleep',
          description: 'Get 8 hours of sleep.',
        ),
      ),
    ),
    Challenge(
      id: '10',
      title: 'Hydration Hero',
      description: 'Drink 3 liters of water daily.',
      imageUrl:
          'https://images.unsplash.com/photo-1548839140-29a749e1cf4d?auto=format&fit=crop&q=80&w=300',
      reward: 'Smart Water Bottle',
      participants: 4000,
      daysLeft: 28,
      totalDays: 30,
      currentDay: 0,
      status: ChallengeStatus.active,
      steps: List.generate(
        30,
        (index) => ChallengeStep(
          day: index + 1,
          title: 'Drink Water',
          description: 'Drink 3 liters.',
        ),
      ),
    ),
    Challenge(
      id: '11',
      title: 'Plank Challenge',
      description: 'Increase plank time daily.',
      imageUrl:
          'https://images.unsplash.com/photo-1571019614242-c5c5dee9f50b?auto=format&fit=crop&q=80&w=300',
      reward: 'Yoga Mat',
      participants: 1500,
      daysLeft: 5,
      totalDays: 30,
      currentDay: 0,
      status: ChallengeStatus.active,
      steps: List.generate(
        30,
        (index) => ChallengeStep(
          day: index + 1,
          title: 'Plank',
          description: 'Hold plank for ${(index + 1) * 10} seconds.',
        ),
      ),
    ),
    Challenge(
      id: '12',
      title: 'Gratitude Practice',
      description: 'Write 3 things you are grateful for.',
      imageUrl:
          'https://images.unsplash.com/photo-1507608616759-54f48f0af0ee?auto=format&fit=crop&q=80&w=300',
      reward: 'Gratitude Journal',
      participants: 2200,
      daysLeft: 22,
      totalDays: 30,
      currentDay: 0,
      status: ChallengeStatus.active,
      steps: List.generate(
        30,
        (index) => ChallengeStep(
          day: index + 1,
          title: 'Gratitude',
          description: 'Write 3 things.',
        ),
      ),
    ),
    Challenge(
      id: '13',
      title: 'Learn a New Skill',
      description: 'Practice a new skill for 30 mins daily.',
      imageUrl:
          'https://images.unsplash.com/photo-1503676260728-1c00da094a0b?auto=format&fit=crop&q=80&w=300',
      reward: 'Online Course Discount',
      participants: 1100,
      daysLeft: 14,
      totalDays: 30,
      currentDay: 0,
      status: ChallengeStatus.active,
      steps: List.generate(
        30,
        (index) => ChallengeStep(
          day: index + 1,
          title: 'Practice',
          description: 'Practice for 30 mins.',
        ),
      ),
    ),
    Challenge(
      id: '14',
      title: 'Random Acts of Kindness',
      description: 'Perform one act of kindness daily.',
      imageUrl:
          'https://images.unsplash.com/photo-1469571486292-0ba58a3f068b?auto=format&fit=crop&q=80&w=300',
      reward: 'Charity Donation',
      participants: 1600,
      daysLeft: 9,
      totalDays: 30,
      currentDay: 0,
      status: ChallengeStatus.active,
      steps: List.generate(
        30,
        (index) => ChallengeStep(
          day: index + 1,
          title: 'Kindness',
          description: 'Perform an act of kindness.',
        ),
      ),
    ),
    Challenge(
      id: '15',
      title: 'Zero Waste Week',
      description: 'Produce zero waste for a week.',
      imageUrl:
          'https://images.unsplash.com/photo-1532996122724-e3c354a0b15b?auto=format&fit=crop&q=80&w=300',
      reward: 'Reusable Kit',
      participants: 800,
      daysLeft: 3,
      totalDays: 7,
      currentDay: 0,
      status: ChallengeStatus.active,
      steps: List.generate(
        7,
        (index) => ChallengeStep(
          day: index + 1,
          title: 'Zero Waste',
          description: 'No waste today.',
        ),
      ),
    ),
    Challenge(
      id: '16',
      title: 'Early Riser',
      description: 'Wake up at 5 AM daily.',
      imageUrl:
          'https://images.unsplash.com/photo-1470252649378-9c29740c9fa8?auto=format&fit=crop&q=80&w=300',
      reward: 'Coffee Subscription',
      participants: 1900,
      daysLeft: 16,
      totalDays: 30,
      currentDay: 0,
      status: ChallengeStatus.active,
      steps: List.generate(
        30,
        (index) => ChallengeStep(
          day: index + 1,
          title: 'Wake Up',
          description: 'Wake up at 5 AM.',
        ),
      ),
    ),
    Challenge(
      id: '17',
      title: 'Deep Work Sprint',
      description: '2 hours of deep work daily.',
      imageUrl:
          'https://images.unsplash.com/photo-1497032628192-86f99bcd76bc?auto=format&fit=crop&q=80&w=300',
      reward: 'Productivity Planner',
      participants: 1300,
      daysLeft: 11,
      totalDays: 30,
      currentDay: 0,
      status: ChallengeStatus.active,
      steps: List.generate(
        30,
        (index) => ChallengeStep(
          day: index + 1,
          title: 'Deep Work',
          description: '2 hours of focus.',
        ),
      ),
    ),
    Challenge(
      id: '18',
      title: 'Social Media Fast',
      description: 'No social media for 30 days.',
      imageUrl:
          'https://images.unsplash.com/photo-1611162617474-5b21e879e113?auto=format&fit=crop&q=80&w=300',
      reward: 'Digital Wellbeing Guide',
      participants: 1400,
      daysLeft: 19,
      totalDays: 30,
      currentDay: 0,
      status: ChallengeStatus.active,
      steps: List.generate(
        30,
        (index) => ChallengeStep(
          day: index + 1,
          title: 'No Social Media',
          description: 'Avoid social media.',
        ),
      ),
    ),
    Challenge(
      id: '19',
      title: 'Healthy Eating Habit',
      description: 'Eat 5 servings of veg daily.',
      imageUrl:
          'https://images.unsplash.com/photo-1512621776951-a57141f2eefd?auto=format&fit=crop&q=80&w=300',
      reward: 'Meal Plan',
      participants: 2800,
      daysLeft: 24,
      totalDays: 30,
      currentDay: 0,
      status: ChallengeStatus.active,
      steps: List.generate(
        30,
        (index) => ChallengeStep(
          day: index + 1,
          title: 'Eat Veg',
          description: '5 servings of vegetables.',
        ),
      ),
    ),
    Challenge(
      id: '20',
      title: 'Daily Stretching',
      description: 'Stretch for 15 minutes daily.',
      imageUrl:
          'https://images.unsplash.com/photo-1518611012118-696072aa579a?auto=format&fit=crop&q=80&w=300',
      reward: 'Foam Roller',
      participants: 1700,
      daysLeft: 7,
      totalDays: 30,
      currentDay: 0,
      status: ChallengeStatus.active,
      steps: List.generate(
        30,
        (index) => ChallengeStep(
          day: index + 1,
          title: 'Stretch',
          description: 'Stretch for 15 mins.',
        ),
      ),
    ),
  ];

  void joinChallenge(String id) {
    state = [
      for (final challenge in state)
        if (challenge.id == id)
          challenge.copyWith(status: ChallengeStatus.active, currentDay: 1)
        else
          challenge,
    ];
  }

  void completeStep(String challengeId, int day) {
    // Logic to complete a step and update progress
    // For now, just a placeholder
  }
}

final challengesProvider =
    StateNotifierProvider<ChallengeNotifier, List<Challenge>>((ref) {
      return ChallengeNotifier();
    });

final filteredChallengesProvider =
    Provider.family<List<Challenge>, ChallengeStatus>((ref, status) {
      final challenges = ref.watch(challengesProvider);
      return challenges.where((c) => c.status == status).toList();
    });
