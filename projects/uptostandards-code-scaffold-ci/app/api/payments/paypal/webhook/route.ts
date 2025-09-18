import { NextResponse } from "next/server";
export async function POST() {
  // TODO: verify signature and update DB
  return NextResponse.json({ received: true });
}
