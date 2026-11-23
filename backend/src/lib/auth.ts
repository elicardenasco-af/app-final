import { SignJWT, jwtVerify } from "jose";
import bcrypt from "bcryptjs";
import crypto from "node:crypto";
import { getDb } from "./db";
import { HttpError } from "./http";

/** Manejo de sesión con JWT (firmado HS256). */

const DEV_SECRET = "dev-secret-solo-para-desarrollo-cambiar-en-produccion";
const secret = new TextEncoder().encode(process.env.JWT_SECRET || DEV_SECRET);
const EXPIRES_IN = process.env.JWT_EXPIRES_IN || "7d";

if (!process.env.JWT_SECRET) {
  console.warn("[auth] JWT_SECRET no definido: usando secreto de desarrollo.");
}

export type UserRow = {
  id: number;
  nombre: string;
  apellidos: string;
  username: string;
  email: string;
  password_hash: string;
  avatar_url: string | null;
  created_at: string;
  updated_at: string;
};

export type PublicUser = {
  id: number;
  nombre: string;
  apellidos: string;
  username: string;
  email: string;
  avatarUrl: string | null;
  createdAt: string;
};

export function toPublicUser(u: UserRow): PublicUser {
  return {
    id: u.id,
    nombre: u.nombre,
    apellidos: u.apellidos,
    username: u.username,
    email: u.email,
    avatarUrl: u.avatar_url,
    createdAt: u.created_at,
  };
}

export const hashPassword = (password: string) => bcrypt.hash(password, 10);
export const verifyPassword = (password: string, hash: string) => bcrypt.compare(password, hash);

export async function signToken(user: UserRow): Promise<string> {
  return new SignJWT({ username: user.username })
    .setProtectedHeader({ alg: "HS256" })
    .setSubject(String(user.id))
    .setJti(crypto.randomUUID())
    .setIssuedAt()
    .setExpirationTime(EXPIRES_IN)
    .sign(secret);
}

function bearerToken(req: Request): string {
  const header = req.headers.get("authorization") ?? "";
  const [scheme, token] = header.split(" ");
  if (scheme?.toLowerCase() !== "bearer" || !token) {
    throw new HttpError(401, "No autenticado: falta el token");
  }
  return token;
}

async function verify(token: string) {
  try {
    const { payload } = await jwtVerify(token, secret, { algorithms: ["HS256"] });
    return payload;
  } catch {
    throw new HttpError(401, "Sesión inválida o expirada");
  }
}

/** Valida el JWT de la cabecera Authorization y devuelve el usuario. */
export async function requireUser(req: Request): Promise<UserRow> {
  const payload = await verify(bearerToken(req));
  const db = getDb();

  if (payload.jti) {
    const revoked = db.prepare("SELECT 1 FROM revoked_tokens WHERE jti = ?").get(payload.jti);
    if (revoked) throw new HttpError(401, "La sesión fue cerrada");
  }

  const user = db.prepare("SELECT * FROM users WHERE id = ?").get(Number(payload.sub)) as UserRow | undefined;
  if (!user) throw new HttpError(401, "Usuario no encontrado");
  return user;
}

/** Invalida el token actual (cierre de sesión). */
export async function revokeToken(req: Request) {
  const payload = await verify(bearerToken(req));
  if (!payload.jti || !payload.exp) return;
  const db = getDb();
  db.prepare("INSERT OR IGNORE INTO revoked_tokens (jti, expires_at) VALUES (?, ?)").run(payload.jti, payload.exp);
  // Limpieza de tokens revocados ya expirados.
  db.prepare("DELETE FROM revoked_tokens WHERE expires_at < ?").run(Math.floor(Date.now() / 1000));
}

export const sha256 = (value: string) => crypto.createHash("sha256").update(value).digest("hex");
