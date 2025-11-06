// lib/core/constants/art_styles.dart
// AI art style definitions for Stability AI image generation

/// Represents an AI art style for iris transformation
class ArtStyle {
  final String id;
  final String name;
  final String description;
  final String prompt;
  final String negativePrompt;
  final double cfgScale; // Classifier Free Guidance scale
  final bool isPro; // Whether this is a premium/pro feature
  final String thumbnailAsset;
  final List<String> tags;

  const ArtStyle({
    required this.id,
    required this.name,
    required this.description,
    required this.prompt,
    this.negativePrompt = 'blurry, low quality, distorted, bad anatomy, watermark',
    this.cfgScale = 7.5,
    this.isPro = false,
    required this.thumbnailAsset,
    this.tags = const [],
  });

  // ============================================================
  // FREE STYLES (Available to all users)
  // ============================================================

  static const neonCyber = ArtStyle(
    id: 'neon_cyber',
    name: 'Neon Cyber',
    description: 'Futuristic cyberpunk with glowing neon colors',
    prompt: 'cyberpunk neon art style, vibrant electric colors, '
        'glowing iris patterns, futuristic digital art, high contrast, '
        'detailed eye structure, neon blue pink purple, sci-fi aesthetic, '
        'digital hologram effect',
    cfgScale: 8.0,
    thumbnailAsset: 'assets/styles/neon_cyber.jpg',
    tags: ['futuristic', 'vibrant', 'neon', 'cyberpunk'],
  );

  static const watercolorDream = ArtStyle(
    id: 'watercolor_dream',
    name: 'Watercolor Dream',
    description: 'Soft flowing watercolor with dreamy pastels',
    prompt: 'soft watercolor painting, flowing delicate colors, '
        'dreamy aesthetic, pastel tones, artistic iris rendering, '
        'gentle brush strokes, ethereal quality, painted on paper, '
        'artistic masterpiece',
    cfgScale: 7.0,
    thumbnailAsset: 'assets/styles/watercolor.jpg',
    tags: ['soft', 'dreamy', 'artistic', 'pastel'],
  );

  static const oilPainting = ArtStyle(
    id: 'oil_painting',
    name: 'Oil Painting',
    description: 'Classical oil painting with rich textures',
    prompt: 'classical oil painting, rich textures, masterpiece quality, '
        'renaissance style art, detailed iris with visible brush strokes, '
        'warm lighting, artistic rendering, canvas texture, museum quality',
    cfgScale: 7.5,
    thumbnailAsset: 'assets/styles/oil_painting.jpg',
    tags: ['classical', 'textured', 'artistic', 'renaissance'],
  );

  static const minimalistLine = ArtStyle(
    id: 'minimalist_line',
    name: 'Minimalist Line',
    description: 'Clean line art with minimal color palette',
    prompt: 'minimalist line art, clean simple lines, minimal color palette, '
        'elegant iris design, modern aesthetic, vector style, '
        'sophisticated simplicity',
    cfgScale: 7.0,
    thumbnailAsset: 'assets/styles/minimalist.jpg',
    tags: ['minimalist', 'modern', 'clean', 'elegant'],
  );

  // ============================================================
  // PRO STYLES (Premium subscription required)
  // ============================================================

  static const cosmicGalaxy = ArtStyle(
    id: 'cosmic_galaxy',
    name: 'Cosmic Galaxy',
    description: 'Celestial space art with nebula and stars',
    prompt: 'cosmic galaxy art, nebula colors, starfield, universe patterns, '
        'space aesthetic, mystical iris with celestial swirls, '
        'deep space colors, ethereal glow, astronomical beauty, '
        'interstellar artwork',
    cfgScale: 8.0,
    thumbnailAsset: 'assets/styles/cosmic.jpg',
    isPro: true,
    tags: ['cosmic', 'mystical', 'space', 'celestial'],
  );

  static const geometricGold = ArtStyle(
    id: 'geometric_gold',
    name: 'Geometric Gold',
    description: 'Sacred geometry with luxurious gold accents',
    prompt: 'sacred geometry art, gold foil accents, mandala patterns, '
        'luxury aesthetic, intricate iris with golden details, '
        'symmetrical design, metallic shine, ornate decoration, '
        'precious metal effect',
    cfgScale: 8.5,
    thumbnailAsset: 'assets/styles/geometric_gold.jpg',
    isPro: true,
    tags: ['luxury', 'geometric', 'elegant', 'gold'],
  );

  static const kaleidoscope = ArtStyle(
    id: 'kaleidoscope',
    name: 'Kaleidoscope',
    description: 'Mesmerizing symmetrical patterns',
    prompt: 'kaleidoscope art, symmetrical patterns, rainbow colors, '
        'mesmerizing design, iris with mirrored details, '
        'psychedelic aesthetic, vibrant mandala, hypnotic patterns, '
        'radial symmetry',
    cfgScale: 7.5,
    thumbnailAsset: 'assets/styles/kaleidoscope.jpg',
    isPro: true,
    tags: ['symmetrical', 'colorful', 'mesmerizing', 'psychedelic'],
  );

  static const inkSplatter = ArtStyle(
    id: 'ink_splatter',
    name: 'Ink Splatter',
    description: 'Dynamic black ink with dramatic contrast',
    prompt: 'ink splatter art, black and white, dynamic contrast, '
        'flowing ink patterns, artistic iris rendering, '
        'dramatic composition, high contrast, traditional ink painting, '
        'expressive brushwork',
    cfgScale: 7.0,
    thumbnailAsset: 'assets/styles/ink_splatter.jpg',
    isPro: true,
    tags: ['dramatic', 'monochrome', 'dynamic', 'ink'],
  );

  static const crystalPrism = ArtStyle(
    id: 'crystal_prism',
    name: 'Crystal Prism',
    description: 'Refracted light through crystalline structures',
    prompt: 'crystal prism art, refracted light, rainbow spectrum, '
        'crystalline structures, iris with light dispersion, '
        'gem-like quality, brilliant colors, diamond facets, '
        'prismatic effect',
    cfgScale: 8.0,
    thumbnailAsset: 'assets/styles/crystal_prism.jpg',
    isPro: true,
    tags: ['brilliant', 'prismatic', 'crystalline', 'rainbow'],
  );

  static const floraBotanical = ArtStyle(
    id: 'flora_botanical',
    name: 'Flora Botanical',
    description: 'Delicate botanical illustration with flowers',
    prompt: 'botanical illustration, delicate flowers, natural flora, '
        'iris surrounded by botanical elements, vintage botanical print, '
        'detailed plant life, nature-inspired art, organic patterns',
    cfgScale: 7.5,
    thumbnailAsset: 'assets/styles/flora.jpg',
    isPro: true,
    tags: ['botanical', 'natural', 'floral', 'organic'],
  );

  static const stainedGlass = ArtStyle(
    id: 'stained_glass',
    name: 'Stained Glass',
    description: 'Luminous stained glass window effect',
    prompt: 'stained glass art, colorful glass panels, lead lines, '
        'cathedral window style, iris in stained glass, '
        'translucent colors, light through glass, gothic art',
    cfgScale: 8.0,
    thumbnailAsset: 'assets/styles/stained_glass.jpg',
    isPro: true,
    tags: ['luminous', 'colorful', 'gothic', 'glass'],
  );

  static const abstractExpression = ArtStyle(
    id: 'abstract_expression',
    name: 'Abstract Expression',
    description: 'Bold abstract expressionism with vibrant energy',
    prompt: 'abstract expressionism, bold colors, energetic brushstrokes, '
        'expressive art, iris abstracted into dynamic forms, '
        'contemporary art style, vivid colors, artistic freedom',
    cfgScale: 7.5,
    thumbnailAsset: 'assets/styles/abstract.jpg',
    isPro: true,
    tags: ['abstract', 'bold', 'expressive', 'contemporary'],
  );

  // ============================================================
  // Collections
  // ============================================================

  /// Get all available art styles
  static List<ArtStyle> get allStyles => [
        neonCyber,
        watercolorDream,
        oilPainting,
        minimalistLine,
        cosmicGalaxy,
        geometricGold,
        kaleidoscope,
        inkSplatter,
        crystalPrism,
        floraBotanical,
        stainedGlass,
        abstractExpression,
      ];

  /// Get only free styles
  static List<ArtStyle> get freeStyles =>
      allStyles.where((s) => !s.isPro).toList();

  /// Get only pro styles
  static List<ArtStyle> get proStyles => allStyles.where((s) => s.isPro).toList();

  /// Get style by ID
  static ArtStyle? getById(String id) {
    try {
      return allStyles.firstWhere((s) => s.id == id);
    } catch (e) {
      return null;
    }
  }

  /// Get styles by tag
  static List<ArtStyle> getByTag(String tag) {
    return allStyles.where((s) => s.tags.contains(tag)).toList();
  }

  /// Get all unique tags
  static List<String> get allTags {
    final tags = <String>{};
    for (final style in allStyles) {
      tags.addAll(style.tags);
    }
    return tags.toList()..sort();
  }
}
