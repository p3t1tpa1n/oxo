// Edge Function : création d'utilisateur côté serveur.
//
// Seuls les appelants authentifiés avec le rôle admin ou associé peuvent
// créer un compte. La clé service_role n'existe que dans ce contexte serveur
// (injectée par la plateforme) — le client Flutter n'appelle plus jamais
// auth.signUp ni n'écrit profiles.role.
//
// Déploiement : supabase functions deploy admin-create-user

import { createClient } from "npm:@supabase/supabase-js@2";

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers":
    "authorization, x-client-info, apikey, content-type",
  "Access-Control-Allow-Methods": "POST, OPTIONS",
};

const STAFF_ROLES = ["admin", "associe", "associé"];
const ALLOWED_NEW_ROLES = ["admin", "associe", "partenaire", "client"];

function json(status: number, body: unknown): Response {
  return new Response(JSON.stringify(body), {
    status,
    headers: { ...corsHeaders, "Content-Type": "application/json" },
  });
}

Deno.serve(async (req) => {
  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: corsHeaders });
  }
  if (req.method !== "POST") {
    return json(405, { error: "Méthode non autorisée" });
  }

  const supabaseUrl = Deno.env.get("SUPABASE_URL")!;
  const serviceRoleKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!;
  const anonKey = Deno.env.get("SUPABASE_ANON_KEY")!;

  // 1. Identifier l'appelant à partir de son JWT.
  const authHeader = req.headers.get("Authorization");
  if (!authHeader) {
    return json(401, { error: "Non authentifié" });
  }

  const callerClient = createClient(supabaseUrl, anonKey, {
    global: { headers: { Authorization: authHeader } },
  });

  const { data: userData, error: userError } =
    await callerClient.auth.getUser();
  if (userError || !userData.user) {
    return json(401, { error: "Session invalide" });
  }

  // 2. Vérifier que l'appelant est admin/associé (lecture avec service_role
  //    pour ne pas dépendre de la RLS).
  const adminClient = createClient(supabaseUrl, serviceRoleKey);

  const { data: callerProfile, error: profileError } = await adminClient
    .from("profiles")
    .select("role")
    .eq("user_id", userData.user.id)
    .single();

  if (profileError || !callerProfile) {
    return json(403, { error: "Profil appelant introuvable" });
  }
  if (!STAFF_ROLES.includes(String(callerProfile.role).toLowerCase())) {
    return json(403, {
      error: "Seul un administrateur ou un associé peut créer un compte",
    });
  }

  // 3. Valider la requête.
  let body: {
    email?: string;
    first_name?: string;
    last_name?: string;
    phone?: string;
    role?: string;
    company_id?: number;
  };
  try {
    body = await req.json();
  } catch {
    return json(400, { error: "Corps JSON invalide" });
  }

  const { email, first_name, last_name, phone, role, company_id } = body;
  if (!email || !role) {
    return json(400, { error: "Champs requis : email, role" });
  }
  if (!ALLOWED_NEW_ROLES.includes(role.toLowerCase())) {
    return json(400, { error: `Rôle invalide : ${role}` });
  }
  // Seul un admin peut créer un autre admin.
  if (
    role.toLowerCase() === "admin" &&
    String(callerProfile.role).toLowerCase() !== "admin"
  ) {
    return json(403, { error: "Seul un admin peut créer un compte admin" });
  }

  // 4. Créer le compte auth (email confirmé, mot de passe défini par
  //    l'utilisateur via le lien d'invitation — pas de mot de passe en clair
  //    qui transite par l'admin).
  const { data: created, error: createError } =
    await adminClient.auth.admin.createUser({
      email,
      email_confirm: true,
    });

  if (createError || !created.user) {
    return json(422, {
      error: `Création du compte impossible : ${createError?.message}`,
    });
  }

  // 5. Créer le profil (rollback du compte auth si échec pour ne pas laisser
  //    un utilisateur sans profil).
  const { error: insertError } = await adminClient.from("profiles").insert({
    user_id: created.user.id,
    email,
    first_name: first_name ?? null,
    last_name: last_name ?? null,
    phone: phone ?? null,
    role: role.toLowerCase(),
    status: "actif",
    company_id: company_id ?? null,
  });

  if (insertError) {
    await adminClient.auth.admin.deleteUser(created.user.id);
    return json(422, {
      error: `Création du profil impossible : ${insertError.message}`,
    });
  }

  // 6. Envoyer le lien de définition du mot de passe.
  const { error: resetError } = await adminClient.auth.resetPasswordForEmail(
    email,
  );
  if (resetError) {
    // Non bloquant : le compte existe, l'email peut être renvoyé plus tard.
    console.error("Envoi de l'email d'invitation échoué:", resetError.message);
  }

  return json(200, { user_id: created.user.id, email });
});
