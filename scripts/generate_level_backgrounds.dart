// ignore_for_file: avoid_print
/// Asset Generation Script for Level Backgrounds
///
/// Generates AI-powered background images for each node in every archetype
/// using the Pollinations AI API (flux model).
///
/// Usage:
///   dart run scripts/generate_level_backgrounds.dart
///   dart run scripts/generate_level_backgrounds.dart --dry-run  (prints prompts only)
///   dart run scripts/generate_level_backgrounds.dart --archetype athlete  (single archetype)

import 'dart:io';
import 'dart:convert';

/// All node definitions per archetype with their image generation prompts
final Map<String, List<Map<String, String>>> archetypeNodes = {
  'athlete': [
    // STAGE 1: VALLEY (Phantom - Levels 1-5)
    {
      'id': 'athlete_1_1',
      'name': 'First Steps',
      'prompt':
          'Dusty trail leading into a vast open valley at dawn, first rays of sunlight, lone footprints in the dirt, RPG fantasy environment, atmospheric, cinematic, vertical mobile wallpaper',
    },
    {
      'id': 'athlete_1_2',
      'name': 'Foundation',
      'prompt':
          'Ancient stone foundation ruins in a green valley, morning mist, wildflowers growing through cracks, training grounds feel, RPG fantasy art, cinematic, vertical',
    },
    {
      'id': 'athlete_1_3',
      'name': 'Strength Trial',
      'prompt':
          'Rocky arena in a valley with standing stones arranged in a circle, golden hour light, challenge atmosphere, RPG trial grounds, fantasy environment, vertical',
    },
    {
      'id': 'athlete_1_4',
      'name': 'Endurance Build',
      'prompt':
          'Long winding path through rolling hills, endurance trail markers, sweat and determination atmosphere, fantasy RPG landscape, epic scale, vertical',
    },
    {
      'id': 'athlete_1_5',
      'name': 'Valley Gate',
      'prompt':
          'Massive ancient stone gate portal in a valley, glowing with golden energy, atmospheric mist, mountains in distance, RPG milestone portal, dramatic, vertical',
    },
    // STAGE 2: FOREST (Construct - Levels 6-10)
    {
      'id': 'athlete_2_1',
      'name': 'Forest Entry',
      'prompt':
          'Mystical dense forest entrance, ethereal light through ancient trees, bioluminescent mushrooms, misty atmosphere, RPG forest environment, vertical',
    },
    {
      'id': 'athlete_2_2',
      'name': 'Runners Grove',
      'prompt':
          'Enchanted forest clearing with a natural running track, dappled sunlight, ancient trees forming an arch, athletic energy, RPG fantasy, vertical',
    },
    {
      'id': 'athlete_2_3',
      'name': 'Warriors Trial',
      'prompt':
          'Deep forest training arena with wooden obstacles, rope bridges between trees, combat training grounds, RPG warrior environment, vertical',
    },
    {
      'id': 'athlete_2_4',
      'name': 'Stamina Climb',
      'prompt':
          'Steep forest hillside with ancient carved stone steps, vines and roots creating handholds, mist below, RPG climbing challenge, vertical',
    },
    {
      'id': 'athlete_2_5',
      'name': 'Forest Master',
      'prompt':
          'Majestic treehouse fortress atop the tallest tree, overlooking the entire forest, golden canopy, RPG mastery achievement, epic vista, vertical',
    },
    // STAGE 3: MOUNTAIN (Incarnate - Levels 11-15)
    {
      'id': 'athlete_3_1',
      'name': 'Mountain Base',
      'prompt':
          'Base camp at the foot of a massive snow-capped mountain, tents and climbing gear, dramatic clouds, RPG mountain expedition start, vertical',
    },
    {
      'id': 'athlete_3_2',
      'name': 'Peak Conditioning',
      'prompt':
          'Rocky mountain ledge with a natural training platform, wind-swept, clouds below, alpine flowers, RPG altitude training, vertical',
    },
    {
      'id': 'athlete_3_3',
      'name': 'Iron Will',
      'prompt':
          'Iron forge built into the mountainside, glowing hot metal, anvil and hammer, determination atmosphere, RPG smithing mountain, vertical',
    },
    {
      'id': 'athlete_3_4',
      'name': 'Altitude Training',
      'prompt':
          'High altitude plateau above the clouds, thin air feel, prayer flags fluttering, distant peaks, RPG mountain monastery, vertical',
    },
    {
      'id': 'athlete_3_5',
      'name': 'Summit Master',
      'prompt':
          'Breathtaking mountain summit at golden sunrise, panoramic vista, snow-capped peak, triumphant achievement atmosphere, RPG legendary pinnacle, vertical',
    },
    // STAGE 4: SKY CITADEL (Radiant - Levels 16-20)
    {
      'id': 'athlete_4_1',
      'name': 'Cloud Bridge',
      'prompt':
          'Ethereal bridge made of solidified clouds connecting two floating peaks, rainbow light, sky realm entrance, RPG radiant environment, vertical',
    },
    {
      'id': 'athlete_4_2',
      'name': 'Storm Arena',
      'prompt':
          'Floating colosseum in a thunderstorm, lightning crackling around the edges, epic battle arena in the sky, RPG storm challenge, vertical',
    },
    {
      'id': 'athlete_4_3',
      'name': 'Wind Sprint',
      'prompt':
          'Narrow crystal pathway through powerful wind corridors, streaks of light, speed and agility atmosphere, RPG sky race track, vertical',
    },
    {
      'id': 'athlete_4_4',
      'name': 'Thunder Peak',
      'prompt':
          'Mountain peak struck by constant lightning, energy crackling, power accumulation point, RPG elemental mastery, vertical',
    },
    {
      'id': 'athlete_4_5',
      'name': 'Sky Citadel',
      'prompt':
          'Grand floating fortress above the clouds, golden spires, radiant light emanating from windows, RPG sky castle milestone, vertical',
    },
    // STAGE 5: BEYOND (Ascended - Levels 21-25)
    {
      'id': 'athlete_5_1',
      'name': 'Astral Fields',
      'prompt':
          'Vast astral plane with nebula-colored grass, stars visible in the sky, transcendent atmosphere, RPG ascended realm, vertical',
    },
    {
      'id': 'athlete_5_2',
      'name': 'Cosmic Arena',
      'prompt':
          'Arena floating in deep space, surrounded by galaxies, cosmic energy barriers, ultimate challenge ground, RPG cosmic battle, vertical',
    },
    {
      'id': 'athlete_5_3',
      'name': 'Infinity Run',
      'prompt':
          'Endless crystal pathway spiraling through a cosmos of stars and nebulae, runner silhouette, transcendent speed, RPG infinite path, vertical',
    },
    {
      'id': 'athlete_5_4',
      'name': 'Titan Forge',
      'prompt':
          'Cosmic forge where stars are born, molten energy, creation of legendary artifacts, RPG titan crafting, vertical',
    },
    {
      'id': 'athlete_5_5',
      'name': 'Eternal Summit',
      'prompt':
          'Peak beyond all peaks, floating at the edge of the universe, pure golden energy, ultimate transcendence, RPG ascended pinnacle, vertical',
    },
  ],
  'scholar': [
    // STAGE 1: STUDY (Phantom - Levels 1-5)
    {
      'id': 'scholar_1_1',
      'name': 'First Page',
      'prompt':
          'Ancient dusty study room with a single open book glowing softly, candlelight, scrolls and ink, RPG scholar beginning, mystic library, vertical',
    },
    {
      'id': 'scholar_1_2',
      'name': 'Inkwell',
      'prompt':
          'Ornate writing desk with magical inkwell, letters floating in the air, quill and parchment, RPG scholarly environment, vertical',
    },
    {
      'id': 'scholar_1_3',
      'name': 'Logic Gate',
      'prompt':
          'Stone archway covered in mathematical symbols and runes, puzzle gate that opens with knowledge, RPG intellect trial, vertical',
    },
    {
      'id': 'scholar_1_4',
      'name': 'Memory Palace',
      'prompt':
          'Interior of a vast mind palace, floating memories as glowing orbs, architectural corridors of thought, RPG mental construct, vertical',
    },
    {
      'id': 'scholar_1_5',
      'name': 'Library Entrance',
      'prompt':
          'Grand entrance to an ancient crystal library, towering bookshelves visible inside, magical barrier, RPG milestone portal, vertical',
    },
    // STAGE 2: LIBRARY (Construct - Levels 6-10)
    {
      'id': 'scholar_2_1',
      'name': 'Archive Hall',
      'prompt':
          'Vast underground archive hall with infinite rows of glowing books, floating lanterns, RPG library of knowledge, vertical',
    },
    {
      'id': 'scholar_2_2',
      'name': 'Research Lab',
      'prompt':
          'Alchemical research laboratory with bubbling potions, star charts on walls, floating instruments, RPG scholar lab, vertical',
    },
    {
      'id': 'scholar_2_3',
      'name': 'Debate Chamber',
      'prompt':
          'Grand debate amphitheater with floating podiums, spectral scholars arguing, RPG intellectual arena, vertical',
    },
    {
      'id': 'scholar_2_4',
      'name': 'Cipher Room',
      'prompt':
          'Room filled with rotating cipher wheels, encoded messages floating in air, puzzle-solving atmosphere, RPG code breaker, vertical',
    },
    {
      'id': 'scholar_2_5',
      'name': 'Knowledge Master',
      'prompt':
          'Throne of books at the center of the library, knowledge radiating outward as golden light, RPG mastery achievement, vertical',
    },
    // STAGE 3: OBSERVATORY (Incarnate - Levels 11-15)
    {
      'id': 'scholar_3_1',
      'name': 'Star Corridor',
      'prompt':
          'Corridor in a floating observatory, glass walls showing outer space, star maps on surfaces, RPG cosmic hallway, vertical',
    },
    {
      'id': 'scholar_3_2',
      'name': 'Orrery Chamber',
      'prompt':
          'Massive brass orrery with planets orbiting, mechanical solar system model, steampunk-fantasy observatory, RPG astronomical, vertical',
    },
    {
      'id': 'scholar_3_3',
      'name': 'Telescope Peak',
      'prompt':
          'Observatory dome on a mountain peak, giant telescope pointed at nebula, stars reflected on marble floor, RPG stargazing, vertical',
    },
    {
      'id': 'scholar_3_4',
      'name': 'Theorem Hall',
      'prompt':
          'Grand hall with floating mathematical equations and proofs, light bending through prisms, RPG mathematical beauty, vertical',
    },
    {
      'id': 'scholar_3_5',
      'name': 'Cosmic Lens',
      'prompt':
          'Giant lens floating in space, focusing starlight into pure knowledge, enlightenment atmosphere, RPG cosmic mastery, vertical',
    },
    // STAGE 4: ACADEMY (Radiant - Levels 16-20)
    {
      'id': 'scholar_4_1',
      'name': 'Academy Gates',
      'prompt':
          'Grand gates of an arcane academy floating in aurora borealis, magical energy crackling, RPG radiant school entrance, vertical',
    },
    {
      'id': 'scholar_4_2',
      'name': 'Arcane Lab',
      'prompt':
          'High-tech magical laboratory with energy reactors, spell formulas on holographic displays, RPG advanced research, vertical',
    },
    {
      'id': 'scholar_4_3',
      'name': 'Quantum Study',
      'prompt':
          'Room where reality bends, multiple dimensions visible simultaneously, paradox visualization, RPG quantum realm, vertical',
    },
    {
      'id': 'scholar_4_4',
      'name': 'Grand Thesis',
      'prompt':
          'Lecture hall where the scholars thesis manifests as a living construct of light, RPG intellectual triumph, vertical',
    },
    {
      'id': 'scholar_4_5',
      'name': 'Wisdom Spire',
      'prompt':
          'Towering crystal spire of pure crystallized wisdom, radiating knowledge energy, RPG radiant milestone, vertical',
    },
    // STAGE 5: TRANSCENDENCE (Ascended - Levels 21-25)
    {
      'id': 'scholar_5_1',
      'name': 'Mind Nexus',
      'prompt':
          'Vast neural network visualization in cosmic space, synapses firing as stars, RPG mind ascension, vertical',
    },
    {
      'id': 'scholar_5_2',
      'name': 'Akashic Record',
      'prompt':
          'Infinite ethereal library containing all knowledge ever written, pages floating like galaxies, RPG akashic records, vertical',
    },
    {
      'id': 'scholar_5_3',
      'name': 'Truth Forge',
      'prompt':
          'Forge of absolute truth where raw knowledge is purified into wisdom, golden fire, RPG truth creation, vertical',
    },
    {
      'id': 'scholar_5_4',
      'name': 'Omniscient Eye',
      'prompt':
          'Giant cosmic eye that sees all knowledge simultaneously, fractal patterns, RPG omniscience, vertical',
    },
    {
      'id': 'scholar_5_5',
      'name': 'Eternal Scholar',
      'prompt':
          'Scholar silhouette made of pure starlight, floating in the center of all knowledge, RPG ascended intellect, vertical',
    },
  ],
  'creator': [
    // STAGE 1: GARDEN (Phantom - Levels 1-5)
    {
      'id': 'creator_1_1',
      'name': 'Seed Bed',
      'prompt':
          'Magical garden plot where first seeds are being planted, colorful soil, tiny sprouts of light, RPG creator beginning, vertical',
    },
    {
      'id': 'creator_1_2',
      'name': 'Color Spring',
      'prompt':
          'Natural spring that flows with liquid colors instead of water, rainbow mist, painting atmosphere, RPG color magic, vertical',
    },
    {
      'id': 'creator_1_3',
      'name': 'Sketch Grove',
      'prompt':
          'Forest grove where trees are made of pencil lines, sketched landscape coming to life, RPG creative awakening, vertical',
    },
    {
      'id': 'creator_1_4',
      'name': 'Melody Path',
      'prompt':
          'Pathway made of musical notes, sound waves visible in the air, harmonious environment, RPG music trail, vertical',
    },
    {
      'id': 'creator_1_5',
      'name': 'Forge Garden',
      'prompt':
          'Garden where a forge grows naturally from the earth, flowers made of metal, creation point, RPG milestone portal, vertical',
    },
    // STAGE 2: WORKSHOP (Construct - Levels 6-10)
    {
      'id': 'creator_2_1',
      'name': 'Loom Chamber',
      'prompt':
          'Vast chamber with magical looms weaving reality, threads of light, fabric of creation, RPG weaver workshop, vertical',
    },
    {
      'id': 'creator_2_2',
      'name': 'Clay Studio',
      'prompt':
          'Enchanted pottery studio where clay shapes itself, floating sculptures, creative energy visible, RPG sculptor space, vertical',
    },
    {
      'id': 'creator_2_3',
      'name': 'Paint Storm',
      'prompt':
          'Storm of swirling paint colors in a magical space, brushstrokes forming landscapes, RPG art storm, vertical',
    },
    {
      'id': 'creator_2_4',
      'name': 'Harmony Hall',
      'prompt':
          'Concert hall where instruments play themselves, visible sound waves, symphony of creation, RPG musical mastery, vertical',
    },
    {
      'id': 'creator_2_5',
      'name': 'Master Artisan',
      'prompt':
          'Artisan throne made of every creative medium, paint, clay, music, surrounded by masterworks, RPG creative mastery, vertical',
    },
    // STAGE 3: GALLERY (Incarnate - Levels 11-15)
    {
      'id': 'creator_3_1',
      'name': 'Living Gallery',
      'prompt':
          'Art gallery where paintings are alive and moving, visitors walking through living art, RPG living museum, vertical',
    },
    {
      'id': 'creator_3_2',
      'name': 'Dream Canvas',
      'prompt':
          'Massive floating canvas in a dreamscape, painting itself with subconscious imagery, RPG dream art, vertical',
    },
    {
      'id': 'creator_3_3',
      'name': 'Sculpture Peak',
      'prompt':
          'Mountain peak carved into a massive sculpture, the mountain itself is art, clouds swirling around, RPG monumental art, vertical',
    },
    {
      'id': 'creator_3_4',
      'name': 'Muse Temple',
      'prompt':
          'Ancient temple dedicated to the muses, inspiration flowing as golden light, RPG muse sanctuary, vertical',
    },
    {
      'id': 'creator_3_5',
      'name': 'Opus Hall',
      'prompt':
          'Grand hall displaying the creators magnum opus, light radiating from centerpiece, RPG creative pinnacle, vertical',
    },
    // STAGE 4: STUDIO (Radiant - Levels 16-20)
    {
      'id': 'creator_4_1',
      'name': 'Aurora Studio',
      'prompt':
          'Studio floating in aurora borealis, painting with northern lights, colors flowing everywhere, RPG radiant creativity, vertical',
    },
    {
      'id': 'creator_4_2',
      'name': 'Reality Brush',
      'prompt':
          'Giant paintbrush painting reality itself into existence, landscapes forming from brushstrokes, RPG reality creation, vertical',
    },
    {
      'id': 'creator_4_3',
      'name': 'Synesthesia',
      'prompt':
          'Space where all senses merge, sounds visible as colors, touch creates music, RPG sensory fusion, vertical',
    },
    {
      'id': 'creator_4_4',
      'name': 'Living Art',
      'prompt':
          'Art pieces that have become sentient and are creating their own art, recursive creation, RPG living masterpiece, vertical',
    },
    {
      'id': 'creator_4_5',
      'name': 'Creation Nexus',
      'prompt':
          'Central nexus where all creative energy converges, explosion of color and form, RPG radiant milestone, vertical',
    },
    // STAGE 5: TRANSCENDENCE (Ascended - Levels 21-25)
    {
      'id': 'creator_5_1',
      'name': 'Cosmic Palette',
      'prompt':
          'Palette floating in deep space, mixing galaxies and nebulae as paint colors, RPG cosmic creation, vertical',
    },
    {
      'id': 'creator_5_2',
      'name': 'Genesis Point',
      'prompt':
          'The point where the universe was first created, pure creative energy, big bang visualization, RPG genesis origin, vertical',
    },
    {
      'id': 'creator_5_3',
      'name': 'Dream Weaver',
      'prompt':
          'Ethereal being weaving dreams into reality, threads of starlight, RPG dream weaving, vertical',
    },
    {
      'id': 'creator_5_4',
      'name': 'Infinity Canvas',
      'prompt':
          'Canvas that extends infinitely in all directions, containing all possible art ever created, RPG infinite creation, vertical',
    },
    {
      'id': 'creator_5_5',
      'name': 'Eternal Creator',
      'prompt':
          'Creator becoming one with the creative force itself, pure energy of imagination, RPG ascended creator, vertical',
    },
  ],
  'stoic': [
    // STAGE 1: GARDEN (Phantom - Levels 1-5)
    {
      'id': 'stoic_1_1',
      'name': 'Still Water',
      'prompt':
          'Perfectly still zen pond reflecting mountains, single lotus flower, absolute serenity, RPG stoic beginning, vertical',
    },
    {
      'id': 'stoic_1_2',
      'name': 'Stone Path',
      'prompt':
          'Ancient stone path through a minimalist zen garden, raked sand patterns, deliberate simplicity, RPG stoic walkway, vertical',
    },
    {
      'id': 'stoic_1_3',
      'name': 'Focus Chamber',
      'prompt':
          'Minimal meditation chamber with a single candle flame, stone walls, perfect stillness, RPG focus trial, vertical',
    },
    {
      'id': 'stoic_1_4',
      'name': 'Patience Rock',
      'prompt':
          'Massive patient rock in a river, water flowing around it for millennia, erosion beauty, RPG patience symbol, vertical',
    },
    {
      'id': 'stoic_1_5',
      'name': 'Temple Gate',
      'prompt':
          'Grand torii gate at the entrance to an ancient temple, cherry blossoms falling, zen atmosphere, RPG milestone gate, vertical',
    },
    // STAGE 2: TEMPLE (Construct - Levels 6-10)
    {
      'id': 'stoic_2_1',
      'name': 'Meditation Hall',
      'prompt':
          'Vast meditation hall with floating cushions, incense smoke forming patterns, serene blue light, RPG zen temple, vertical',
    },
    {
      'id': 'stoic_2_2',
      'name': 'Bamboo Forest',
      'prompt':
          'Towering bamboo forest with filtered green light, wind creating natural music, contemplation path, RPG bamboo grove, vertical',
    },
    {
      'id': 'stoic_2_3',
      'name': 'Trial of Silence',
      'prompt':
          'Chamber where all sound is absorbed, perfect visual of silence, floating feathers frozen in time, RPG silence trial, vertical',
    },
    {
      'id': 'stoic_2_4',
      'name': 'Balance Bridge',
      'prompt':
          'Impossibly thin bridge over vast chasm, perfect balance required, clouds below, RPG balance challenge, vertical',
    },
    {
      'id': 'stoic_2_5',
      'name': 'Inner Master',
      'prompt':
          'Inner sanctum of the temple, golden buddha-like statue emanating peace, RPG stoic mastery, vertical',
    },
    // STAGE 3: FORTRESS (Incarnate - Levels 11-15)
    {
      'id': 'stoic_3_1',
      'name': 'Iron Gate',
      'prompt':
          'Massive iron gate of an impenetrable mental fortress, stoic architecture, unbreakable walls, RPG mental fortress, vertical',
    },
    {
      'id': 'stoic_3_2',
      'name': 'Discipline Tower',
      'prompt':
          'Tall austere tower of pure discipline, minimal design, strong foundations, RPG discipline monument, vertical',
    },
    {
      'id': 'stoic_3_3',
      'name': 'Virtue Hall',
      'prompt':
          'Hall with statues representing cardinal virtues, justice wisdom courage temperance, RPG virtue gallery, vertical',
    },
    {
      'id': 'stoic_3_4',
      'name': 'Calm Storm',
      'prompt':
          'Eye of a massive storm, perfect calm in the center while chaos rages around, RPG inner peace, vertical',
    },
    {
      'id': 'stoic_3_5',
      'name': 'Unshakable',
      'prompt':
          'Mountain that has withstood every storm, ancient and immovable, ultimate stability, RPG stoic pinnacle, vertical',
    },
    // STAGE 4: VOID (Radiant - Levels 16-20)
    {
      'id': 'stoic_4_1',
      'name': 'Void Entry',
      'prompt':
          'Entrance to the void, where all distraction falls away, pure emptiness with faint starlight, RPG void gateway, vertical',
    },
    {
      'id': 'stoic_4_2',
      'name': 'Echo Chamber',
      'prompt':
          'Chamber where only truth echoes back, reflective surfaces showing inner self, RPG truth reflection, vertical',
    },
    {
      'id': 'stoic_4_3',
      'name': 'Will Forge',
      'prompt':
          'Forge of willpower, hammering weakness into strength, sparks of determination, RPG will forging, vertical',
    },
    {
      'id': 'stoic_4_4',
      'name': 'Acceptance Pool',
      'prompt':
          'Serene pool that shows reality as it truly is, no illusion, perfect acceptance, RPG acceptance meditation, vertical',
    },
    {
      'id': 'stoic_4_5',
      'name': 'Sage Throne',
      'prompt':
          'Simple stone throne of the sage, wisdom radiating outward, minimal but powerful, RPG radiant milestone, vertical',
    },
    // STAGE 5: TRANSCENDENCE (Ascended - Levels 21-25)
    {
      'id': 'stoic_5_1',
      'name': 'Eternal Calm',
      'prompt':
          'Infinite calm ocean under stars, no waves, perfect mirror, RPG stoic transcendence, vertical',
    },
    {
      'id': 'stoic_5_2',
      'name': 'Mind Palace',
      'prompt':
          'Vast constructed mind palace, infinite rooms of organized thought, RPG mental architecture, vertical',
    },
    {
      'id': 'stoic_5_3',
      'name': 'Fate Acceptance',
      'prompt':
          'Standing at crossroads where all paths lead to peace, amor fati visualization, RPG fate acceptance, vertical',
    },
    {
      'id': 'stoic_5_4',
      'name': 'Stone Eternal',
      'prompt':
          'Ancient stone that has existed since the beginning of time, witnessing all, RPG eternal stoic, vertical',
    },
    {
      'id': 'stoic_5_5',
      'name': 'The Sage',
      'prompt':
          'Pure energy of stoic wisdom, beyond form, pure equanimity, RPG ascended sage, vertical',
    },
  ],
  'zealot': [
    // STAGE 1: SHRINE (Phantom - Levels 1-5)
    {
      'id': 'zealot_1_1',
      'name': 'First Flame',
      'prompt':
          'Single sacred flame burning in darkness, devotional candle, beginning of faith journey, RPG zealot spark, vertical',
    },
    {
      'id': 'zealot_1_2',
      'name': 'Inner Fire',
      'prompt':
          'Fire burning within a crystal heart, inner devotion becoming visible, RPG inner flame, vertical',
    },
    {
      'id': 'zealot_1_3',
      'name': 'Prayer Stones',
      'prompt':
          'Circle of prayer stones in a sacred grove, each stone glowing with collected prayers, RPG prayer site, vertical',
    },
    {
      'id': 'zealot_1_4',
      'name': 'Faith Trial',
      'prompt':
          'Walking across hot coals, faith enabling the impossible, fire not burning, RPG faith trial, vertical',
    },
    {
      'id': 'zealot_1_5',
      'name': 'Sacred Threshold',
      'prompt':
          'Threshold of a grand sacred temple, divine light pouring through doorway, RPG faith milestone, vertical',
    },
    // STAGE 2: TEMPLE (Construct - Levels 6-10)
    {
      'id': 'zealot_2_1',
      'name': 'Devotion Hall',
      'prompt':
          'Grand temple hall with floating prayer lanterns, golden light, sacred chanting atmosphere, RPG devotion space, vertical',
    },
    {
      'id': 'zealot_2_2',
      'name': 'Ritual Chamber',
      'prompt':
          'Sacred ritual chamber with arcane symbols on floor, incense and candles, ceremonial energy, RPG ritual space, vertical',
    },
    {
      'id': 'zealot_2_3',
      'name': 'Cleansing Falls',
      'prompt':
          'Sacred waterfall used for spiritual cleansing, crystal-clear water, rainbow mist, RPG purification site, vertical',
    },
    {
      'id': 'zealot_2_4',
      'name': 'Oath Stone',
      'prompt':
          'Ancient stone altar where sacred oaths are sworn, lightning striking the stone, commitment energy, RPG oath binding, vertical',
    },
    {
      'id': 'zealot_2_5',
      'name': 'Temple Master',
      'prompt':
          'Inner sanctum of the sacred temple, divine light column from above, mastery of devotion, RPG temple mastery, vertical',
    },
    // STAGE 3: SANCTUM (Incarnate - Levels 11-15)
    {
      'id': 'zealot_3_1',
      'name': 'Holy Ground',
      'prompt':
          'Ground that radiates divine golden energy, flowers growing instantly, sacred earth, RPG holy site, vertical',
    },
    {
      'id': 'zealot_3_2',
      'name': 'Spirit Walk',
      'prompt':
          'Path through the spirit realm, transparent world overlaying physical, ancestors walking alongside, RPG spirit journey, vertical',
    },
    {
      'id': 'zealot_3_3',
      'name': 'Fervor Peak',
      'prompt':
          'Mountain peak with perpetual sacred fire, pilgrimage destination, zealous energy, RPG fervor summit, vertical',
    },
    {
      'id': 'zealot_3_4',
      'name': 'Covenant Arc',
      'prompt':
          'Golden arc of covenant energy, binding promise to the divine, RPG sacred covenant, vertical',
    },
    {
      'id': 'zealot_3_5',
      'name': 'Divine Gate',
      'prompt':
          'Massive gate opening to divine realm, blinding golden light beyond, RPG divine threshold, vertical',
    },
    // STAGE 4: ETHEREAL (Radiant - Levels 16-20)
    {
      'id': 'zealot_4_1',
      'name': 'Spirit Forge',
      'prompt':
          'Forge where spirit weapons are crafted from pure faith, holy fire, RPG spirit forging, vertical',
    },
    {
      'id': 'zealot_4_2',
      'name': 'Prophecy Pool',
      'prompt':
          'Sacred pool that shows visions of the future, surface rippling with prophecy, RPG divination, vertical',
    },
    {
      'id': 'zealot_4_3',
      'name': 'Radiant Path',
      'prompt':
          'Path made of pure radiant light leading upward, angelic energy, RPG radiant ascent, vertical',
    },
    {
      'id': 'zealot_4_4',
      'name': 'Sacred Storm',
      'prompt':
          'Storm of holy energy, lightning of divine power, purifying tempest, RPG sacred storm, vertical',
    },
    {
      'id': 'zealot_4_5',
      'name': 'Eternal Flame',
      'prompt':
          'The eternal flame that never dies, source of all sacred fire, RPG radiant milestone, vertical',
    },
    // STAGE 5: DIVINE (Ascended - Levels 21-25)
    {
      'id': 'zealot_5_1',
      'name': 'Heaven Gate',
      'prompt':
          'Gates of a celestial realm opening, divine chorus of light, RPG heaven entrance, vertical',
    },
    {
      'id': 'zealot_5_2',
      'name': 'Angel Court',
      'prompt':
          'Court of celestial beings, golden architecture, divine judgment hall, RPG celestial court, vertical',
    },
    {
      'id': 'zealot_5_3',
      'name': 'Divine Trial',
      'prompt':
          'Final trial of faith, walking through divine fire unharmed, ultimate devotion test, RPG divine trial, vertical',
    },
    {
      'id': 'zealot_5_4',
      'name': 'Sacred Unity',
      'prompt':
          'All faiths converging into one pure light of devotion, unity of spirit, RPG sacred convergence, vertical',
    },
    {
      'id': 'zealot_5_5',
      'name': 'The Ascended',
      'prompt':
          'Being of pure divine energy, transcended beyond mortal form, RPG ascended zealot, vertical',
    },
  ],
  'explorer': [
    // STAGE 1: WILDERNESS (Phantom - Levels 1-5)
    {
      'id': 'explorer_1_1',
      'name': 'Open Road',
      'prompt':
          'Sun-drenched dirt road stretching towards a distant golden horizon, wide open plains, adventure beginning, RPG explorer starting area, vertical',
    },
    {
      'id': 'explorer_1_2',
      'name': 'Ancient Map',
      'prompt':
          'Close up of an aged tattered map on a wooden table, compass and lantern, mysterious markings, RPG quest discovery, vertical',
    },
    {
      'id': 'explorer_1_3',
      'name': 'Hidden Path',
      'prompt':
          'Faint overgrown trail leading through a misty forest, sunlight filtering through leaves, mystery and exploration, RPG secret passage, vertical',
    },
    {
      'id': 'explorer_1_4',
      'name': 'First Camp',
      'prompt':
          'Small campfire under a starry sky in a quiet valley, glowing embers, peaceful outdoor atmosphere, RPG rest area, vertical',
    },
    {
      'id': 'explorer_1_5',
      'name': 'Wilderness Gate',
      'prompt':
          'Natural stone archway framing a new diverse landscape, gateway to adventure, RPG exploration milestone, vertical',
    },
    // STAGE 2: ADAPTATION (Construct - Levels 6-10)
    {
      'id': 'explorer_2_1',
      'name': 'River Cross',
      'prompt':
          'Rushing mountain river with stepping stones, misty spray, vibrant vegetation, challenge of adaptation, RPG nature crossing, vertical',
    },
    {
      'id': 'explorer_2_2',
      'name': 'Desert Oasis',
      'prompt':
          'Hidden crystal clear pool in a vast sandy desert, palm trees, cool sanctuary, RPG survival milestone, vertical',
    },
    {
      'id': 'explorer_2_3',
      'name': 'Versatility Trial',
      'prompt':
          'Mechanical ruins with shifting platforms and gears, puzzle environment, testing all-around skill, RPG engineering challenge, vertical',
    },
    {
      'id': 'explorer_2_4',
      'name': 'Hidden Grotto',
      'prompt':
          'Underground cave with bioluminescent plants and glowing crystals reflected in a pool, secret beauty, RPG cave exploration, vertical',
    },
    {
      'id': 'explorer_2_5',
      'name': 'Pathfinder King',
      'prompt':
          'Ancient stone throne at the highest point of a central plateau, overlooking multiple biomes, RPG explorer mastery, vertical',
    },
    // STAGE 3: SUMMIT (Incarnate - Levels 11-15)
    {
      'id': 'explorer_3_1',
      'name': 'Convergence Point',
      'prompt':
          'Place where snow, forest, and desert meet in a magical convergence, swirling elemental energy, RPG world center, vertical',
    },
    {
      'id': 'explorer_3_2',
      'name': 'Sky Path',
      'prompt':
          'High altitude crystal walkway between floating islands, clouds far below, thin air atmosphere, RPG aerial exploration, vertical',
    },
    {
      'id': 'explorer_3_3',
      'name': 'Ruins of Time',
      'prompt':
          'Ancient crumbling clocktower in a jungle, overgrown with vines, time-bending energy, RPG temporal ruins, vertical',
    },
    {
      'id': 'explorer_3_4',
      'name': 'Trailblazer\'s Legacy',
      'prompt':
          'Massive statue of an explorer built into a cliffside, overlooking a vast civilized world, legacy atmosphere, RPG icon, vertical',
    },
    {
      'id': 'explorer_3_5',
      'name': 'Pathfinder Ascended',
      'prompt':
          'Radiant portal opening at the peak of the world, glowing with pure potential, RPG ascension point, vertical',
    },
    // STAGE 4: FRONTIER (Radiant - Levels 16-20)
    {
      'id': 'explorer_4_1',
      'name': 'Uncharted Gate',
      'prompt':
          'Floating gate in the middle of a nebula, opening to dimensions of pure light, RPG radiant gateway, vertical',
    },
    {
      'id': 'explorer_4_2',
      'name': 'Prism Overlook',
      'prompt':
          'Vantage point where the atmosphere is made of rainbows, crystal terrain reflecting every color, RPG multi-faceted growth, vertical',
    },
    {
      'id': 'explorer_4_3',
      'name': 'Trial of Adaptation',
      'prompt':
          'Ever-changing landscape shifting between ice and fire, adaptation in real-time, RPG dynamic environment, vertical',
    },
    {
      'id': 'explorer_4_4',
      'name': 'Echoes of Mastery',
      'prompt':
          'Canyon where every sound manifests as a visual wave of light, reflecting past actions, RPG intuition valley, vertical',
    },
    {
      'id': 'explorer_4_5',
      'name': 'Radiant Milestone',
      'prompt':
          'Lighthouse at the edge of the universe, casting a beam of pure radiant energy across the void, RPG beacon, vertical',
    },
    // STAGE 5: ASCENDED (Ascended - Levels 21-25)
    {
      'id': 'explorer_5_1',
      'name': 'Void Stepper',
      'prompt':
          'Walking on a path of starlight across the infinite void, galaxies below, RPG cosmic explorer, vertical',
    },
    {
      'id': 'explorer_5_2',
      'name': 'Nexus of All',
      'prompt':
          'Central hub of the multiverse where all possibilities coexist, complex geometric architecture, RPG harmonic center, vertical',
    },
    {
      'id': 'explorer_5_3',
      'name': 'Infinite Trial',
      'prompt':
          'Recursive landscape that repeats infinitely, test of absolute persistence and focus, RPG infinite loops, vertical',
    },
    {
      'id': 'explorer_5_4',
      'name': 'Path\'s End',
      'prompt':
          'A simple wooden bench at the end of the universe, looking back at everything created, perfect peace, RPG reflection, vertical',
    },
    {
      'id': 'explorer_5_5',
      'name': 'The Ultimate Emerge',
      'prompt':
          'The explorer becoming the world itself, pure energy merging with all existence, RPG ultimate ascension, vertical',
    },
  ],
};

Future<void> main(List<String> args) async {
  final isDryRun = args.contains('--dry-run');
  // Extract archetype after --archetype flag if present
  String? filterArchetype;
  final archetypeIdx = args.indexOf('--archetype');
  if (archetypeIdx >= 0 && archetypeIdx + 1 < args.length) {
    filterArchetype = args[archetypeIdx + 1];
  }

  final outputDir = 'assets/images/levels';
  final width = 1080;
  final height = 1920;
  final model = 'flux';

  print('🎨 Emerge Level Background Generator');
  print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
  print('Output: $outputDir/{archetype}/{node_id}.png');
  print('Size: ${width}x$height | Model: $model');
  if (isDryRun) print('🔍 DRY RUN — prompts only, no downloads');
  if (filterArchetype != null) print('🎯 Filtering: $filterArchetype only');
  print('');

  int total = 0;
  int generated = 0;
  int skipped = 0;
  int failed = 0;

  final client = HttpClient();

  for (final entry in archetypeNodes.entries) {
    final archetype = entry.key;
    final nodes = entry.value;

    if (filterArchetype != null && archetype != filterArchetype) continue;

    print('\\n📂 $archetype (${nodes.length} nodes)');
    print('─────────────────────────────────────');

    // Create directory
    final dir = Directory('$outputDir/$archetype');
    if (!isDryRun && !dir.existsSync()) {
      dir.createSync(recursive: true);
    }

    for (final node in nodes) {
      total++;
      final id = node['id']!;
      final name = node['name']!;
      final prompt = node['prompt']!;
      final outputFile = File('$outputDir/$archetype/$id.png');

      // Skip if already exists
      if (!isDryRun && outputFile.existsSync()) {
        print('  ⏭️  $name ($id) — already exists');
        skipped++;
        continue;
      }

      if (isDryRun) {
        print('  📝 $name ($id)');
        print('     Prompt: ${prompt.substring(0, 80)}...');
        continue;
      }

      // Generate image
      final encodedPrompt = Uri.encodeComponent(prompt);
      final apiKey = 'sk_OGhhzmGVPhl6FFdSSHKiyAnHEx48dHlj';
      // Official authenticated endpoint and parameters from guide
      final url =
          'https://gen.pollinations.ai/image/$encodedPrompt?model=$model&width=$width&height=$height&enhance=true&safe=true';

      print('  🎨 Generating: $name ($id)...');

      if (isDryRun) {
        print('    [Dry Run] Request URL: $url');
        continue;
      }

      try {
        final request = await client.getUrl(Uri.parse(url));
        request.headers.add('Authorization', 'Bearer $apiKey');
        request.headers.add('Accept', 'image/*');
        final response = await request.close();

        if (response.statusCode == 200) {
          final bytes = <int>[];
          await for (final chunk in response) {
            bytes.addAll(chunk);
          }
          await outputFile.writeAsBytes(bytes);
          generated++;
          print('  ✅ Saved: ${outputFile.path} (${bytes.length ~/ 1024} KB)');
        } else {
          failed++;
          print('  ❌ Failed: HTTP ${response.statusCode}');
          // Read error body if possible
          final errorBody = await response.transform(utf8.decoder).join();
          print('     Error: $errorBody');
        }

        // Rate limit: wait between requests as per guide (30-120s is for gen time, but API call is async)
        // We'll wait a bit to avoid overwhelming the connection
        await Future.delayed(const Duration(seconds: 3));
      } catch (e) {
        failed++;
        print('  ❌ Error: $e');
      }
    }
  }
  client.close();

  print('\\n━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
  print('📊 Summary:');
  print('   Total: $total');
  print('   Generated: $generated');
  print('   Skipped: $skipped');
  print('   Failed: $failed');
  print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
}
