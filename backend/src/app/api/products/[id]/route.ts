import { getDb } from "@/lib/db";
import { handle, json, HttpError } from "@/lib/http";
import { PRODUCT_SELECT, toProduct, type ProductRow } from "@/lib/catalog";

/** GET /api/products/:id — Detalle de un producto. */
export async function GET(_req: Request, ctx: { params: Promise<{ id: string }> }) {
  return handle(async () => {
    const { id } = await ctx.params;
    const row = getDb().prepare(`${PRODUCT_SELECT} WHERE p.id = ?`).get(Number(id)) as ProductRow | undefined;
    if (!row) throw new HttpError(404, "Producto no encontrado");
    return json({ product: toProduct(row) });
  });
}
