import { createClient } from '@supabase/supabase-js'

const supabaseUrl = import.meta.env.VITE_SUPABASE_URL
const supabaseAnonKey = import.meta.env.VITE_SUPABASE_ANON_KEY

if (!supabaseUrl || !supabaseAnonKey) {
  // Message clair plutôt qu'une erreur réseau cryptique si les variables
  // d'environnement n'ont pas été configurées (local ou sur l'hébergeur).
  console.error(
    "Configuration Supabase manquante : vérifie VITE_SUPABASE_URL et VITE_SUPABASE_ANON_KEY dans .env.local (ou les variables d'environnement de l'hébergeur)."
  )
}

export const supabase = createClient(supabaseUrl, supabaseAnonKey)
