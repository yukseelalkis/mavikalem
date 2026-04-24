/// Sipariş durumu güncelleme isteğinin hedefini tanımlar.
///
/// - [auto]: Teslimat tipine göre uygun statüye (`delivered` / `being_prepared`)
///   geçiş yapılır. Ürün toplama sonrası "Sisteme Gonder" akışı bu modu kullanır.
/// - [delivered]: Teslimat tipinden bağımsız olarak siparişi doğrudan
///   "Teslim Edildi" statüsüne taşır. "Teslim Et" aksiyonu bu modu kullanır.
enum OrderStatusTarget { auto, delivered }
