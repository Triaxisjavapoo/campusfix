import { createClient } from "@supabase/supabase-js";
import { createRemoteJWKSet, jwtVerify } from "jose";
import { createEvidenceHandler } from "./handler.ts";

const projectId = Deno.env.get("FIREBASE_PROJECT_ID") ?? "campusfix-ae32e";
const jwks = createRemoteJWKSet(
  new URL(
    "https://www.googleapis.com/service_accounts/v1/jwk/securetoken@system.gserviceaccount.com",
  ),
);
const supabase = createClient(
  Deno.env.get("SUPABASE_URL")!,
  Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!,
  { auth: { persistSession: false, autoRefreshToken: false, detectSessionInUrl: false } },
);

Deno.serve(createEvidenceHandler({
  projectId,
  storage: supabase.storage.from("campusfix-evidence"),
  allowedOrigins: [
    `https://${projectId}.web.app`,
    `https://${projectId}.firebaseapp.com`,
    ...(Deno.env.get("ALLOWED_ORIGINS") ?? "").split(",").map((s) => s.trim()).filter(Boolean),
  ],
  async verifyToken(token) {
    const { payload } = await jwtVerify(token, jwks, {
      algorithms: ["RS256"],
      issuer: `https://securetoken.google.com/${projectId}`,
      audience: projectId,
      requiredClaims: ["exp", "iat", "auth_time", "sub"],
    });
    const now = Math.floor(Date.now() / 1000);
    if (
      !payload.sub || payload.sub.length > 128 ||
      typeof payload.iat !== "number" || payload.iat > now ||
      typeof payload.auth_time !== "number" || payload.auth_time > now
    ) {
      throw new Error("Invalid Firebase identity");
    }
    return payload.sub;
  },
}));
