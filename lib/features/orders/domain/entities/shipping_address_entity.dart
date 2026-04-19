/// Teslimat adresi (liste/detay JSON icindeki shippingAddress).
class ShippingAddressEntity {
  const ShippingAddressEntity({
    required this.fullName,
    required this.phone,
    required this.address,
    required this.location,
    required this.subLocation,
  });

  final String fullName;
  final String phone;

  /// Sokak / adres satiri
  final String address;

  /// Genelde il veya ust konum adi
  final String location;

  /// Genelde ilce veya alt konum adi
  final String subLocation;

  bool get isEmpty =>
      fullName.trim().isEmpty &&
      phone.trim().isEmpty &&
      address.trim().isEmpty &&
      location.trim().isEmpty &&
      subLocation.trim().isEmpty;
}
