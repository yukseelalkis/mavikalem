import 'package:flutter/material.dart';
import 'package:mavikalem_app/core/delivery/delivery_type_kind.dart';

/// Teslimat tipi chip'i. [rawValue] ve [kind] ikisi de null ise bilinmeyen rozet gösterilir.
final class DeliveryTypeBadge extends StatelessWidget {
  const DeliveryTypeBadge({
    super.key,
    this.rawValue,
    this.kind,
    this.alignment = Alignment.centerLeft,
    this.unknownLabel,
  });

  final String? rawValue;
  final DeliveryTypeKind? kind;
  final AlignmentGeometry alignment;

  /// `DeliveryTypeKind.unknown` durumunda badge üzerinde gösterilecek metni
  /// özelleştirmek için; örneğin sipariş UX'inde "Teslimat Bilgisi Yok".
  final String? unknownLabel;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final resolvedKind = kind ?? resolveDeliveryType(rawValue);
    final style = _styleFor(theme, resolvedKind);

    return Align(
      alignment: alignment,
      child: Chip(
        avatar: Icon(style.icon, size: 18, color: style.foregroundColor),
        label: Text(
          style.label,
          style: theme.textTheme.labelLarge?.copyWith(
            fontWeight: FontWeight.w700,
            color: style.foregroundColor,
          ),
        ),
        side: BorderSide(color: style.foregroundColor.withValues(alpha: 0.25)),
        backgroundColor: style.backgroundColor,
        visualDensity: VisualDensity.compact,
        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
      ),
    );
  }

  _DeliveryBadgeStyle _styleFor(
    ThemeData theme,
    DeliveryTypeKind resolvedKind,
  ) {
    switch (resolvedKind) {
      case DeliveryTypeKind.storePickup:
        return _DeliveryBadgeStyle(
          label: 'Mağazadan Teslim',
          icon: Icons.storefront_rounded,
          foregroundColor: Colors.green.shade800,
          backgroundColor: Colors.green.shade50,
        );
      case DeliveryTypeKind.cargo:
        return _DeliveryBadgeStyle(
          label: 'Kargo ile Teslim',
          icon: Icons.local_shipping_rounded,
          foregroundColor: Colors.blue.shade800,
          backgroundColor: Colors.blue.shade50,
        );
      case DeliveryTypeKind.unknown:
        final foreground = theme.colorScheme.onSurfaceVariant;
        return _DeliveryBadgeStyle(
          label: unknownLabel ?? 'Teslimat Bilgisi Bulunamadı',
          icon: Icons.info_outline_rounded,
          foregroundColor: foreground,
          backgroundColor: theme.colorScheme.surfaceContainerHighest,
        );
    }
  }
}

final class _DeliveryBadgeStyle {
  const _DeliveryBadgeStyle({
    required this.label,
    required this.icon,
    required this.foregroundColor,
    required this.backgroundColor,
  });

  final String label;
  final IconData icon;
  final Color foregroundColor;
  final Color backgroundColor;
}
