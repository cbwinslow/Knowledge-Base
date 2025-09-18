import { NextResponse } from "next/server";
import Stripe from "stripe";

export async function POST(req: Request) {
  const body = await req.json();
  const { listingId, successUrl, cancelUrl } = body;
  if (!process.env.STRIPE_SECRET_KEY) return NextResponse.json({ error: "Stripe not configured" }, { status: 500 });
  const stripe = new Stripe(process.env.STRIPE_SECRET_KEY!, { apiVersion: "2024-06-20" });

  // TODO: fetch authoritative price from DB using listingId
  const amount = 5000; // cents
  const session = await stripe.checkout.sessions.create({
    mode: "payment",
    line_items: [{ price_data: { currency: "usd", unit_amount: amount, product_data: { name: `Listing ${listingId}` }}, quantity: 1 }],
    success_url: successUrl || `${process.env.NEXT_PUBLIC_SITE_URL}/order/success`,
    cancel_url: cancelUrl || `${process.env.NEXT_PUBLIC_SITE_URL}/order/cancel`,
    metadata: { listingId }
  });
  return NextResponse.json({ url: session.url });
}
