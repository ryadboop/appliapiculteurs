# Suivi des ruches IziGreen

Dashboard interne pour piloter les ruchers, clients et chiffre d'affaires IziGreen.
React + Vite + Tailwind v4 + Supabase, installable comme une app sur téléphone (PWA).

## État actuel (étape 1/2)

✅ Authentification (email / mot de passe), rôles admin / utilisateur
✅ Dashboard : KPIs de la saison, historique par année, tableau filtrable par statut
✅ Sécurité : le chiffre d'affaires n'est jamais transmis aux comptes non-admin, même
   via l'inspecteur réseau du navigateur (masqué côté base de données, pas juste à l'écran)
✅ Installable sur téléphone (PWA), mise à jour automatique sans réinstallation

🔜 À venir (étape 2) : formulaire "Ajouter une ruche" (multi-étapes, géolocalisation,
   prix personnalisé, rucher partagé hôte/hébergé), vue détaillée d'un rucher,
   suppression avec confirmation, confettis à la création.

## Mise en route

### 1. Base de données Supabase

1. Crée un projet gratuit sur [supabase.com](https://supabase.com) (région EU, ex. Frankfurt).
2. Va dans **SQL Editor > New query**, colle tout le contenu de `supabase/schema.sql`, et exécute.
3. Va dans **Authentication > Users > Add user** pour créer tes comptes (un par personne).
   Un profil "utilisateur" est créé automatiquement pour chacun.
4. Passe-toi (et tes futurs admins) en rôle admin, dans **SQL Editor** :
   ```sql
   update public.profiles set role = 'admin'
   where id = (select id from auth.users where email = 'ton.email@izigreen.fr');
   ```

### 2. Configuration locale

```bash
cp .env.example .env.local
```

Remplis `.env.local` avec l'URL et la clé **anon/public** du projet
(Supabase > Project Settings > API) — jamais la clé `service_role`.

### 3. Lancer en local

```bash
npm install
npm run dev
```

### 4. Déployer (gratuit)

Pousse ce projet sur un repo GitHub, connecte-le à Vercel ou Netlify, et ajoute
les deux mêmes variables d'environnement (`VITE_SUPABASE_URL`,
`VITE_SUPABASE_ANON_KEY`) dans les réglages du projet côté hébergeur.
Chaque `git push` redéploie automatiquement, sans réinstallation côté utilisateurs.

### Icônes

`public/icon-192.png` et `public/icon-512.png` sont des icônes provisoires
(alvéole dorée sur fond vert forêt). À remplacer par le logo IziGreen si besoin —
mêmes noms de fichiers, mêmes dimensions.
