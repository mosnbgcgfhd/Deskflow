// Supabase Edge Function: invite-user
//
// WHY THIS EXISTS: creating a new auth user requires the Supabase
// service-role key. That key must never be shipped inside the Flutter
// app (anyone could decompile the app and take over every organization
// on the platform). So user creation happens here, server-side, using
// a key that only ever lives in Supabase's own environment.
//
// Deploy with:  supabase functions deploy invite-user
// The service-role key is already available to Edge Functions as
// SUPABASE_SERVICE_ROLE_KEY — you do not set this yourself.

import { serve } from "https://deno.land/std@0.224.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2.45.0";

const SUPABASE_URL = Deno.env.get("SUPABASE_URL")!;
const SERVICE_ROLE_KEY = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!;

serve(async (req) => {
  try {
    const authHeader = req.headers.get("Authorization");
    if (!authHeader) {
      return json({ error: "Missing Authorization header" }, 401);
    }

    // Client bound to the CALLER's own JWT — used only to verify who
    // is calling and to look up their profile (organization + role).
    const callerClient = createClient(SUPABASE_URL, SERVICE_ROLE_KEY, {
      global: { headers: { Authorization: authHeader } },
    });

    const {
      data: { user: caller },
      error: callerError,
    } = await callerClient.auth.getUser();

    if (callerError || !caller) {
      return json({ error: "Not authenticated" }, 401);
    }

    // Admin client — full privileges, used only for the two writes below.
    const adminClient = createClient(SUPABASE_URL, SERVICE_ROLE_KEY);

    const { data: callerProfile, error: profileError } = await adminClient
      .from("profiles")
      .select("organization_id, role")
      .eq("id", caller.id)
      .single();

    if (profileError || !callerProfile) {
      return json({ error: "Caller has no profile" }, 403);
    }

    // Enforced here too, not just in RLS: only admins invite people.
    if (callerProfile.role !== "admin") {
      return json({ error: "Only an admin can invite employees" }, 403);
    }

    const { email, full_name, role } = await req.json();
    if (!email || !full_name) {
      return json({ error: "email and full_name are required" }, 400);
    }
    if (role !== "manager" && role !== "employee") {
      return json({ error: "role must be 'manager' or 'employee'" }, 400);
    }

    // Creates the auth user AND immediately emails them an invite link
    // (Supabase handles the email delivery + password-set flow).
    const { data: created, error: createError } =
      await adminClient.auth.admin.inviteUserByEmail(email);

    if (createError || !created?.user) {
      return json({ error: createError?.message ?? "Could not create user" }, 400);
    }

    const { error: insertError } = await adminClient.from("profiles").insert({
      id: created.user.id,
      organization_id: callerProfile.organization_id,
      full_name,
      role,
    });

    if (insertError) {
      // Roll back the orphaned auth user so a failed invite doesn't
      // leave a dangling account with no profile.
      await adminClient.auth.admin.deleteUser(created.user.id);
      return json({ error: insertError.message }, 400);
    }

    return json({ success: true, user_id: created.user.id }, 200);
  } catch (e) {
    return json({ error: String(e) }, 500);
  }
});

function json(body: unknown, status: number) {
  return new Response(JSON.stringify(body), {
    status,
    headers: { "Content-Type": "application/json" },
  });
}
