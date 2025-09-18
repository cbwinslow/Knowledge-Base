import { NextResponse } from "next/server";
export function middleware(req: Request) {
  // TODO: check session role === 'admin'
  return NextResponse.next();
}
export const config = { matcher: ["/admin/:path*"] };
