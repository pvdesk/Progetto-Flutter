import 'package:flutter/material.dart';

/// Centra il contenuto e ne limita la larghezza massima sugli schermi larghi
/// (tablet), lasciandolo a piena larghezza sui telefoni. Evita il layout
/// "mobile stirato" su tablet.
///
/// Uso: avvolgere il body di uno Scaffold, es.
///   body: ResponsiveCenter(child: ...)
class ResponsiveCenter extends StatelessWidget {
  final Widget child;
  final double maxWidth;

  const ResponsiveCenter({
    super.key,
    required this.child,
    this.maxWidth = 820,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxWidth),
        child: child,
      ),
    );
  }
}
