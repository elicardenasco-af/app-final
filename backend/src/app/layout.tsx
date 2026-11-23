import type { Metadata } from "next";
import "./globals.css";

export const metadata: Metadata = {
  title: "Tienda App — API",
  description: "Backend REST de la App E-Commerce",
};

export default function RootLayout({ children }: { children: React.ReactNode }) {
  return (
    <html lang="es">
      <body>{children}</body>
    </html>
  );
}
