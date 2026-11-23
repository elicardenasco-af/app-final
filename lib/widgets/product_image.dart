import 'package:flutter/material.dart';

import '../config/api_config.dart';

/// Imagen de red con indicador de carga y respaldo si falla.
class ProductImage extends StatelessWidget {
  final String url;
  final BoxFit fit;
  final BorderRadius? borderRadius;

  const ProductImage({super.key, required this.url, this.fit = BoxFit.cover, this.borderRadius});

  @override
  Widget build(BuildContext context) {
    final image = Image.network(
      ApiConfig.resolveUrl(url),
      fit: fit,
      width: double.infinity,
      height: double.infinity,
      loadingBuilder: (context, child, progress) => progress == null
          ? child
          : Container(
              color: Colors.grey.shade200,
              alignment: Alignment.center,
              child: const SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            ),
      errorBuilder: (context, error, stack) => Container(
        color: Colors.grey.shade200,
        alignment: Alignment.center,
        child: Icon(Icons.image_not_supported_outlined, color: Colors.grey.shade500),
      ),
    );
    return borderRadius == null ? image : ClipRRect(borderRadius: borderRadius!, child: image);
  }
}
