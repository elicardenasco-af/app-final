import { getDb, transaction } from "@/lib/db";
import { handle, json, readJson, HttpError } from "@/lib/http";
import { requireUser } from "@/lib/auth";
import { PRODUCT_SELECT, calculateTotals, type ProductRow } from "@/lib/catalog";

type OrderRow = {
  id: number;
  subtotal: number;
  tax: number;
  shipping: number;
  total: number;
  status: string;
  created_at: string;
};

type OrderItemRow = {
  order_id: number;
  product_id: number;
  name: string;
  image_url: string;
  unit_price: number;
  quantity: number;
};

function loadOrders(userId: number, orderId?: number) {
  const db = getDb();
  const orders = (
    orderId
      ? db.prepare("SELECT * FROM orders WHERE user_id = ? AND id = ?").all(userId, orderId)
      : db.prepare("SELECT * FROM orders WHERE user_id = ? ORDER BY id DESC").all(userId)
  ) as OrderRow[];
  if (orders.length === 0) return [];

  const ids = orders.map((o) => o.id);
  const items = db
    .prepare(`SELECT * FROM order_items WHERE order_id IN (${ids.map(() => "?").join(",")})`)
    .all(...ids) as OrderItemRow[];

  return orders.map((o) => ({
    id: o.id,
    subtotal: o.subtotal,
    tax: o.tax,
    shipping: o.shipping,
    total: o.total,
    status: o.status,
    createdAt: o.created_at,
    items: items
      .filter((i) => i.order_id === o.id)
      .map((i) => ({
        productId: i.product_id,
        name: i.name,
        imageUrl: i.image_url,
        unitPrice: i.unit_price,
        quantity: i.quantity,
      })),
  }));
}

/** GET /api/orders — Pedidos del usuario autenticado ("Mis pedidos"). */
export async function GET(req: Request) {
  return handle(async () => {
    const user = await requireUser(req);
    return json({ orders: loadOrders(user.id) });
  });
}

/**
 * POST /api/orders — Simula la compra del carrito.
 * Body: { items: [{ productId, quantity }] }
 * El servidor recalcula precios, IVA, envío y total.
 */
export async function POST(req: Request) {
  return handle(async () => {
    const user = await requireUser(req);
    const body = await readJson<{ items?: unknown }>(req);

    if (!Array.isArray(body.items) || body.items.length === 0) {
      throw new HttpError(422, "El carrito está vacío");
    }

    // Agrupa cantidades por producto.
    const quantities = new Map<number, number>();
    for (const raw of body.items) {
      const item = raw as { productId?: unknown; quantity?: unknown };
      const productId = Number(item.productId);
      const quantity = Number(item.quantity);
      if (!Number.isInteger(productId) || !Number.isInteger(quantity) || quantity < 1) {
        throw new HttpError(422, "Ítems del carrito inválidos");
      }
      quantities.set(productId, (quantities.get(productId) ?? 0) + quantity);
    }

    const orderId = transaction((db) => {
      const lines: { product: ProductRow; quantity: number }[] = [];
      for (const [productId, quantity] of quantities) {
        const product = db.prepare(`${PRODUCT_SELECT} WHERE p.id = ?`).get(productId) as ProductRow | undefined;
        if (!product) throw new HttpError(404, `Producto ${productId} no encontrado`);
        if (product.stock < quantity) {
          throw new HttpError(409, `Stock insuficiente para "${product.name}" (disponible: ${product.stock})`);
        }
        lines.push({ product, quantity });
      }

      const subtotal = lines.reduce((sum, l) => sum + l.product.price * l.quantity, 0);
      const totals = calculateTotals(subtotal);

      const res = db
        .prepare("INSERT INTO orders (user_id, subtotal, tax, shipping, total) VALUES (?, ?, ?, ?, ?)")
        .run(user.id, totals.subtotal, totals.tax, totals.shipping, totals.total);
      const id = Number(res.lastInsertRowid);

      const insertItem = db.prepare(
        "INSERT INTO order_items (order_id, product_id, name, image_url, unit_price, quantity) VALUES (?, ?, ?, ?, ?, ?)",
      );
      const updateStock = db.prepare("UPDATE products SET stock = stock - ? WHERE id = ?");
      for (const { product, quantity } of lines) {
        insertItem.run(id, product.id, product.name, product.image_url, product.price, quantity);
        updateStock.run(quantity, product.id);
      }
      return id;
    });

    const [order] = loadOrders(user.id, orderId);
    return json({ message: "Compra realizada con éxito", order }, 201);
  });
}
