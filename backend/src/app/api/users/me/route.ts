import { getDb } from "@/lib/db";
import { handle, json, readJson } from "@/lib/http";
import { Validator, str } from "@/lib/validation";
import { requireUser, toPublicUser, type UserRow } from "@/lib/auth";

/** GET /api/users/me — Datos del usuario autenticado. */
export async function GET(req: Request) {
  return handle(async () => {
    const user = await requireUser(req);
    return json({ user: toPublicUser(user) });
  });
}

/** PUT /api/users/me — Actualiza nombre, apellidos y username. */
export async function PUT(req: Request) {
  return handle(async () => {
    const user = await requireUser(req);
    const body = await readJson(req);
    const nombre = str(body.nombre);
    const apellidos = str(body.apellidos);
    const username = str(body.username);

    const v = new Validator()
      .required("nombre", nombre, "El nombre es obligatorio")
      .required("apellidos", apellidos, "Los apellidos son obligatorios")
      .required("username", username, "El username es obligatorio")
      .username("username", username);
    v.throwIfErrors();

    const db = getDb();
    if (db.prepare("SELECT 1 FROM users WHERE username = ? AND id <> ?").get(username, user.id)) {
      v.add("username", "El username ya está en uso");
    }
    v.throwIfErrors(409);

    db.prepare(
      "UPDATE users SET nombre = ?, apellidos = ?, username = ?, updated_at = datetime('now') WHERE id = ?",
    ).run(nombre, apellidos, username, user.id);

    const updated = db.prepare("SELECT * FROM users WHERE id = ?").get(user.id) as UserRow;
    return json({ message: "Datos actualizados", user: toPublicUser(updated) });
  });
}
