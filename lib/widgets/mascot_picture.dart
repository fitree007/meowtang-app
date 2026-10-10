import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'mascot_accessories_3d.dart';

/// 3D-rendered mascot pictures (`assets/mascots/<id>.webp`, 512×768, transparent)
/// and where code-drawn accessories attach on each of them.
class MascotPictures {
  MascotPictures._();

  /// Mascots that have a picture. Others fall back to the code-drawn painter.
  static const Set<String> available = {
    'cat_meowtang',
    'cat_quill',
    'cat_black',
    'cat_persian',
    'cat_calico',
    'cat_muslim',
    'cat_samurai',
    'cat_siamese',
    'cat_grey',
    'cat_tuxedo',
    'cat_pink',
    'cat_egypt',
    'cat_sphynx',
    'cat_golden',
    'shiba_gold',
    'lion_gold',
    'panda_saver',
    'fox_smart',
    'owl_wise',
    'rabbit_rich',
    'bear_wealth',
    'robot_ai',
  };

  static String asset(String id) => 'assets/mascots/$id.webp';

  /// Accessory already part of the picture (e.g. the Muslim cat's kufi):
  /// choosing it draws nothing extra.
  static const Map<String, String> builtIn = {
    'cat_muslim': 'songkok',
    'cat_samurai': 'headband',
    'cat_tuxedo': 'bowtie',
    'cat_pink': 'flower',
    'cat_quill': 'pen',
    'cat_grey': 'gold_shades',
  };

  static final Map<String, MascotAnchors> _anchors = {
    'cat_meowtang': MascotAnchors.meowtang,
    'cat_quill': MascotAnchors.fromEyes(const Offset(0.32, 0.477), const Offset(0.738, 0.435)),
    'cat_black': MascotAnchors.fromEyes(const Offset(0.33, 0.485), const Offset(0.738, 0.437)),
    'cat_persian': MascotAnchors.fromEyes(const Offset(0.355, 0.472), const Offset(0.68, 0.447)),
    'cat_calico': MascotAnchors.fromEyes(const Offset(0.33, 0.477), const Offset(0.73, 0.468)),
    'cat_muslim': MascotAnchors.fromEyes(const Offset(0.325, 0.452), const Offset(0.71, 0.452)),
    'cat_samurai': MascotAnchors.fromEyes(const Offset(0.32, 0.477), const Offset(0.725, 0.447)),
    'cat_siamese': MascotAnchors.fromEyes(const Offset(0.33, 0.488), const Offset(0.738, 0.438)),
    'cat_grey': MascotAnchors.fromEyes(const Offset(0.32, 0.46), const Offset(0.68, 0.45)),
    'cat_tuxedo': MascotAnchors.fromEyes(const Offset(0.343, 0.477), const Offset(0.738, 0.43)),
    'cat_pink': MascotAnchors.fromEyes(const Offset(0.33, 0.51), const Offset(0.733, 0.477)),
    'cat_egypt': MascotAnchors.fromEyes(const Offset(0.33, 0.518), const Offset(0.725, 0.452)),
    'cat_sphynx': MascotAnchors.fromEyes(const Offset(0.31, 0.493), const Offset(0.729, 0.438)),
    'cat_golden': MascotAnchors.fromEyes(const Offset(0.343, 0.46), const Offset(0.725, 0.438)),
    'shiba_gold': MascotAnchors.fromEyes(const Offset(0.341, 0.502), const Offset(0.713, 0.46)),
    'lion_gold': MascotAnchors.fromEyes(const Offset(0.338, 0.48), const Offset(0.70, 0.463)),
    'panda_saver': MascotAnchors.fromEyes(const Offset(0.356, 0.48), const Offset(0.71, 0.447)),
    'fox_smart': MascotAnchors.fromEyes(const Offset(0.33, 0.502), const Offset(0.731, 0.447)),
    'owl_wise': MascotAnchors.fromEyes(const Offset(0.35, 0.477), const Offset(0.719, 0.443)),
    'rabbit_rich': MascotAnchors.fromEyes(const Offset(0.35, 0.535), const Offset(0.725, 0.527)),
    'bear_wealth': MascotAnchors.fromEyes(const Offset(0.368, 0.471), const Offset(0.738, 0.462)),
    'robot_ai': MascotAnchors.fromEyes(const Offset(0.313, 0.49), const Offset(0.63, 0.49)),
  };

  static MascotAnchors anchorsFor(String id) => _anchors[id] ?? MascotAnchors.meowtang;
}

/// Square view of a mascot picture with its 3D accessory.
///
/// [headOnly] zooms on the face for small avatars; otherwise the upper body
/// (head, collar and waving paw) fills the square. Wearables sit on the
/// picture (wings and capes behind it); held items float at the bottom-right.
class MascotPicture extends StatelessWidget {
  final String mascotId;
  final double size;
  final bool headOnly;
  final String? accessory;

  const MascotPicture({
    super.key,
    required this.mascotId,
    required this.size,
    this.headOnly = false,
    this.accessory,
  });

  @override
  Widget build(BuildContext context) {
    final acc = accessory;
    final spec = (acc == null || acc == MascotPictures.builtIn[mascotId]) ? null : MascotAccessories.spec(acc);
    final anchors = MascotPictures.anchorsFor(mascotId);

    // Crop square as fractions of the 2:3 picture: left, top, side (of width).
    // Full view zooms out a little so the collar bell fits; head view keeps the ear tips.
    var (cx, cy, side) = headOnly ? (0.07, 0.12, 0.88) : (-0.06, 0.12, 1.12);
    final hatTop = spec == null ? null : MascotAccessories.topOf(spec, anchors);
    if (hatTop != null && hatTop - 0.015 < cy) {
      // Zoom out around the same bottom edge so a tall hat stays in frame.
      final bottom = cy + side / 1.5;
      final newSide = math.min((bottom - (hatTop - 0.015)) * 1.5, side * 1.3);
      cx -= (newSide - side) / 2;
      cy = bottom - newSide / 1.5;
      side = newSide;
    }
    final imgW = size / side;
    final imgH = imgW * 1.5;
    final worn = spec != null && spec.slot != AccessorySlot.held;
    final held = spec != null && spec.slot == AccessorySlot.held;
    final heldSize = size * (headOnly ? 0.38 : 0.46);

    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          ClipRect(
            child: SizedBox(
              width: size,
              height: size,
              child: Stack(
                clipBehavior: Clip.hardEdge,
                children: [
                  Positioned(
                    left: -cx * imgW,
                    top: -cy * imgH,
                    width: imgW,
                    height: imgH,
                    child: Stack(
                      clipBehavior: Clip.none,
                      children: [
                        if (worn && spec.isBehind)
                          MascotAccessories.placed(acc!, spec, anchors, imgW, imgH),
                        Positioned.fill(
                          child: Image.asset(
                            MascotPictures.asset(mascotId),
                            fit: BoxFit.fill,
                            filterQuality: FilterQuality.medium,
                            gaplessPlayback: true,
                          ),
                        ),
                        if (worn && !spec.isBehind)
                          MascotAccessories.placed(acc!, spec, anchors, imgW, imgH),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (held)
            Positioned(
              right: -size * 0.04,
              bottom: -size * 0.02,
              width: heldSize,
              height: heldSize,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  // Soft contact shadow so the item reads as floating in front.
                  Positioned(
                    bottom: heldSize * 0.02,
                    child: Container(
                      width: heldSize * 0.62,
                      height: heldSize * 0.14,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(heldSize),
                        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.22), blurRadius: heldSize * 0.08)],
                      ),
                    ),
                  ),
                  Transform.rotate(
                    angle: -0.14,
                    child: Image.asset(
                      MascotAccessories.asset(MascotAccessories.pictureId(acc!)),
                      width: heldSize * 0.9,
                      height: heldSize * 0.9,
                      fit: BoxFit.contain,
                      filterQuality: FilterQuality.medium,
                      gaplessPlayback: true,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
