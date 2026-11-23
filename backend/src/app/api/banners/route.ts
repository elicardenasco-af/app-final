import { getDb } from "@/lib/db";
import { handle, json } from "@/lib/http";

/** GET /api/banners — Imágenes promocionales del carrusel del Home. */
export async function GET() {
  return handle(async () => {
    const banners = getDb()
      .prepare("SELECT id, title, subtitle, image_url AS imageUrl FROM banners ORDER BY id")
      .all();
    return json({ banners });
  });
}
