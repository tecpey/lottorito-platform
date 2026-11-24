// Synthetic authentication fixture only. This is not production authentication.
export const TENANT_A = "11111111-1111-4111-8111-111111111111";
export const TENANT_B = "22222222-2222-4222-8222-222222222222";
export const SHARED_RECORD_ID = "aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa";
export const TENANT_B_ONLY_RECORD_ID = "bbbbbbbb-bbbb-4bbb-8bbb-bbbbbbbbbbbb";

const principalsByToken = new Map([
  ["p01-synthetic-token-a", { subjectId: "synthetic-user-a", tenantId: TENANT_A }],
  ["p01-synthetic-token-b", { subjectId: "synthetic-user-b", tenantId: TENANT_B }]
]);

export async function authenticateSyntheticRequest(req) {
  const authorization = req.headers.authorization ?? "";
  const match = authorization.match(/^Bearer (.+)$/);
  return match ? principalsByToken.get(match[1]) ?? null : null;
}
