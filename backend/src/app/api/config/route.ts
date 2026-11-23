import { handle, json } from "@/lib/http";
import { PRICING } from "@/lib/catalog";

/** GET /api/config — Reglas de precios (IVA y envío) usadas en el carrito. */
export async function GET() {
  return handle(async () => json({ pricing: PRICING }));
}
