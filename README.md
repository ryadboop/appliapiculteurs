# Suivi des ruches IziGreen

Dashboard interne pour piloter les ruchers, clients et chiffre d'affaires IziGreen.
React + Vite + Tailwind v4 + Supabase, installable comme une app sur téléphone (PWA).

Schéma et logique métier alignés sur le projet Lovable d'origine (mêmes noms de
tables/colonnes, mêmes règles de calcul), avec deux renforts de sécurité que
l'original n'avait pas : le CA est masqué en base (pas juste à l'écran) pour
les comptes non-admin, et la création de ruches est réservée aux admins côté
base de données.

## État actuel

✅ Authentification, rôles admin / utilisateur (table `user_roles`)
✅ Dashboard : KPIs, filtres par statut, tableau des ruchers
✅ Formulaire d'ajout en 3 étapes (identité, implantation, engagement) avec
   géolocalisation, aperçu carte, rucher partagé hôte/hébergé, prix personnalisé
✅ Vue détaillée d'un rucher, éditable par les admins uniquement
✅ Suppression avec avertissement si l'engagement 3 ans n'est pas terminé
✅ Historique par année (calculé dynamiquement, pas de tâche planifiée),
   export CSV
✅ Confettis à la création d'une ruche, compteurs animés, anneau de progression
   de l'engagement
✅ Installable sur téléphone (PWA), mise à jour automatique sans réinstallation
✅ Journal d'audit (qui a créé/modifié/supprimé quoi, et quand), restauration
   d'un rucher supprimé
✅ Sauvegarde quotidienne automatique de la base (GitHub Actions, gratuite)

🔜 À venir : l'espace admin (`/admin`) est pour l'instant un écran d'attente.
   La création/suppression de comptes utilisateurs directement depuis l'appli
   nécessite une Supabase Edge Function (pour manipuler les comptes avec la
   clé secrète, jamais exposée au navigateur) — prochaine étape.
   En attendant, gère les comptes depuis Supabase (Authentication > Users).

## Mise en route

### 1. Base de données Supabase

1. Crée un projet gratuit sur [supabase.com](https://supabase.com) (région EU, ex. Frankfurt).
2. **SQL Editor > New query**, colle tout `supabase/schema.sql`, exécute.
   Le script passe automatiquement `ryad.bouchami@izigroup.fr` en admin dès
   que ce compte est créé — modifie l'email dans le script avant de l'exécuter
   si besoin.
3. **Authentication > Users > Add user** pour chaque personne. Un compte sans
   ligne dans `user_roles` est un utilisateur standard en lecture seule par
   défaut — pas besoin d'action supplémentaire pour ça.
4. Pour donner les droits admin à quelqu'un d'autre que toi :
   ```sql
   insert into public.user_roles (user_id, role)
   values ((select id from auth.users where email = '...'), 'admin');
   ```

### 2. Configuration locale

```bash
cp .env.example .env.local
```

Remplis avec l'URL et la clé **anon/public** du projet (Project Settings > API).

### 3. Lancer en local

```bash
npm install
npm run dev
```

### 4. Déployer (gratuit)

Pousse sur GitHub, connecte le repo à Vercel ou Netlify, ajoute les deux
variables d'environnement (`VITE_SUPABASE_URL`, `VITE_SUPABASE_ANON_KEY`)
côté hébergeur. Chaque `git push` redéploie automatiquement.

### Icônes

`public/icon-192.png` et `public/icon-512.png` sont provisoires — à
remplacer par le logo IziGreen si besoin, mêmes noms de fichiers.

### Activer la sauvegarde automatique quotidienne

Le workflow existe déjà (`.github/workflows/backup.yml`), il ne manque
qu'une information secrète pour qu'il puisse se connecter à la base :

1. **Récupère la chaîne de connexion** : Supabase > Project Settings (⚙️)
   > Database > Connection string > sélectionne le format **URI**. Si tu ne
   te souviens plus du mot de passe de la base, un bouton "Reset database
   password" est juste à côté.
2. **Ajoute-la comme secret GitHub** : sur `github.com/ryadboop/appliapiculteurs`
   > Settings > Secrets and variables > Actions > **New repository secret**.
   Nom : `SUPABASE_DB_URL`. Valeur : la chaîne de connexion complète
   (avec le mot de passe dedans, à la place de `[YOUR-PASSWORD]`).
3. C'est tout. La sauvegarde tourne chaque nuit automatiquement, et garde
   les 14 derniers jours dans le dossier `backups/` du repo (les plus
   anciennes sont supprimées automatiquement).

Pour tester tout de suite sans attendre la nuit : onglet **Actions** du
repo > "Sauvegarde quotidienne Supabase" > **Run workflow**.

Ces sauvegardes couvrent uniquement les données de l'appli (`public`),
pas les comptes/mots de passe (gérés par Supabase lui-même).
