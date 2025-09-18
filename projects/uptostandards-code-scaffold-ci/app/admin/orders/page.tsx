import { supabaseAdmin } from "../../../lib/supabaseClient";
export default async function OrdersAdmin() {
  const db = supabaseAdmin();
  const { data: orders } = await db.from("orders").select("id,status,amount_usd,provider,created_at").order("created_at", { ascending: false }).limit(200);
  return (
    <div className="space-y-4">
      <h1 className="text-2xl font-bold">Orders</h1>
      <table className="w-full text-sm">
        <thead><tr><th>ID</th><th>Status</th><th>Amount</th><th>Provider</th><th>Created</th></tr></thead>
        <tbody>
          {(orders||[]).map((o:any)=> (
            <tr key={o.id}><td>{o.id}</td><td>{o.status}</td><td>${o.amount_usd}</td><td>{o.provider}</td><td>{o.created_at}</td></tr>
          ))}
        </tbody>
      </table>
    </div>
  );
}
