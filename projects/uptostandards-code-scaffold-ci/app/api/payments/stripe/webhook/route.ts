import { headers } from "next/headers";
import { NextResponse } from "next/server";
import Stripe from "stripe";

export async function POST(req: Request) {
  const buf = Buffer.from(await req.arrayBuffer());
  const sig = (await headers()).get("stripe-signature");
  const secret = process.env.STRIPE_WEBHOOK_SECRET!;
  if (!sig || !secret) return NextResponse.json({ error: "Webhook not configured" }, { status: 500 });
  const stripe = new Stripe(process.env.STRIPE_SECRET_KEY!, { apiVersion: "2024-06-20" });

  try {
    const event = stripe.webhooks.constructEvent(buf, sig, secret);
    // TODO: idempotent upsert to orders/order_events based on event.id
    return NextResponse.json({ received: true });
  } catch (e: any) {
    return NextResponse.json({ error: e.message }, { status: 400 });
  }
}
