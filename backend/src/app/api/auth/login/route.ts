import { getDb } from "@/lib/db";
import { handle, json, readJson, HttpError } from "@/lib/http";
import { Validator, str, MIN_LOGIN_PASSWORD } from "@/lib/validation";
import { signToken, toPublicUser, verifyPassword, type UserRow } from "@/lib/auth";

/** POST /api/auth/login — Inicio de sesión con username o correo. Devuelve el JWT. */
export async function POST(req: Request) {
  return handle(async () => {
    const body = await readJson(req);
    const identifier = str(body.identifier);
    const password = typeof body.password === "string" ? body.password : "";

    const v = new Validator()
      .required("identifier", identifier, "El username o correo es obligatorio")
      .required("password", password, "La contraseña es obligatoria")
      .minLength("password", password, MIN_LOGIN_PASSWORD, "La contraseña");
    if (identifier.includes("@")) v.email("identifier", identifier);
    v.throwIfErrors();

    const user = getDb()
      .prepare("SELECT * FROM users WHERE username = ? OR email = ?")
      .get(identifier, identifier.toLowerCase()) as UserRow | undefined;

    if (!user || !(await verifyPassword(password, user.password_hash))) {
      throw new HttpError(401, "Credenciales incorrectas");
    }

    const token = await signToken(user);
    return json({ token, user: toPublicUser(user) });
  });
}
