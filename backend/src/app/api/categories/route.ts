import { getDb } from "@/lib/db";
import { handle, json } from "@/lib/http";

/** GET /api/categories — Categorías para los chips de filtro. */
export async function GET() {
  return handle(async () => {
    const categories = getDb().prepare("SELECT id, name FROM categories ORDER BY id").all();
    return json({ categories });
  });
}
