import 'package:emerge_app/features/social/domain/models/tribe.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final tribesProvider = Provider<List<Tribe>>((ref) {
  return [
    const Tribe(
      id: '1',
      name: '5 AM Writers',
      description: 'Early risers dedicated to the craft of writing.',
      imageUrl:
          'https://images.unsplash.com/photo-1455390582262-044cdead277a?auto=format&fit=crop&q=80&w=300',
      memberCount: 1240,
      rank: 1,
      totalXp: 540000,
    ),
    const Tribe(
      id: '2',
      name: 'Meditation Guild',
      description: 'Seekers of inner peace and mindfulness.',
      imageUrl:
          'https://images.unsplash.com/photo-1593811167562-9cef47bfc4d7?auto=format&fit=crop&q=80&w=300',
      memberCount: 3500,
      rank: 2,
      totalXp: 480000,
    ),
    const Tribe(
      id: '3',
      name: 'Accountability Alliance',
      description: 'We hold each other to the highest standard.',
      imageUrl:
          'https://images.unsplash.com/photo-1521737604893-d14cc237f11d?auto=format&fit=crop&q=80&w=300',
      memberCount: 890,
      rank: 3,
      totalXp: 420000,
    ),
    const Tribe(
      id: '4',
      name: 'Iron Lifters',
      description: 'Forging bodies of steel in the gym.',
      imageUrl:
          'https://images.unsplash.com/photo-1517836357463-d25dfeac3438?auto=format&fit=crop&q=80&w=300',
      memberCount: 2100,
      rank: 4,
      totalXp: 390000,
    ),
    const Tribe(
      id: '5',
      name: 'Code Warriors',
      description: 'Building the future, one line at a time.',
      imageUrl:
          'https://images.unsplash.com/photo-1515879218367-8466d910aaa4?auto=format&fit=crop&q=80&w=300',
      memberCount: 1800,
      rank: 5,
      totalXp: 360000,
    ),
    const Tribe(
      id: '6',
      name: 'Deep Work Disciples',
      description: 'Mastering focus in a distracted world.',
      imageUrl:
          'https://images.unsplash.com/photo-1497032628192-86f99bcd76bc?auto=format&fit=crop&q=80&w=300',
      memberCount: 950,
      rank: 6,
      totalXp: 330000,
    ),
    const Tribe(
      id: '7',
      name: 'Stoic Circle',
      description: 'Practicing ancient wisdom for modern life.',
      imageUrl:
          'https://images.unsplash.com/photo-1535905557558-afc4877a26fc?auto=format&fit=crop&q=80&w=300',
      memberCount: 1100,
      rank: 7,
      totalXp: 310000,
    ),
    const Tribe(
      id: '8',
      name: 'Plant-Based Power',
      description: 'Fueling our bodies with nature\'s best.',
      imageUrl:
          'https://images.unsplash.com/photo-1512621776951-a57141f2eefd?auto=format&fit=crop&q=80&w=300',
      memberCount: 1400,
      rank: 8,
      totalXp: 290000,
    ),
    const Tribe(
      id: '9',
      name: 'Financial Freedom Fighters',
      description: 'Building wealth and securing our future.',
      imageUrl:
          'https://images.unsplash.com/photo-1579621970563-ebec7560ff3e?auto=format&fit=crop&q=80&w=300',
      memberCount: 2500,
      rank: 9,
      totalXp: 270000,
    ),
    const Tribe(
      id: '10',
      name: 'Digital Nomads',
      description: 'Working from anywhere, living everywhere.',
      imageUrl:
          'https://images.unsplash.com/photo-1507525428034-b723cf961d3e?auto=format&fit=crop&q=80&w=300',
      memberCount: 3000,
      rank: 10,
      totalXp: 250000,
    ),
    const Tribe(
      id: '11',
      name: 'Language Learners',
      description: 'Connecting with the world through words.',
      imageUrl:
          'https://images.unsplash.com/photo-1543269865-cbf427effbad?auto=format&fit=crop&q=80&w=300',
      memberCount: 1600,
      rank: 11,
      totalXp: 230000,
    ),
    const Tribe(
      id: '12',
      name: 'Artistic Souls',
      description: 'Expressing creativity in every form.',
      imageUrl:
          'https://images.unsplash.com/photo-1460661631189-a052511d1de7?auto=format&fit=crop&q=80&w=300',
      memberCount: 1300,
      rank: 12,
      totalXp: 210000,
    ),
    const Tribe(
      id: '13',
      name: 'Eco Warriors',
      description: 'Protecting our planet for future generations.',
      imageUrl:
          'https://images.unsplash.com/photo-1542601906990-b4d3fb778b09?auto=format&fit=crop&q=80&w=300',
      memberCount: 2200,
      rank: 13,
      totalXp: 190000,
    ),
    const Tribe(
      id: '14',
      name: 'Mindful Parents',
      description: 'Raising the next generation with love.',
      imageUrl:
          'https://images.unsplash.com/photo-1511895426328-dc8714191300?auto=format&fit=crop&q=80&w=300',
      memberCount: 1700,
      rank: 14,
      totalXp: 170000,
    ),
    const Tribe(
      id: '15',
      name: 'Biohackers',
      description: 'Optimizing human performance through science.',
      imageUrl:
          'https://images.unsplash.com/photo-1532094349884-543bc11b234d?auto=format&fit=crop&q=80&w=300',
      memberCount: 800,
      rank: 15,
      totalXp: 150000,
    ),
    const Tribe(
      id: '16',
      name: 'Minimalists',
      description: 'Living more with less.',
      imageUrl:
          'https://images.unsplash.com/photo-1494438639946-1ebd1d20bf85?auto=format&fit=crop&q=80&w=300',
      memberCount: 1900,
      rank: 16,
      totalXp: 130000,
    ),
    const Tribe(
      id: '17',
      name: 'Book Club',
      description: 'Devouring knowledge one page at a time.',
      imageUrl:
          'https://images.unsplash.com/photo-1495446815901-a7297e633e8d?auto=format&fit=crop&q=80&w=300',
      memberCount: 2400,
      rank: 17,
      totalXp: 110000,
    ),
    const Tribe(
      id: '18',
      name: 'Yoga Flow',
      description: 'Finding balance on and off the mat.',
      imageUrl:
          'https://images.unsplash.com/photo-1544367563-12123d8965cd?auto=format&fit=crop&q=80&w=300',
      memberCount: 2600,
      rank: 18,
      totalXp: 90000,
    ),
    const Tribe(
      id: '19',
      name: 'Chess Strategists',
      description: 'Sharpening minds through the royal game.',
      imageUrl:
          'https://images.unsplash.com/photo-1529699211952-734e80c4d42b?auto=format&fit=crop&q=80&w=300',
      memberCount: 600,
      rank: 19,
      totalXp: 70000,
    ),
    const Tribe(
      id: '20',
      name: 'Music Makers',
      description: 'Creating the soundtrack of our lives.',
      imageUrl:
          'https://images.unsplash.com/photo-1511379938547-c1f69419868d?auto=format&fit=crop&q=80&w=300',
      memberCount: 1500,
      rank: 20,
      totalXp: 50000,
    ),
  ];
});
