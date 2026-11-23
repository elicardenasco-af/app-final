import type { DatabaseSync } from "node:sqlite";

/**
 * Datos iniciales del catálogo (categorías, productos y banners).
 * Solo se insertan si las tablas están vacías.
 * Precios en pesos colombianos (COP), sin IVA.
 */

/**
 * Las imágenes están en backend/public/images y las sirve el propio backend.
 * Se guardan como rutas relativas; la app las completa con la URL del servidor.
 * Fuentes y licencias: backend/public/images/CREDITOS.md
 */
const productImg = (seed: string) => `/images/products/${seed}.jpg`;
const bannerImg = (seed: string) => `/images/banners/${seed}.jpg`;

const categories = ["Ropa", "Electrónica", "Hogar", "Deportes", "Accesorios"];

const products: Array<{
  name: string;
  description: string;
  price: number;
  stock: number;
  category: string;
  seed: string;
}> = [
  { name: "Camiseta básica algodón", category: "Ropa", price: 39900, stock: 50, seed: "camiseta",
    description: "Camiseta de algodón 100% peinado, corte regular y cuello redondo. Suave al tacto, transpirable e ideal para el uso diario. Disponible en tallas S a XL." },
  { name: "Jean slim fit", category: "Ropa", price: 119900, stock: 30, seed: "jean",
    description: "Jean de corte slim con tela denim elástica que brinda comodidad y libertad de movimiento. Cinco bolsillos y cierre con cremallera y botón metálico." },
  { name: "Chaqueta impermeable", category: "Ropa", price: 189900, stock: 20, seed: "chaqueta",
    description: "Chaqueta ligera impermeable con capucha ajustable, costuras selladas y bolsillos con cremallera. Perfecta para días lluviosos y actividades al aire libre." },
  { name: "Buzo con capota", category: "Ropa", price: 99900, stock: 35, seed: "buzo",
    description: "Buzo en tela perchada con capota y bolsillo canguro. Interior afelpado para mayor abrigo, puños y pretina en rib." },
  { name: "Audífonos inalámbricos", category: "Electrónica", price: 159900, stock: 40, seed: "audifonos",
    description: "Audífonos Bluetooth 5.3 con cancelación pasiva de ruido, hasta 30 horas de batería, micrófono integrado y estuche de carga USB-C." },
  { name: "Smartwatch deportivo", category: "Electrónica", price: 249900, stock: 25, seed: "smartwatch",
    description: "Reloj inteligente con monitor de frecuencia cardíaca, oxígeno en sangre, conteo de pasos, notificaciones y resistencia al agua IP68." },
  { name: "Parlante Bluetooth portátil", category: "Electrónica", price: 129900, stock: 30, seed: "parlante",
    description: "Parlante portátil con sonido 360°, graves potentes, 12 horas de autonomía y resistencia a salpicaduras. Ideal para llevar a cualquier lugar." },
  { name: "Teclado mecánico RGB", category: "Electrónica", price: 209900, stock: 15, seed: "teclado",
    description: "Teclado mecánico con switches táctiles, iluminación RGB personalizable, teclas anti-ghosting y cable USB-C desmontable." },
  { name: "Lámpara de escritorio LED", category: "Hogar", price: 79900, stock: 45, seed: "lampara",
    description: "Lámpara LED con brazo flexible, tres temperaturas de color y cinco niveles de brillo. Bajo consumo y puerto USB para cargar el celular." },
  { name: "Juego de sábanas", category: "Hogar", price: 139900, stock: 25, seed: "sabanas",
    description: "Juego de sábanas doble en microfibra de alta densidad: sábana ajustable, sábana plana y dos fundas. Suaves y fáciles de lavar." },
  { name: "Cafetera de goteo", category: "Hogar", price: 169900, stock: 18, seed: "cafetera",
    description: "Cafetera de goteo con capacidad para 12 tazas, jarra de vidrio, placa para mantener caliente y filtro permanente lavable." },
  { name: "Balón de fútbol", category: "Deportes", price: 89900, stock: 40, seed: "balon",
    description: "Balón de fútbol tamaño 5 cosido a máquina, cámara de butilo para mejor retención de aire. Apto para césped natural y sintético." },
  { name: "Mat de yoga", category: "Deportes", price: 69900, stock: 35, seed: "yoga",
    description: "Colchoneta de yoga antideslizante de 6 mm de grosor, liviana y con correa de transporte. Ideal para yoga, pilates y estiramientos." },
  { name: "Mancuernas ajustables", category: "Deportes", price: 229900, stock: 12, seed: "mancuernas",
    description: "Par de mancuernas ajustables de 2 a 10 kg con discos intercambiables y agarre antideslizante. Perfectas para entrenar en casa." },
  { name: "Gafas de sol polarizadas", category: "Accesorios", price: 109900, stock: 30, seed: "gafas",
    description: "Gafas de sol con lentes polarizados y protección UV400, marco liviano y resistente. Incluyen estuche rígido y paño de limpieza." },
  { name: "Morral urbano", category: "Accesorios", price: 149900, stock: 22, seed: "morral",
    description: "Morral resistente al agua con compartimento acolchado para portátil de hasta 15.6\", múltiples bolsillos y puerto de carga USB." },
  { name: "Billetera de cuero", category: "Accesorios", price: 74900, stock: 40, seed: "billetera",
    description: "Billetera en cuero genuino con protección RFID, ocho ranuras para tarjetas, compartimento para billetes y monedero." },
];

const banners = [
  { title: "Temporada de descuentos", subtitle: "Hasta 40% en productos seleccionados", seed: "ofertas" },
  { title: "Nueva colección", subtitle: "Descubre lo último en ropa y accesorios", seed: "coleccion" },
  { title: "Envío gratis", subtitle: "En compras desde $200.000", seed: "envio" },
];

/** Actualiza las imágenes de una base de datos creada con una versión anterior. */
function syncCatalogImages(db: DatabaseSync) {
  const updateProduct = db.prepare("UPDATE products SET image_url = ? WHERE name = ? AND image_url <> ?");
  const updateOrderItem = db.prepare("UPDATE order_items SET image_url = ? WHERE name = ? AND image_url <> ?");
  for (const p of products) {
    const url = productImg(p.seed);
    updateProduct.run(url, p.name, url);
    updateOrderItem.run(url, p.name, url);
  }
  const updateBanner = db.prepare("UPDATE banners SET image_url = ? WHERE title = ? AND image_url <> ?");
  for (const b of banners) {
    const url = bannerImg(b.seed);
    updateBanner.run(url, b.title, url);
  }
}

export function seedDatabase(db: DatabaseSync) {
  const count = db.prepare("SELECT COUNT(*) AS c FROM categories").get() as { c: number };
  if (count.c > 0) {
    syncCatalogImages(db);
    return;
  }

  db.exec("BEGIN");
  try {
    const insertCategory = db.prepare("INSERT INTO categories (name) VALUES (?)");
    const categoryIds = new Map<string, number>();
    for (const name of categories) {
      const res = insertCategory.run(name);
      categoryIds.set(name, Number(res.lastInsertRowid));
    }

    const insertProduct = db.prepare(
      "INSERT INTO products (name, description, price, image_url, stock, category_id) VALUES (?, ?, ?, ?, ?, ?)",
    );
    for (const p of products) {
      insertProduct.run(p.name, p.description, p.price, productImg(p.seed), p.stock, categoryIds.get(p.category)!);
    }

    const insertBanner = db.prepare("INSERT INTO banners (title, subtitle, image_url) VALUES (?, ?, ?)");
    for (const b of banners) {
      insertBanner.run(b.title, b.subtitle, bannerImg(b.seed));
    }
    db.exec("COMMIT");
  } catch (err) {
    db.exec("ROLLBACK");
    throw err;
  }
}
