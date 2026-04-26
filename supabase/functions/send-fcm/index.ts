import { serve } from "https://deno.land/std@0.168.0/http/server.ts"
import { initializeApp, cert, getApp, getApps } from "npm:firebase-admin/app"
import { getMessaging } from "npm:firebase-admin/messaging"

serve(async (req) => {
  try {
    const body = await req.json();
    console.log("Ideasoft'tan Gelen Sipariş:", JSON.stringify(body));

    // Ideasoft verilerini ayıklıyoruz
    const orderId = body.id || "000";
    const customerName = `${body.customerFirstname || ''} ${body.customerSurname || ''}`.trim() || "Müşteri Bilgisi Yok";
    const totalAmount = body.amount || "0";

    // Firebase'i hazırla
    const serviceAccount = JSON.parse(Deno.env.get('FIREBASE_SERVICE_ACCOUNT') || '{}');
    const app = getApps().length === 0 ? initializeApp({ credential: cert(serviceAccount) }) : getApp();

    // Senin Mi Note 10 Lite token'ın
    const deviceToken = "eitrBumKQbuYiUaP3C2CxM:APA91bFaEkd2ZQeGllTEhZI1OL0oXuZbh6wf0gJxoJf07z11H6HgjztN2jceSQaKzota9AmFsDAifUEl09MpaVbY_x6lzDEr7zMmuggubN7vcflMYfyqtHg";

    const message = {
      token: deviceToken,
      notification: {
        title: "🛒 MAVİKALEM: YENİ SİPARİŞ!",
        body: `${customerName} - ${totalAmount} TL (Sipariş No: ${orderId})`,
      },
      android: { 
        priority: "high" as const,
        notification: {
          sound: "default",
          clickAction: "FLUTTER_NOTIFICATION_CLICK"
        }
      }
    };

    const response = await getMessaging(app).send(message);
    console.log("Bildirim Gönderildi:", response);

    return new Response(JSON.stringify({ success: true }), { status: 200 });
  } catch (error) {
    console.error("Hata:", error.message);
    return new Response(JSON.stringify({ error: error.message }), { status: 500 });
  }
})