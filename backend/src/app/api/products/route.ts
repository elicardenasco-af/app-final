import { getDb } from "@/lib/db";
import { handle, json } from "@/lib/http";
import { PRODUCT_SELECT, toProduct, type ProductRow } from "@/lib/catalog";

/**
 * GET /api/products — Listado de productos.
 * Filtros opcionales: ?search=texto&categoryId=1
 */
export async function GET(req: Request) {
  return handle(async () => {
    const params = new URL(req.url).searchParams;
    const search = params.get("search")?.trim() ?? "";
    const categoryId = Number(params.get("categoryId") ?? 0);

    const where: string[] = [];
    const args: (string | number)[] = [];
    if (search) {
      where.push("p.name LIKE ?");
      args.push(`%${search}%`);
    }
    if (categoryId > 0) {
      where.push("p.category_id = ?");
      args.push(categoryId);
    }

    const sql = `${PRODUCT_SELECT} ${where.length ? "WHERE " + where.join(" AND ") : ""} ORDER BY p.id`;
    const rows = getDb().prepare(sql).all(...args) as ProductRow[];
    return json({ products: rows.map(toProduct) });
  });
}
