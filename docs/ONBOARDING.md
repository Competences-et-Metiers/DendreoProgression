# Onboarding : infrastructure et où trouver l'information

Pour les collaborateurs qui reprennent ce projet. Ceci ne donne que la vue d'ensemble —
le détail se trouve dans les documents liés.

L'application repose sur deux services principaux : **Scaleway** (hébergement) et
**GitHub** (code + déploiement).

## 1. De quoi s'agit-il

Une application full-stack qui synchronise les données de cours/participants du LMS
Dendreo (et de HubSpot) vers un tableau de bord de suivi de la progression et de
l'engagement des apprenants. Voir le [README.md](../README.md) à la racine pour les
fonctionnalités et la surface d'API.

## 2. Documentation déjà présente dans le repo

- [docs/README.md](README.md) — index de tout ce qui suit
- [docs/deployment/](deployment/) — guides de déploiement. Plusieurs se recoupent ou
  sont obsolètes ; `docs/archive/` contient ceux qui sont totalement remplacés. En cas
  de doute, vérifiez plutôt le code réel dans `infra/` et dans `.github/workflows/`
  plutôt que de faire confiance aveuglément à un document.
- [docs/features/](features/) — descriptifs de fonctionnalités spécifiques (cleanup,
  ID entreprise, sync)
- [back/AGENT.md](../back/AGENT.md) et [frontend/AGENT.md](../frontend/AGENT.md) —
  stack technique, structure des dossiers et conventions pour chaque sous-projet. Ce
  sont les références les plus fiables sur « comment ce code est construit », écrites
  aussi bien pour les agents IA que pour les humains.

## 3. Où un agent IA trouve son contexte

Pointez-le vers `back/AGENT.md` / `frontend/AGENT.md` et ce dossier `docs/` — c'est le
contexte durable et partagé qui vit avec le repo.

Un point important à connaître : un assistant qui travaille sur la durée, comme
Claude Code, construit aussi sa propre **mémoire locale** des décisions d'infra, des
pièges rencontrés et de l'état du projet au fil du travail. Cette mémoire vit sur la
machine/le compte où elle a été créée, pas dans git — elle ne se transmet **pas**
automatiquement à un nouveau collaborateur ou à une nouvelle machine. Traitez-la comme
des notes de travail de la personne qui pilote au moment donné, pas comme de la
documentation. Si quelque chose appris de cette façon vaut la peine d'être conservé
(une décision d'infra, un piège récurrent), il doit être écrit dans ce dossier `docs/`
ou dans un `AGENT.md` pour que la prochaine personne/le prochain agent en dispose
réellement.

## 4. Scaleway

Héberge toute la plateforme — base de données, backups, stockage, etc. C'est aussi là
que se fait le paiement de l'hébergement.

**Accès** : Victor crée les accès admin sur la console Scaleway. Une fois cet accès
obtenu, l'accès SSH au VPS se fait via le bouton **Console** sur la page du serveur.

![Panneau « Access » du VPS dans la console Scaleway, avec la commande SSH et le bouton Console](images/scaleway-console-access.png)

### Se donner un accès SSH personnel

Une fois connecté·e en root via la Console web, on ajoute sa propre clé à
l'utilisateur `deploy` (c'est cet utilisateur, pas `root` ni `ubuntu`, qui est
configuré/durci pour l'usage courant — voir le rôle Ansible `common`) :

**1. Sur votre machine**, générez une paire de clés :

```bash
ssh-keygen -t ed25519 -f ~/.ssh/deploy_key -C "deploy-key-$(hostname)"
cat ~/.ssh/deploy_key.pub
```

**2. Dans la Console Scaleway** (session root sur le VPS), ajoutez la clé publique à
l'utilisateur `deploy` :

```bash
su - deploy
mkdir -p ~/.ssh && chmod 700 ~/.ssh
echo "ssh-ed25519 AAAA... deploy-key-<hostname>" >> ~/.ssh/authorized_keys
chmod 600 ~/.ssh/authorized_keys
exit
```

**3. Depuis votre machine**, vous pouvez maintenant vous connecter directement :

```bash
ssh -i ~/.ssh/deploy_key deploy@163.172.153.172
```

Ceci est indépendant du secret GitHub `VPS_SSH_KEY` (la clé dédiée que la CI utilise
pour déployer automatiquement) — vous ajoutez simplement une deuxième clé autorisée
dans le même `authorized_keys`, sans rien toucher côté GitHub.

### Ce qui tourne sur le VPS

- Un seul VPS, région `fr-par-1` (Paris — choisi pour la conformité RGPD des données
  de formation françaises), Ubuntu 22.04. Domaine
  `dendreo.competences-et-metiers.com` (DNS chez Hostinger), SSL via Let's
  Encrypt/certbot.
- `docker-compose.prod.yml` fait tourner toute la stack : `nginx`, `backend`
  (FastAPI), `sync` (jobs cron de synchronisation Dendreo/HubSpot), `postgres`,
  `redis`, `netdata` (monitoring).
- **IaC** (`infra/`) : Terraform provisionne le VPS, son groupe de sécurité, et un
  bucket Object Storage pour les sauvegardes. Ansible le configure, via 4 rôles —
  `common` (durcissement OS/pare-feu/utilisateur deploy), `docker`, `app` (fichiers
  compose, nginx, secrets, SSL), `backup` (rclone + cron pg_dump).
- **Secrets** : chiffrés au repos avec SOPS + age, committés en tant que fichiers
  `*.enc` dans `secrets/`. Déchiffrables uniquement avec la clé privée age, qui vit sur
  le VPS (et chez la personne qui l'administre) — pas dans git.
- **Sauvegardes** : `pg_dump` quotidien vers Scaleway Object Storage via rclone,
  rétention de 30 jours.

`setup-server.sh` et `deploy-prod.sh` à la racine du repo couvrent la configuration
initiale du serveur et les déploiements manuels, si le VPS doit un jour être
reconstruit de zéro.

## 5. GitHub

Met à jour la plateforme à chaque push sur la branche `main` du repo. Nécessite un
compte GitHub avec accès au repo pour contribuer.

![Run du workflow « Build and Push Docker Images » dans l'onglet Actions de GitHub, avec les 3 builds et le déploiement en succès](images/github-actions-run.png)

Un seul workflow : [.github/workflows/docker-build.yml](../.github/workflows/docker-build.yml).

- À chaque push sur `main`/`dev` (ou un tag `v*`) : construit les 3 images Docker
  (backend, sync, frontend) et les pousse vers GHCR (registre de conteneurs GitHub).
- Sur push vers `main` **spécifiquement**, un second job déploie aussi : il attend la
  fin d'une éventuelle synchronisation en cours, se connecte en SSH au VPS, récupère
  les nouvelles images, redémarre la stack avec `docker compose`, nettoie les anciennes
  images, et vérifie `/health`.
- **Merger sur `main`, c'est déployer.** Il n'y a pas d'étape de release manuelle
  séparée pour les changements normaux.
- ⚠️ **À noter** : ce workflow ne lance pas de suite de tests automatisés — c'est
  uniquement du build + push + déploiement. Le repo a des hooks `pre-commit` locaux
  (formatage `black`, lint `flake8`, garde-fous anti-fichiers `.env`/cache) mais ils
  ne s'exécutent pas en CI aujourd'hui ; à mettre en place si une suite de tests
  automatisée est souhaitée avant déploiement.
- Nécessite ces secrets GitHub du repo : `VPS_HOST`, `VPS_USER`, `VPS_SSH_KEY` (accès
  SSH de déploiement), `GHCR_PAT` (pour récupérer les images sur le VPS), et
  `AZURE_AD_CLIENT_ID` / `AZURE_AD_TENANT_ID` / `AZURE_AD_REDIRECT_URI` (arguments de
  build pour l'auth Microsoft du frontend).

## 6. Obtenir les accès — récapitulatif

Pour administrer le VPS ou l'infra, il vous faudra, auprès du mainteneur actuel (rien
de tout ça n'est dans git) :

- Accès admin à la console Scaleway (créé par Victor)
- Accès SSH en tant qu'utilisateur `deploy` (voir §4 ci-dessus)
- La clé privée age de SOPS, pour déchiffrer les secrets dans `secrets/`
- Un compte GitHub avec accès au repo, et les secrets GitHub Actions listés en §5

### Comment ces clés sont transmises

Les clés Scaleway et la clé privée SOPS ne passent ni par email ni par chat : elles
sont déposées sous forme de fichiers dans le **SharePoint, dossier IT**. Deux fichiers
distincts :

- **Clés API Scaleway** (variables d'environnement pour Terraform/Ansible et pour
  l'API Scaleway) :

  ```
  SCW_ACCESS_KEY=
  SCW_SECRET_KEY=
  SCW_DEFAULT_ORGANIZATION_ID=
  SCW_DEFAULT_PROJECT_ID=
  Root_key=
  ```

- **Clé privée age (SOPS)** — au format généré par `age-keygen`, à placer telle quelle
  sur la machine à `~/.config/sops/age/keys.txt` pour pouvoir déchiffrer les fichiers
  `secrets/*.enc` :

  ```
  # created: 2026-04-01T14:53:11+02:00
  # public key: age1XXX
  AGE-SECRET-KEY-XXXX
  ```

⚠️ Ces fichiers contiennent un accès complet au compte Scaleway (donc à la
facturation) et à tous les secrets chiffrés du repo — à traiter comme des mots de
passe root. Ne jamais les copier dans le repo git, dans Slack/Teams ou dans un email.
Une fois le nouveau collaborateur onboardé, envisager de faire tourner (régénérer) ces
clés côté Scaleway/age plutôt que de laisser une copie indéfiniment accessible dans le
SharePoint.

## 7. Pour aller plus loin

| Sujet | Fichier |
|---|---|
| Guide de déploiement complet | [docs/deployment/DEPLOYMENT_GUIDE.md](deployment/DEPLOYMENT_GUIDE.md) |
| Conteneur sync / jobs cron | [docs/deployment/CONTAINER_SYNC_DEPLOYMENT.md](deployment/CONTAINER_SYNC_DEPLOYMENT.md) |
| Migrer la base de données entre machines | [docs/deployment/DATABASE_MIGRATION.md](deployment/DATABASE_MIGRATION.md) |
| Tunnel SSH pour du dev local sur des données proches de la prod | [docs/deployment/SSH_TUNNEL.md](deployment/SSH_TUNNEL.md) |
| Architecture/conventions backend | [back/AGENT.md](../back/AGENT.md) |
| Architecture/conventions frontend | [frontend/AGENT.md](../frontend/AGENT.md) |
| Terraform | `infra/terraform/` |
| Ansible | `infra/ansible/` |
