import { NextResponse } from "next/server";
export async function POST(req: Request) {
  const { orderID } = await req.json();
  // TODO: implement capture call and update DB
  return NextResponse.json({ captured: true, orderID });
}
