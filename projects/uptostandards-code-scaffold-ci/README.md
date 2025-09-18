# UpToStandards — Code Scaffold + CI

This bundle contains lightweight payment routes (Stripe/PayPal), webhooks, admin orders page, DB migrations, middleware, and CI workflows.

## How to use
1. Copy these files into your Next.js app root (expanded MVP).
2. Apply `supabase/payments.sql` in Supabase SQL editor.
3. Add env vars in `.env` for Stripe and PayPal.
4. Push to GitHub — CI runs lint/typecheck/build automatically.
