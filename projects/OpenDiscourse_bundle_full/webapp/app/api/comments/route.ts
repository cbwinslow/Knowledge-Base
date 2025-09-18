import { NextRequest, NextResponse } from 'next/server'

async function verifyTurnstile(token: string) {
  const body = new URLSearchParams();
  body.append('secret', process.env.TURNSTILE_SECRET!);
  body.append('response', token);
  const resp = await fetch('https://challenges.cloudflare.com/turnstile/v0/siteverify', { method: 'POST', body });
  const data = await resp.json();
  return data.success === true;
}

export async function POST(req: NextRequest) {
  const { token, comment } = await req.json();
  if (!await verifyTurnstile(token)) return NextResponse.json({ ok: false }, { status: 400 });
  // TODO: persist to discuss_comment
  return NextResponse.json({ ok: true });
}
