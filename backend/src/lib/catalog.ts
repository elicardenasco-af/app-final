/** Utilidades del catálogo y del cálculo del pedido. */

export type ProductRow = {
  id: number;
  name: string;
  description: string;
  price: number;
  image_url: string;
  stock: number;
  category_id: number;
  category_name: string;
};

export function toProduct(p: ProductRow) {
  return {
    id: p.id,
    name: p.name,
    description: p.description,
    price: p.price,
    imageUrl: p.image_url,
    stock: p.stock,
    category: { id: p.category_id, name: p.category_name },
  };
}

export const PRODUCT_SELECT = `
  SELECT p.*, c.name AS category_name
  FROM products p
  JOIN categories c ON c.id = p.category_id
`;

/** Reglas del resumen del pedido (las mismas que usa la app). */
export const PRICING = {
  taxRate: 0.19, // IVA Colombia 19%
  shippingCost: 12000, // costo de envío estándar (COP)
  freeShippingFrom: 200000, // envío gratis desde este subtotal
};

const round = (n: number) => Math.round(n * 100) / 100;

export function calculateTotals(subtotal: number) {
  const tax = round(subtotal * PRICING.taxRate);
  const shipping = subtotal === 0 || subtotal >= PRICING.freeShippingFrom ? 0 : PRICING.shippingCost;
  return { subtotal: round(subtotal), tax, shipping, total: round(subtotal + tax + shipping) };
}
