import 'package:flutter/material.dart';

/// Widget reutilizável que aplica efeito "hover" (zoom + sombra) em imagens.
/// Funciona em desktop/web (mouse). Em mobile, permanece estático.
class HoverImage extends StatefulWidget {
  final String imageUrl;
  final double width;
  final double height;
  final BorderRadius? borderRadius;
  final BoxFit fit;
  final VoidCallback? onTap;
  final Widget? errorWidget;

  const HoverImage({
    super.key,
    required this.imageUrl,
    required this.width,
    required this.height,
    this.borderRadius,
    this.fit = BoxFit.cover,
    this.onTap,
    this.errorWidget,
  });

  @override
  State<HoverImage> createState() => _HoverImageState();
}

class _HoverImageState extends State<HoverImage> {
  bool _hovering = false;

  void _onEnter(PointerEvent _) => setState(() => _hovering = true);
  void _onExit(PointerEvent _) => setState(() => _hovering = false);

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: _onEnter,
      onExit: _onExit,
      cursor: widget.onTap != null
          ? SystemMouseCursors.click
          : SystemMouseCursors.basic,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeOut,
        transform: _hovering
            ? (Matrix4.identity()..scale(1.06))
            : Matrix4.identity(),
        decoration: BoxDecoration(
          borderRadius: widget.borderRadius ?? BorderRadius.zero,
          boxShadow: _hovering
              ? [
                  BoxShadow(
                    color: Colors.deepPurple.withOpacity(0.4),
                    blurRadius: 16,
                    offset: const Offset(0, 8),
                  )
                ]
              : [],
        ),
        child: ClipRRect(
          borderRadius: widget.borderRadius ?? BorderRadius.zero,
          child: GestureDetector(
            onTap: widget.onTap,
            child: Image.network(
              widget.imageUrl,
              width: widget.width,
              height: widget.height,
              fit: widget.fit,
              errorBuilder: (_, __, ___) => widget.errorWidget ??
                  Container(
                    color: Colors.grey[900],
                    child: const Icon(Icons.broken_image,
                        color: Colors.white54),
                  ),
            ),
          ),
        ),
      ),
    );
  }
}
