import { NextResponse } from "next/server";

export type FieldErrors = Record<string, string>;

/** Error HTTP controlado que se convierte en una respuesta JSON. */
export class HttpError extends Error {
  constructor(
    public status: number,
    message: string,
    public errors?: FieldErrors,
  ) {
    super(message);
  }
}

export function json<T>(data: T, status = 200) {
  return NextResponse.json(data, { status });
}

/** Envuelve un handler para responder errores con formato uniforme { message, errors }. */
export async function handle(fn: () => Promise<Response>): Promise<Response> {
  try {
    return await fn();
  } catch (err) {
    if (err instanceof HttpError) {
      return json({ message: err.message, errors: err.errors }, err.status);
    }
    console.error(err);
    return json({ message: "Error interno del servidor" }, 500);
  }
}

/** Lee el cuerpo JSON de la petición o lanza 400. */
export async function readJson<T = Record<string, unknown>>(req: Request): Promise<T> {
  try {
    const body = await req.json();
    if (body === null || typeof body !== "object") throw new Error();
    return body as T;
  } catch {
    throw new HttpError(400, "El cuerpo de la petición debe ser JSON válido");
  }
}
