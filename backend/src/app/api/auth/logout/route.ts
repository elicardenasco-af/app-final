import { handle, json } from "@/lib/http";
import { revokeToken } from "@/lib/auth";

/** POST /api/auth/logout — Cierra la sesión invalidando el JWT actual. */
export async function POST(req: Request) {
  return handle(async () => {
    await revokeToken(req);
    return json({ message: "Sesión cerrada" });
  });
}
