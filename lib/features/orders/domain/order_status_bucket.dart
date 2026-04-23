/// IdeaSoft / API `status` alanini depo filtre gruplarina indirger.
enum OrderStatusBucket {
  all,
  yeni,
  hazirlaniyor,
  tamamlandi,
  diger;

  String get label => switch (this) {
        OrderStatusBucket.all => 'Tumu',
        OrderStatusBucket.yeni => 'Yeni',
        OrderStatusBucket.hazirlaniyor => 'Hazirlaniyor',
        OrderStatusBucket.tamamlandi => 'Tamamlandi',
        OrderStatusBucket.diger => 'Diger',
      };

  static OrderStatusBucket bucketForRawStatus(String raw) {
    final s = raw.trim().toLowerCase();
    if (s.isEmpty || s == '-') return OrderStatusBucket.diger;

    const tamamKeys = [
      'tamamlandi',
      'completed',
      'complete',
      'delivered',
      'teslim',
      'kargolandı',
      'kargolandi',
      'shipped',
      'closed',
      'kapali',
      'iptal',
      'cancel',
      'cancelled',
    ];
    for (final k in tamamKeys) {
      if (s.contains(k)) return OrderStatusBucket.tamamlandi;
    }

    const hazirKeys = [
      'hazirlan',
      'prepar',
      'pack',
      'toplama',
      'processing',
      'in progress',
      'isleniyor',
      'işleniyor',
    ];
    for (final k in hazirKeys) {
      if (s.contains(k)) return OrderStatusBucket.hazirlaniyor;
    }

    const yeniKeys = [
      'yeni',
      'new',
      'approved',
      'bekle',
      'wait',
      'pending',
      'onay',
      'odeme',
      'ödeme',
      'payment',
      'unpaid',
      'acik',
      'açık',
    ];
    for (final k in yeniKeys) {
      if (s.contains(k)) return OrderStatusBucket.yeni;
    }

    return OrderStatusBucket.diger;
  }

  bool matches(OrderStatusBucket itemBucket) {
    if (this == OrderStatusBucket.all) return true;
    return this == itemBucket;
  }
}
