import 'package:flutter/material.dart';

/// Mostra un elenco di card in **colonna singola su telefono** e su **più colonne**
/// (griglia fluida) su tablet, usando tutta la larghezza disponibile.
///
/// I parametri [itemCount], [itemBuilder] e [padding] combaciano con
/// `ListView.builder`, così da poter sostituire quest'ultimo con una modifica
/// minima:  `ListView.builder(` → `ResponsiveCardGrid(`.
class ResponsiveCardGrid extends StatelessWidget {
  final int itemCount;
  final Widget Function(BuildContext, int) itemBuilder;
  final EdgeInsetsGeometry? padding;

  /// Larghezza minima di una colonna: sotto questa soglia si passa a colonna singola.
  final double minColWidth;
  final double spacing;
  final double runSpacing;

  const ResponsiveCardGrid({
    super.key,
    required this.itemCount,
    required this.itemBuilder,
    this.padding,
    this.minColWidth = 460,
    this.spacing = 12,
    this.runSpacing = 4,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final w = constraints.maxWidth;
        final cols = (w / minColWidth).floor().clamp(1, 4);

        // Telefono / schermi stretti: comportamento identico a ListView.builder.
        if (cols <= 1) {
          return ListView.builder(
            padding: padding,
            itemCount: itemCount,
            itemBuilder: itemBuilder,
          );
        }

        // Tablet: card a larghezza fissa disposte su più colonne.
        final pad = (padding ?? EdgeInsets.zero).resolve(TextDirection.ltr);
        final avail = w - pad.left - pad.right - (cols - 1) * spacing;
        final cardW = avail / cols;

        return SingleChildScrollView(
          padding: padding,
          physics: const AlwaysScrollableScrollPhysics(),
          child: Wrap(
            spacing: spacing,
            runSpacing: runSpacing,
            children: List.generate(
              itemCount,
              (i) => SizedBox(width: cardW, child: itemBuilder(context, i)),
            ),
          ),
        );
      },
    );
  }
}
