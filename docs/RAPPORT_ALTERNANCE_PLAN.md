# Rapport d'alternance — Plan détaillé

> **Niveau visé** : Bac+5 / Master / Ingénieur
> **Type de plan** : analytique, articulé autour d'une problématique
> **Projet** : Dendreo Progression Dashboard — plateforme de pilotage de l'engagement apprenant chez Compétences et Métiers
> **Période couverte** : mai 2025 → mai 2026 (≈ 12 mois)

---

## Problématique proposée

> **Comment outiller un organisme de formation pour détecter automatiquement les décrochages en e-learning et orchestrer des interventions correctives traçables, en s'appuyant sur les données du LMS (Dendreo) et du CRM (HubSpot) ?**

**Sous-questions** :
- Comment fiabiliser une source de vérité unifiée à partir d'une API tierce limitée en débit (Dendreo) ?
- Comment qualifier l'inactivité d'un apprenant de manière fine (e-learning + classe virtuelle) ?
- Comment réinjecter l'action humaine (appels, notes, mails) dans la boucle métier sans dupliquer la saisie côté CRM ?
- Comment industrialiser le déploiement et l'exploitation d'un tel outil en équipe réduite ?

---

## Structure recommandée

### Pages liminaires
- Page de garde (école, entreprise, tuteurs, période)
- Remerciements
- Résumé / Abstract (FR + EN, ~250 mots)
- Sommaire
- Glossaire & acronymes (LMS, CRM, ADF, OF, Qualiopi, CPF, IaC, CI/CD, SSO, MSAL…)
- Liste des figures et tableaux

### Introduction (2–3 pages)
- Accroche : contexte de la formation professionnelle continue et enjeux d'engagement en e-learning
- Présentation succincte de l'entreprise et de la mission
- Énoncé de la **problématique**
- Annonce du plan

---

## Partie I — Contexte de l'alternance (15–20 pages)

### Chapitre 1. L'entreprise : Compétences et Métiers (CM)
- Activité : organisme de formation professionnelle, certifications Qualiopi
- Catalogue, typologie des formations (présentiel, distanciel, mixte), publics
- Organisation interne, équipe pédagogique et administrative
- Position dans l'écosystème : LMS Dendreo, CRM HubSpot, téléphonie Ringover, identité Microsoft 365

### Chapitre 2. L'écosystème technique avant le projet
- Dendreo comme LMS principal : forces et limites côté pilotage
- Données dispersées (Dendreo, HubSpot, exports manuels Excel)
- Absence de vision consolidée de l'engagement apprenant
- Charge administrative : suivi manuel des relances, pas de traçabilité

### Chapitre 3. La mission d'alternance
- Cadre : alternant développeur, autonomie sur la conception et la mise en production
- Encadrement (tuteur entreprise, tuteur école)
- Objectifs initiaux et évolution du périmètre sur 12 mois
- Méthodologie de travail : itérations courtes, recettage utilisateur direct, déploiement continu

---

## Partie II — Cadrage de la problématique (10–15 pages)

### Chapitre 4. Enjeux métier
- L'engagement apprenant comme indicateur Qualiopi et levier commercial
- Coût d'un décrochage non détecté (abandon, financement non justifié, image)
- Personae : équipe pédagogique, managers, direction

### Chapitre 5. Analyse de l'existant
- Workflow actuel des conseillers pédagogiques
- Limites de l'interface Dendreo native pour le pilotage transversal
- Tentatives précédentes (exports, tableaux croisés) — pourquoi insuffisantes

### Chapitre 6. État de l'art rapide
- Outils du marché : 360Learning, Beedeez, dashboards BI génériques (Metabase, Superset)
- Choix « build vs buy » : pourquoi un développement interne sur-mesure
- Inspirations techniques (architecture FastAPI + React, patterns de sync, observabilité)

### Chapitre 7. Cahier des charges et objectifs SMART
- Fonctionnels : liste paginée des ADF, détection inactivité, journal d'interventions, lien CRM
- Non-fonctionnels : disponibilité, fraîcheur des données (< 1 h), RGPD, accessibilité
- Critères de succès mesurables (taux d'adoption interne, réduction du temps de traitement par dossier, fraîcheur effective)

---

## Partie III — Conception et architecture (20–25 pages)

### Chapitre 8. Architecture globale
- Schéma d'ensemble : React → Nginx → FastAPI → PostgreSQL ← Sync container ← API Dendreo / HubSpot
- Justification des choix technologiques
  - **Backend** : FastAPI + SQLAlchemy + Pydantic Settings — typage strict, perfs async, OpenAPI auto
  - **Frontend** : React 18 + Tailwind — vélocité, écosystème, courbe d'apprentissage
  - **Base** : PostgreSQL — relationnel pour modèle riche (apprenants, modules, créneaux, interventions)
  - **Cache** : Redis pour endpoints lourds (inactivité paginée)
  - **Conteneurisation** : Docker Compose, séparation back / front / sync / nginx / postgres / redis / netdata

### Chapitre 9. Modélisation des données
- ERD : ADF, participants, modules, progression, créneaux liveroom, interventions, notes, deals HubSpot
- Choix structurants : table `creneau_participants` pour granularité présence, `is_manual_link` pour préserver les liens saisis manuellement
- Stratégie d'index et de performance

### Chapitre 10. Le service de synchronisation
- Architecture cron + wrapper shell + script Python idempotent
- Gestion du **rate limiting** Dendreo (90 req/10 s — marge volontaire sous le plafond de 100)
- Pagination, batching, gestion des erreurs partielles, reprise sur incident
- **Difficulté résolue** : les jobs cron n'héritent pas des variables Docker → génération de `cron_env.sh` à l'entrée du conteneur
- **Difficulté résolue** : instances SQLAlchemy détachées entre sessions → pattern « stocker l'id, refetch »

### Chapitre 11. L'algorithme d'inactivité
- Définition : `max(dernière activité e-learning, dernier créneau liveroom avec présence=1)`
- Pondération par mode de formation (présentiel pur exclu)
- Tiers d'inactivité (et suppression du tier `at_risk` après retour utilisateur)
- Filtres : déduplication par titre de module, exclusion des ADF archivés (statuts 5/6/7)

### Chapitre 12. Sécurité et authentification
- SSO Microsoft (MSAL) côté frontend, validation des tokens côté backend
- Modèle de rôles (Admin, Manager) et autorisation par route
- Gestion des secrets : **SOPS + age**, dépôt Git lisible mais déchiffrable uniquement par les clés autorisées
- Tunnel SSH dédié pour le dev (contournement MSAL/crypto)

---

## Partie IV — Réalisations fonctionnelles (25–30 pages)

> Présenter chaque grande fonctionnalité sous le format : **besoin → conception → implémentation → résultat → recul critique**.

### Chapitre 13. Le socle : dashboard ADF et fiches détaillées
- Vue paginée des actions de formation, recherche multi-mots
- Fiche ADF, fiche participant, fiche module
- Bouton retour « véritable précédente page » (et pourquoi ce détail UX compte)

### Chapitre 14. Le module de gestion des inactivités
- Page `InactiveManagement` : tri, filtres, tiers, ajout récent
- Cache Redis sur l'endpoint lourd, pagination côté serveur
- Vues sauvegardées (par page) pour chaque utilisateur

### Chapitre 15. Le journal d'interventions
- Actions disponibles : snooze, note, mail, appel, dismiss
- Timeline unifiée mixant notes Dendreo, notes internes, notes/appels HubSpot
- Filtres par type, suppression, troncature avec « voir plus »
- Proxy audio pour les enregistrements Ringover

### Chapitre 16. L'intégration HubSpot
- Liaison manuelle ADF ↔ deal avec garde anti-écrasement (`is_manual_link`)
- Push bidirectionnel : notes avec attribution propriétaire, progression sur propriétés deal personnalisées
- Récupération des appels via l'API d'associations
- Limitation et solution : scope `crm.objects.owners.read` à activer côté app privée HubSpot

### Chapitre 17. Module Management & exports
- Vue transverse des modules, déduplication par titre
- Exports Excel et PDF avec sélection de colonnes
- Filtres et vues sauvegardées par utilisateur

### Chapitre 18. L'admin et l'observabilité métier
- Dashboard sync : historique paginé, compteurs d'appels API calés sur calendrier, téléchargement de logs archivés
- Page « Action History » : audit des interventions humaines
- Compteur de prochain sync, rotation des logs

---

## Partie V — Industrialisation : déploiement, sécurité, supervision (15–20 pages)

### Chapitre 19. Infrastructure as Code
- VPS Scaleway (fr-par-1) provisionné par **Terraform**
- Configuration via **Ansible** (idempotente, rejouable)
- Justification du choix VPS vs PaaS managé : coût, contrôle, conformité données

### Chapitre 20. Pipeline CI/CD
- GitHub Actions : build des 3 images (back, sync, front) → push GHCR → déploiement SSH automatique sur push `main`
- Stratégies : attente de fin de sync avant redeploy (timeout 30 min), purge des images dangling, push du compose sur le VPS
- Healthchecks Docker : liveness uniquement pour le sync, business health via dashboard dédié

### Chapitre 21. Reverse-proxy, TLS, sous-domaines
- Nginx unique avec build React intégré (suppression de la race condition de volume)
- Exposition de Netdata via sous-domaine et basic auth
- Certificats SSL et rotation

### Chapitre 22. Supervision
- **Netdata** auto-installé via Ansible, alerte RAM faible (avec correctif `lookup` vs `calc`)
- Logs applicatifs centralisés, rotation, archives par sync téléchargeables
- Sauvegardes base : stratégie, fréquence, restauration testée

### Chapitre 23. Qualité logicielle
- Revue de code, ultrareview multi-agents, PR systématiques
- Conventions de commit, branches feature
- Limites assumées (couverture de tests, dette technique identifiée)

---

## Partie VI — Mesure d'impact et recul critique (10–15 pages)

### Chapitre 24. Adoption et bénéfices observés
- Indicateurs d'usage : utilisateurs actifs, nombre d'interventions tracées, taux de liens HubSpot manuels
- Gains qualitatifs côté équipe pédagogique (verbatims si possibles)
- Réduction estimée du temps de traitement par dossier inactif

### Chapitre 25. Limites et angles morts
- Dépendance forte à l'API Dendreo (rate limit, pannes, changements de schéma)
- Pas de tests automatisés systématiques — pourquoi, conséquences
- Périmètre RGPD à durcir (purge, droits d'accès apprenants)
- Coût d'exploitation d'un VPS dédié vs solution managée

### Chapitre 26. Choix discutables, refactorisations envisagées
- Monorepo vs séparation back/front
- React vs framework plus structurant (Next.js, Remix)
- Cron simple vs orchestrateur (Celery, Temporal, Prefect)
- Stratégie de sync : incrémental partiel à explorer

### Chapitre 27. Perspectives produit
- Push progression sur propriétés HubSpot avancées
- Notifications proactives (mail, Slack) sur seuils d'inactivité
- Dashboard mobile / responsive avancé
- Ouverture multi-organisme (multi-tenant)

---

## Partie VII — Bilan personnel (8–12 pages)

### Chapitre 28. Compétences techniques acquises ou consolidées
- Cartographie selon le référentiel de l'école (architecture distribuée, sécurité, conduite de projet, DevOps…)
- Trois compétences phares détaillées avec preuve : ex. *résoudre un incident SQLAlchemy en production*, *concevoir une stratégie de sync respectant un rate limit*, *industrialiser un déploiement IaC*

### Chapitre 29. Compétences transverses (soft skills)
- Recueil de besoins auprès d'utilisateurs non techniques
- Arbitrages produit / dette technique en autonomie
- Communication asynchrone (PR, notes de version)

### Chapitre 30. Posture d'ingénieur et leçons retenues
- Comprendre le métier avant de coder : la fonctionnalité « inactivité » a évolué 4 fois en 12 mois
- Préférer la simplicité : suppression de Portainer, d'un tier inactivité jugé bruyant
- Itérer en production avec filet de sécurité (PR, supervision, sauvegardes)

---

## Conclusion (2–3 pages)
- Réponse synthétique à la problématique
- Bénéfices durables pour CM, pistes ouvertes
- Apport personnel de l'alternance dans le projet professionnel

---

## Pages finales
- **Bibliographie / Webographie** : docs Dendreo, HubSpot, FastAPI, React, Terraform, articles cités
- **Annexes**
  - A. Schéma d'architecture détaillé
  - B. ERD complet de la base
  - C. Extraits de code commentés (sync wrapper, algorithme inactivité, garde `is_manual_link`)
  - D. Captures d'écran des principales pages
  - E. Extraits de configuration (Terraform, Ansible, GitHub Actions)
  - F. Matrice des compétences école ↔ réalisations

---

## Conseils de rédaction

- **Format cible** : ~80–120 pages hors annexes selon l'école
- **Style** : « je » assumé dans le bilan personnel, neutre/passif dans les parties techniques
- **Figures** : prévoir au moins une figure par chapitre technique (schémas, captures, graphes)
- **Recul critique** : ne pas survendre — chaque réalisation gagne à être assortie d'une limite identifiée
- **Fil rouge** : ramener régulièrement à la problématique en fin de chapitre (« en quoi cela contribue à détecter / corriger les décrochages »)
- **Traçabilité** : pour chaque chiffre annoncé (rate limit, fraîcheur, gains), citer la source ou l'expérimentation

---

## Prochaines étapes proposées

1. Valider ou ajuster la **problématique** (variante possible si tu veux centrer sur DevOps plutôt que produit)
2. Faire valider le plan par les tuteurs école et entreprise
3. Lister les **figures et annexes** à produire (1 jour de travail dédié)
4. Rédiger en premier la **Partie III (architecture)** et la **Partie IV (réalisations)** — les plus longues, le reste s'articule autour
5. Demander dès maintenant à 2–3 utilisateurs internes une courte interview pour le chapitre 24
