import 'dart:math' as math;
import 'package:flutter/material.dart';

/// Where accessories attach on one mascot picture, as fractions (0–1) of the
/// picture's width and height, so they line up at any display size.
class MascotAnchors {
  /// Top-centre of the head, where hats sit.
  final Offset headTop;

  /// Head width as a fraction of the picture width.
  final double headWidth;

  /// Head tilt in degrees (positive = clockwise).
  final double tilt;

  final Offset leftEye;
  final Offset rightEye;

  const MascotAnchors({
    required this.headTop,
    required this.headWidth,
    required this.leftEye,
    required this.rightEye,
    this.tilt = 0,
  });

  /// Anchors from where the glasses lenses should sit; the hat line and tilt
  /// follow the eyes, using the default cat's proportions.
  factory MascotAnchors.fromEyes(Offset leftEye, Offset rightEye) {
    final mid = Offset((leftEye.dx + rightEye.dx) / 2, (leftEye.dy + rightEye.dy) / 2);
    // Pictures are 2:3, so convert to pixels before measuring the angle.
    final tilt = math.atan2((rightEye.dy - leftEye.dy) * 1.5, rightEye.dx - leftEye.dx) * 180 / math.pi;
    return MascotAnchors(
      headTop: Offset(mid.dx - 0.02, mid.dy - 0.225),
      headWidth: 0.84,
      leftEye: leftEye,
      rightEye: rightEye,
      tilt: tilt,
    );
  }

  Offset get eyeMid => Offset((leftEye.dx + rightEye.dx) / 2, (leftEye.dy + rightEye.dy) / 2);

  /// Centre of the collar.
  Offset get neck => Offset(eyeMid.dx - 0.02, eyeMid.dy + 0.245);

  /// The default MeowTang cat picture (1024×1536).
  static const meowtang = MascotAnchors(
    headTop: Offset(0.515, 0.212),
    headWidth: 0.84,
    leftEye: Offset(0.332, 0.448),
    rightEye: Offset(0.737, 0.426),
    tilt: -4,
  );
}

/// Where an accessory goes on the mascot.
enum AccessorySlot {
  /// Hats and halos, from the top of the head; tilts with the head.
  head,

  /// Glasses, centred between the eyes; tilts with the head.
  face,

  /// Bow ties and scarves, at the collar.
  neck,

  /// Wings and capes, behind the picture, from the collar.
  back,

  /// Things the mascot shows off, floating beside it.
  held,
}

/// How one 3D accessory picture (`assets/mascots/acc/<id>.webp`, trimmed to
/// the object) is placed.
class AccessorySpec {
  final AccessorySlot slot;

  /// Width as a fraction of the picture width; for [AccessorySlot.face], a
  /// multiple of the distance between the eyes.
  final double width;

  /// Width / height of the accessory picture.
  final double aspect;

  /// Point of the accessory (fractions of its own size) that sits on the anchor.
  final Offset pivot;

  /// Shift from the anchor, in fractions of the picture.
  final Offset nudge;

  /// Extra rotation in degrees.
  final double rotate;

  /// Top part of the accessory to hide, for rings worn around the head or
  /// neck whose back edge would otherwise cross the face.
  final double clipTop;

  /// Bottom part of the accessory to hide.
  final double clipBottom;

  /// Draw behind the picture so the mascot covers its middle.
  final bool behind;

  const AccessorySpec(
    this.slot, {
    required this.width,
    required this.aspect,
    this.pivot = const Offset(0.5, 0.5),
    this.nudge = Offset.zero,
    this.rotate = 0,
    this.clipTop = 0,
    this.clipBottom = 0,
    this.behind = false,
  });

  bool get isBehind => behind || slot == AccessorySlot.back;
}

class MascotAccessories {
  MascotAccessories._();

  static String asset(String id) => 'assets/mascots/acc/$id.webp';

  /// Accessory ids that share another one's picture.
  static const Map<String, String> _alias = {'gold_coin': 'coin'};

  static String pictureId(String id) => _alias[id] ?? id;

  static AccessorySpec? spec(String id) => _specs[pictureId(id)];

  static const Map<String, AccessorySpec> _specs = {
    // Head
    'grad_cap': AccessorySpec(AccessorySlot.head, width: 0.70, aspect: 1.56, pivot: Offset(0.5, 0.80), nudge: Offset(0, 0.03)),
    'party_hat': AccessorySpec(AccessorySlot.head, width: 0.27, aspect: 0.65, pivot: Offset(0.5, 0.92), nudge: Offset(0.04, 0.04), rotate: 10),
    'wizard_hat': AccessorySpec(AccessorySlot.head, width: 0.60, aspect: 0.93, pivot: Offset(0.5, 0.84), nudge: Offset(0, 0.05)),
    'songkok': AccessorySpec(AccessorySlot.head, width: 0.66, aspect: 1.41, pivot: Offset(0.5, 0.74), nudge: Offset(0, 0.03)),
    'crown': AccessorySpec(AccessorySlot.head, width: 0.46, aspect: 1.43, pivot: Offset(0.5, 0.85), nudge: Offset(0, 0.02)),
    'phoenix_crown': AccessorySpec(AccessorySlot.head, width: 0.52, aspect: 1.09, pivot: Offset(0.5, 0.88), nudge: Offset(0, 0.02)),
    'halo': AccessorySpec(AccessorySlot.head, width: 0.54, aspect: 2.88, nudge: Offset(0, -0.07)),
    'aurora_halo': AccessorySpec(AccessorySlot.head, width: 0.54, aspect: 3.0, nudge: Offset(0, -0.07)),
    'headband': AccessorySpec(AccessorySlot.head, width: 0.86, aspect: 2.45, nudge: Offset(0.02, 0.06), clipTop: 0.42),
    // Behind the head, so the band shows above it and the cups peek out at the
    // sides; squashed a little to reach the wide, round heads.
    'headphones': AccessorySpec(AccessorySlot.head, width: 1.12, aspect: 1.6, pivot: Offset(0.5, 0), nudge: Offset(0.01, -0.07), behind: true),
    'flower': AccessorySpec(AccessorySlot.head, width: 0.22, aspect: 1.09, nudge: Offset(0.25, 0.07), rotate: 12),
    // Face
    'gold_shades': AccessorySpec(AccessorySlot.face, width: 2.05, aspect: 2.43, pivot: Offset(0.5, 0.52)),
    // Neck
    'bowtie': AccessorySpec(AccessorySlot.neck, width: 0.28, aspect: 1.64),
    'scarf': AccessorySpec(AccessorySlot.neck, width: 0.62, aspect: 0.84, pivot: Offset(0.5, 0.18), clipTop: 0.08),
    // Back
    'wings': AccessorySpec(AccessorySlot.back, width: 1.20, aspect: 2.17, nudge: Offset(0, -0.05)),
    'wings_grand': AccessorySpec(AccessorySlot.back, width: 1.35, aspect: 1.96, nudge: Offset(0, -0.07)),
    // Only the ermine collar and clasp, worn over the shoulders like a mantle:
    // the body fills the frame, so a cape behind it would not show.
    'royal_cape': AccessorySpec(AccessorySlot.neck, width: 1.0, aspect: 0.96, pivot: Offset(0.5, 0.02), nudge: Offset(0, -0.035), clipBottom: 0.62),
    // Held
    'pen': AccessorySpec(AccessorySlot.held, width: 0, aspect: 0.72),
    'coin': AccessorySpec(AccessorySlot.held, width: 0, aspect: 0.91),
    'money_bag': AccessorySpec(AccessorySlot.held, width: 0, aspect: 0.97),
    'calculator': AccessorySpec(AccessorySlot.held, width: 0, aspect: 0.82),
    'book': AccessorySpec(AccessorySlot.held, width: 0, aspect: 0.87),
    'star': AccessorySpec(AccessorySlot.held, width: 0, aspect: 1.06),
    'coffee': AccessorySpec(AccessorySlot.held, width: 0, aspect: 0.59),
    'laptop': AccessorySpec(AccessorySlot.held, width: 0, aspect: 1.0),
    'target': AccessorySpec(AccessorySlot.held, width: 0, aspect: 1.0),
    'trophy': AccessorySpec(AccessorySlot.held, width: 0, aspect: 0.98),
    'shield': AccessorySpec(AccessorySlot.held, width: 0, aspect: 0.86),
    'diamond': AccessorySpec(AccessorySlot.held, width: 0, aspect: 1.10),
    'magic_wand': AccessorySpec(AccessorySlot.held, width: 0, aspect: 0.59),
  };

  /// Top edge of a head accessory, as a fraction of the picture height, so
  /// the view can zoom out to keep tall hats in frame.
  static double? topOf(AccessorySpec s, MascotAnchors a) {
    if (s.slot != AccessorySlot.head || s.behind) return null;
    final h = s.width / s.aspect / 1.5;
    return a.headTop.dy + s.nudge.dy - s.pivot.dy * h + h * s.clipTop;
  }

  /// Places [id] on a picture of [imgW]×[imgH] logical pixels.
  /// Not for [AccessorySlot.held], which is laid out by the caller.
  static Widget placed(String id, AccessorySpec s, MascotAnchors a, double imgW, double imgH) {
    final double w;
    if (s.slot == AccessorySlot.face) {
      final eyes = Offset((a.rightEye.dx - a.leftEye.dx) * imgW, (a.rightEye.dy - a.leftEye.dy) * imgH);
      w = eyes.distance * s.width;
    } else {
      w = imgW * s.width;
    }
    final h = w / s.aspect;
    final base = switch (s.slot) {
      AccessorySlot.head => a.headTop,
      AccessorySlot.face => a.eyeMid,
      AccessorySlot.neck || AccessorySlot.back || AccessorySlot.held => a.neck,
    };
    final x = (base.dx + s.nudge.dx) * imgW - s.pivot.dx * w;
    final y = (base.dy + s.nudge.dy) * imgH - s.pivot.dy * h;
    final tilt = (s.slot == AccessorySlot.head || s.slot == AccessorySlot.face ? a.tilt : 0) + s.rotate;

    Widget img = Image.asset(
      asset(pictureId(id)),
      width: w,
      height: h,
      fit: BoxFit.fill,
      filterQuality: FilterQuality.medium,
      gaplessPlayback: true,
    );
    final shown = 1 - s.clipTop - s.clipBottom;
    if (shown < 1) {
      img = ClipRect(
        child: OverflowBox(
          alignment: Alignment(0, -1 + 2 * s.clipTop / (s.clipTop + s.clipBottom)),
          minHeight: h,
          maxHeight: h,
          child: img,
        ),
      );
    }
    return Positioned(
      left: x,
      top: y + h * s.clipTop,
      width: w,
      height: h * shown,
      child: Transform.rotate(angle: tilt * math.pi / 180, child: img),
    );
  }
}
