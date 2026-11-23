import { getDb } from "@/lib/db";
import { handle, json, readJson, HttpError } from "@/lib/http";
import { Validator, str, MIN_PASSWORD } from "@/lib/validation";
import { hashPassword, toPublicUser, type UserRow } from "@/lib/auth";

/** POST /api/auth/register — Registro de usuario. */
export async function POST(req: Request) {
  return handle(async () => {
    const body = await readJson(req);
    const nombre = str(body.nombre);
    const apellidos = str(body.apellidos);
    const username = str(body.username);
    const email = str(body.email).toLowerCase();
    const password = typeof body.password === "string" ? body.password : "";
    const confirmPassword = typeof body.confirmPassword === "string" ? body.confirmPassword : "";

    const v = new Validator()
      .required("nombre", nombre, "El nombre es obligatorio")
      .required("apellidos", apellidos, "Los apellidos son obligatorios")
      .required("username", username, "El username es obligatorio")
      .username("username", username)
      .required("email", email, "El correo es obligatorio")
      .email("email", email)
      .required("password", password, "La contraseña es obligatoria")
      .minLength("password", password, MIN_PASSWORD, "La contraseña")
      .required("confirmPassword", confirmPassword, "Debes verificar la contraseña")
      .matches("confirmPassword", password, confirmPassword, "Las contraseñas no coinciden");
    v.throwIfErrors();

    const db = getDb();
    if (db.prepare("SELECT 1 FROM users WHERE username = ?").get(username)) {
      v.add("username", "El username ya está en uso");
    }
    if (db.prepare("SELECT 1 FROM users WHERE email = ?").get(email)) {
      v.add("email", "El correo ya está registrado");
    }
    v.throwIfErrors(409);

    const passwordHash = await hashPassword(password);
    const res = db
      .prepare("INSERT INTO users (nombre, apellidos, username, email, password_hash) VALUES (?, ?, ?, ?, ?)")
      .run(nombre, apellidos, username, email, passwordHash);

    const user = db.prepare("SELECT * FROM users WHERE id = ?").get(Number(res.lastInsertRowid)) as UserRow;
    if (!user) throw new HttpError(500, "No se pudo crear el usuario");
    return json({ message: "Usuario registrado correctamente", user: toPublicUser(user) }, 201);
  });
}
