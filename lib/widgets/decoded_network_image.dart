import 'package:flutter/material.dart';

/// [Image.network] that decodes at the on-screen pixel size instead of the
/// source resolution. A 72-logical-pixel thumbnail otherwise allocates a
/// full 2000px bitmap.
class DecodedNetworkImage extends StatelessWidget {
  const DecodedNetworkImage(
    this.url, {
    super.key,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
    this.errorBuilder,
  });

  final String url;
  final double? width;
  final double? height;
  final BoxFit fit;
  final ImageErrorWidgetBuilder? errorBuilder;

  @override
  Widget build(BuildContext context) {
    final dpr = MediaQuery.devicePixelRatioOf(context);
    final logical = _logicalPx(context);
    final cache = (logical * dpr).round().clamp(48, 1600);
    return Image.network(
      url,
      width: width,
      height: height,
      fit: fit,
      cacheWidth: cache,
      filterQuality: FilterQuality.medium,
      errorBuilder: errorBuilder,
    );
  }

  double _logicalPx(BuildContext context) {
    final w = width;
    if (w != null && w.isFinite && w > 0) return w;
    final h = height;
    if (h != null && h.isFinite && h > 0) return h;
    return MediaQuery.sizeOf(context).width;
  }
}
