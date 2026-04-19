# IdeaSoft API Contract Notes

Bu dokuman, depo uygulamasinin MVP akisinda bekledigi minimum JSON alanlarini listeler.
Mevcut implementation birden fazla response shape destekleyecek sekilde yazilmistir
(`data/items/results` gibi kapsul alanlar parse edilmektedir).

## 1) OAuth Token Response

`POST https://mavikalem.myideasoft.com/oauth/v2/token`

Beklenen minimum alanlar:

```json
{
  "access_token": "string",
  "token_type": "Bearer",
  "expires_in": 3600,
  "refresh_token": "optional-string"
}
```

Kullanim:
- `access_token`: zorunlu, secure storage icine yazilir.
- `refresh_token`: varsa saklanir (ileride refresh flow icin).

## 2) Incoming Orders List Response

`GET /api/orders?status=incoming&limit=50`

Desteklenen ust seviye shape:
- Direkt liste: `[{...}, {...}]`
- Kapsul map: `{"data":[...]}` veya `{"items":[...]}`

Her siparis kaydi minimum:

```json
{
  "id": 101,
  "orderNumber": "MK-2026-0001",
  "customerName": "John Doe",
  "status": "incoming",
  "createdAt": "2026-04-19T10:00:00Z",
  "items": [
    {
      "id": 1,
      "productId": 234,
      "name": "Urun Adi",
      "sku": "STK-001",
      "quantity": 2,
      "imageUrl": "https://..."
    }
  ]
}
```

Alternatif alan adlari da desteklenir:
- `order_number`, `customer_name`, `created_at`, `statusText`, `product_id`, `productName`, `stockCode`, `image`.

## 3) Order Detail Response

`GET /api/orders/{orderId}`

Beklenen shape bir map nesnesi olmalidir:

```json
{
  "id": 101,
  "orderNumber": "MK-2026-0001",
  "customerName": "John Doe",
  "status": "incoming",
  "items": [ ... ]
}
```

## 4) Product Lookup Response (Barcode / StockCode)

`GET /api/products?barcode=...` veya `GET /api/products?sku=...`

Desteklenen ust seviye shape:
- Direkt liste veya `data/items/results/products` kapsulu

Urun minimum:

```json
{
  "id": 123,
  "name": "Urun Adi",
  "sku": "STK-001",
  "barcode": "869...",
  "stockAmount": 12,
  "images": [
    {
      "directoryName": "abc",
      "filename": "def",
      "extension": "jpg"
    }
  ]
}
```

## 5) Acik Kararlar

- `order status update` endpointi netlesirse `OrderPreparePage` icine API update aksiyonu eklenecek.
- `refresh token` endpoint detaylari netlesirse `AuthRepository` icine refresh akisi eklenecek.
- `redirect_uri` production degeri IdeaSoft panelde kesinlestirilmeli
  (`mavikalemapp://oauth/callback` kullanimi buna baglidir).
