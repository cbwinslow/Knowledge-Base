import * as cloudflare from "@pulumi/cloudflare";

const accountId = process.env.CLOUDFLARE_ACCOUNT_ID!;
// Example placeholder: you can add D1/KV definitions via Pulumi.
// Export something trivial so 'pulumi up' works.
export const hello = `CloudCurio StackHub wired to account ${accountId}`;
