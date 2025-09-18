import { NextResponse } from "next/server";

async function paypalToken() {
  const id = process.env.PAYPAL_CLIENT_ID!;
  const sec = process.env.PAYPAL_CLIENT_SECRET!;
  const res = await fetch("https://api-m.sandbox.paypal.com/v1/oauth2/token", {
    method: "POST",
    headers: { Authorization: `Basic ${Buffer.from(`${id}:${sec}`).toString("base64")}`, "Content-Type": "application/x-www-form-urlencoded" },
    body: "grant_type=client_credentials"
  });
  const j = await res.json();
  return j.access_token as string;
}

export async function POST(req: Request) {
  const { listingId } = await req.json();
  const token = await paypalToken();
  // TODO: authoritative amount from DB
  const order = await fetch("https://api-m.sandbox.paypal.com/v2/checkout/orders", {
    method: "POST",
    headers: { Authorization: `Bearer ${token}`, "Content-Type": "application/json" },
    body: JSON.stringify({ intent: "CAPTURE", purchase_units: [{ amount: { currency_code: "USD", value: "50.00" }, reference_id: String(listingId) }] })
  }).then(r=>r.json());
  const approve = order.links?.find((l:any)=>l.rel==="approve")?.href;
  return NextResponse.json({ approveUrl: approve, orderID: order.id });
}
