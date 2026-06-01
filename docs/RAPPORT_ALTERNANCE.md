# Rapport d'alternance

**Conception et industrialisation d'une plateforme de pilotage de l'engagement apprenant pour un organisme de formation : intégration LMS Dendreo et CRM HubSpot**

---

**Auteur** : LE Dang Quoc Tuan
**École** : EPITECH Paris
**Cycle / Promotion** : MSc Pro — Promotion 2026
**Entreprise d'accueil** : Compétences et Métiers
**Période d'alternance** : novembre 2024 – septembre 2026
**Tuteur entreprise** : Victor LANARD DOMINI
**Responsable de promotion (EPITECH)** : Lucile CASENOVE

---

> *Note d'usage : ce document est un brouillon de rapport. Avant impression, appliquer la mise en forme attendue (Times New Roman 12, interligne 1,5, texte justifié, marges 2,5 cm, pagination en pied de page) et compléter les champs `[...]`. Cible : 30 à 60 pages hors annexes.*

---

## Remerciements

Je tiens à exprimer ma sincère reconnaissance à l'ensemble des personnes qui ont rendu possible et enrichissant ce parcours d'alternance.

Je remercie tout d'abord **Joseph ABECASSIS**, dirigeant de Compétences et Métiers, pour la confiance qu'il m'a accordée en me confiant la conception d'un outil stratégique pour l'activité de l'organisme. La latitude technique dont j'ai bénéficié tout au long de la mission a été aussi formatrice qu'enrichissante.

Je remercie tout particulièrement **Victor LANARD DOMINI**, mon tuteur en entreprise, pour son accompagnement quotidien, sa disponibilité, et la qualité des échanges techniques et fonctionnels que nous avons eus. Ses retours réguliers et son exigence m'ont permis de progresser sur des aspects qui dépassaient le seul cadre du développement logiciel — notamment la conduite de projet, la priorisation produit et la communication avec des utilisateurs non techniques.

Je remercie également **Lucile CASENOVE**, responsable de ma promotion à EPITECH Paris, pour son écoute, ses conseils méthodologiques et ses relectures lors des points de suivi.

Mes remerciements vont aussi à l'ensemble de l'équipe pédagogique et administrative de Compétences et Métiers : conseillers en formation, formateurs, équipe administrative. Leurs retours utilisateurs, parfois exigeants, toujours constructifs, ont façonné la plateforme telle qu'elle existe aujourd'hui.

Enfin, je remercie mes proches pour leur soutien tout au long de cette année exigeante mais profondément formatrice.

---

## Sommaire

> *À régénérer automatiquement après mise en forme finale. Indication des chapitres et numéros de page.*

- Remerciements
- Sommaire
- Glossaire et acronymes
- Introduction
- I. Présentation de l'entreprise
  - 1.1 Compétences et Métiers : un organisme de formation professionnelle
  - 1.2 Activité, marché et positionnement
  - 1.3 Organisation interne
  - 1.4 L'écosystème numérique avant le projet
- II. Projets réalisés
  - 2.1 Vue d'ensemble : la plateforme « Dendreo Progression »
  - 2.2 Architecture technique et choix structurants
  - 2.3 Le moteur de synchronisation Dendreo
  - 2.4 Le module de détection des inactivités
  - 2.5 Le journal d'interventions et l'intégration HubSpot
  - 2.6 La gestion des modules et les exports
  - 2.7 L'industrialisation : infrastructure, CI/CD, supervision
- III. Missions effectuées
  - 3.1 Cadrage et recueil de besoins
  - 3.2 Développement et livraison continue
  - 3.3 Accompagnement utilisateur et formation interne
  - 3.4 Maintien en condition opérationnelle
  - 3.5 Compétences mobilisées et acquises
- Conclusion
- Annexes
- Bibliographie

---

## Glossaire et acronymes

| Sigle / terme | Définition |
|---|---|
| **ADF** | Action De Formation — unité organisationnelle d'une session de formation dans Dendreo |
| **CRM** | Customer Relationship Management — outil de gestion de la relation client (ici : HubSpot) |
| **LMS** | Learning Management System — plateforme de gestion de l'apprentissage (ici : Dendreo) |
| **OF** | Organisme de Formation |
| **CPF** | Compte Personnel de Formation |
| **Qualiopi** | Certification qualité obligatoire pour les organismes de formation finançables |
| **IaC** | Infrastructure as Code (ici : Terraform + Ansible) |
| **CI/CD** | Continuous Integration / Continuous Deployment |
| **SSO** | Single Sign-On — authentification unique (ici via Microsoft Entra ID / MSAL) |
| **MSAL** | Microsoft Authentication Library |
| **RGPD** | Règlement Général sur la Protection des Données |
| **Liveroom** | Classe virtuelle Dendreo, suivie via l'entité `creneaux` |
| **Sync** | Service de synchronisation périodique des données Dendreo vers la base interne |
| **GHCR** | GitHub Container Registry |
| **SOPS** | Secrets OPerationS — outil de chiffrement de fichiers de configuration |

---

## Introduction

La formation professionnelle continue est un secteur en mutation rapide. La généralisation du e-learning, accélérée par la crise sanitaire de 2020 puis consolidée par la réforme de la formation et le développement du CPF, a transformé les pratiques des organismes de formation. Si elle élargit l'accès à la montée en compétences, la formation à distance fait également apparaître un enjeu nouveau : **maintenir l'engagement des apprenants** lorsque la présence physique disparaît. Les taux d'abandon en e-learning sont structurellement plus élevés qu'en présentiel, et le suivi individuel devient indispensable pour préserver la qualité pédagogique — mais aussi pour répondre aux exigences de la certification Qualiopi et justifier les financements publics ou OPCO.

C'est précisément à ce besoin que répond le projet sur lequel j'ai travaillé pendant près de deux ans (novembre 2024 – septembre 2026) chez **Compétences et Métiers**, un organisme de formation utilisant le LMS Dendreo. À mon arrivée, le constat dressé par l'équipe pédagogique était simple : Dendreo, parfaitement adapté à la gestion administrative des actions de formation, n'offrait pas de vision transverse et actionnable de l'engagement des apprenants. Les conseillers consultaient les dossiers un par un, exportaient manuellement vers Excel pour faire des recoupements, et n'avaient aucun outil pour tracer leurs interventions — appels, mails, notes — autrement que dans HubSpot, déconnecté des données de progression.

Ma mission a consisté à concevoir, développer, déployer et faire évoluer une **plateforme web interne** capable de :
- consolider en continu les données Dendreo dans une base de données interne ;
- détecter automatiquement les apprenants en situation de décrochage ;
- offrir aux équipes pédagogiques un poste de travail unifié pour traiter ces cas ;
- réinjecter ces interventions dans HubSpot afin de préserver la cohérence avec le CRM.

Ce rapport s'articule autour de la problématique suivante :

> **Comment outiller un organisme de formation pour détecter automatiquement les décrochages en e-learning et orchestrer des interventions correctives traçables, en s'appuyant sur les données du LMS et du CRM ?**

Il se structure en trois parties. La **première partie** présente l'entreprise d'accueil, son activité et son écosystème technique tel que je l'ai trouvé à mon arrivée. La **deuxième partie** détaille les projets réalisés : architecture, fonctionnalités produites, choix techniques structurants. La **troisième partie** revient sur les missions effectuées dans une perspective réflexive — méthodes de travail, accompagnement utilisateur, compétences mobilisées et acquises. La conclusion dresse un bilan critique du travail accompli et ouvre sur les perspectives, tant pour le produit que pour mon projet professionnel.

---

## I. Présentation de l'entreprise

### 1.1 Compétences et Métiers : un organisme de formation professionnelle

Compétences et Métiers (ci-après « CM ») est un organisme de formation professionnelle continue. Son catalogue est volontairement large et couvre plusieurs grands domaines :
- **bureautique et outils numériques** (Pack Office, Google Workspace, outils collaboratifs) ;
- **langues** (anglais professionnel notamment) ;
- **filière énergétique et diagnostic immobilier** : formations préparant aux certifications de diagnostiqueur immobilier, **DPE** (Diagnostic de Performance Énergétique), audit énergétique ;
- **management, communication et développement personnel** ;
- diverses formations courtes métier.

L'organisme s'adresse principalement à un public adulte en évolution professionnelle, en reconversion ou en montée en compétences. Les modalités de financement mobilisées sont multiples et structurent fortement les profils des apprenants :
- **CPF** (Compte Personnel de Formation) — financement individuel par l'apprenant ;
- **AIF** (Aide Individuelle à la Formation) — dispositif France Travail (ex-Pôle Emploi) pour les demandeurs d'emploi ;
- **POEI** (Préparation Opérationnelle à l'Emploi Individuelle) — pré-recrutement, formation financée par France Travail à la demande d'un employeur ;
- **OPCO** — financement mutualisé par les opérateurs de compétences au titre du plan de développement des compétences des entreprises.

Cette diversité de financements impose des **exigences administratives et de traçabilité différenciées** : par exemple, une formation financée par AIF ou POEI fait l'objet d'un suivi d'assiduité particulièrement strict auprès de France Travail. Le pilotage de l'engagement apprenant a donc non seulement une dimension pédagogique, mais aussi une dimension de **conformité réglementaire**.

L'organisme est certifié **Qualiopi**, certification qualité rendue obligatoire depuis le 1er janvier 2022 pour tous les prestataires d'actions concourant au développement des compétences souhaitant bénéficier de fonds publics ou mutualisés. Cette certification impose notamment des obligations de **suivi de l'assiduité**, de **traçabilité** et d'**évaluation** des apprenants — autant d'éléments qui ont structuré le cahier des charges du projet.

### 1.2 Activité, marché et positionnement

Le marché de la formation professionnelle en France est mature mais fragmenté. Les organismes de formation sont en concurrence avec :
- les **plateformes pure player e-learning** (OpenClassrooms, 360Learning, Coursera…) ;
- les **grands acteurs historiques** du présentiel (Cegos, Demos, M2i…) ;
- et un nombre croissant de **petits organismes spécialisés** sur des niches métiers.

CM se positionne sur un modèle **hybride et personnalisé** : combinaison de présentiel, distanciel synchrone (classes virtuelles via Dendreo Liveroom) et distanciel asynchrone (modules e-learning). Cette personnalisation est l'un des facteurs différenciants de l'organisme, mais elle augmente la charge de suivi individuel. C'est précisément cette charge que la plateforme développée vise à rationaliser.

### 1.3 Organisation interne

L'organisation interne pertinente pour comprendre le contexte du projet comprend :
- une **équipe pédagogique** (conseillers en formation, référents pédagogiques) responsable du suivi des apprenants pendant et après l'inscription ;
- une **équipe commerciale** qui gère l'amont (devis, contractualisation), partiellement outillée via HubSpot ;
- une **équipe administrative** en charge des conventions, financements, facturation et reporting Qualiopi ;
- une **direction** qui consomme les indicateurs agrégés.

À mon arrivée, l'équipe technique interne se limitait à [préciser : un référent IT à temps partiel, externalisation partielle, etc.]. Mon poste constituait donc une création, conçue à la fois comme un investissement produit (l'outil) et comme une montée en autonomie technique de l'organisme.

### 1.4 L'écosystème numérique avant le projet

Avant le début du projet, le paysage numérique de CM reposait sur quatre piliers :

1. **Dendreo** — LMS principal, source de vérité pour les actions de formation, les apprenants, les modules e-learning et les créneaux de classe virtuelle. Dendreo expose une API REST documentée, soumise à une limite de débit (~100 requêtes / 10 secondes).
2. **HubSpot** — CRM commercial et marketing, où sont gérés les contacts, les deals et les communications (appels via intégration Ringover, mails, notes).
3. **Ringover** — solution de téléphonie cloud, intégrée à HubSpot pour la journalisation des appels et la mise à disposition d'enregistrements.
4. **Microsoft 365 / Entra ID** — annuaire, messagerie, et fournisseur d'identité pour le SSO interne.

Les principaux problèmes diagnostiqués :
- **Pas de vision transverse** : pour qualifier un décrochage, un conseiller devait croiser plusieurs vues Dendreo (progression e-learning, présence aux liveroom) et consulter HubSpot pour vérifier l'historique d'échanges.
- **Pas de traçabilité d'intervention** : les actions menées par un conseiller (appel, note, mail de relance) n'étaient pas systématiquement journalisées ; la mémoire collective dépendait des outils de chacun.
- **Reporting laborieux** : les indicateurs Qualiopi ou de direction étaient produits par exports manuels successifs, avec un risque d'erreur et un coût important.

C'est dans ce contexte que la mission a été définie.

---

## II. Projets réalisés

Cette partie présente l'ensemble du travail produit pendant la période d'alternance. La présentation suit un fil thématique plutôt que strictement chronologique, mais les principales jalons temporels sont indiqués pour donner une perspective sur l'évolution du périmètre.

### 2.1 Vue d'ensemble : la plateforme « Dendreo Progression »

La plateforme développée est une **application web interne**, accessible aux collaborateurs de CM via SSO Microsoft. Elle propose les fonctionnalités principales suivantes :

| Module | Description | Utilisateur cible |
|---|---|---|
| Liste des ADF | Vue paginée et filtrable des actions de formation actives | Tous |
| Fiche ADF | Détail d'une session : participants, modules, progression | Pédagogie |
| Fiche participant | Vue 360° d'un apprenant : modules, présences, deals HubSpot | Pédagogie |
| Gestion des inactifs | Liste priorisée des apprenants en situation de décrochage | Pédagogie, Manager |
| Journal d'interventions | Snooze, notes, mails, appels, dismiss — historique unifié | Pédagogie |
| Gestion des modules | Vue transverse, filtres, exports Excel/PDF | Pédagogie, Direction |
| Dashboard sync | Suivi technique de la synchronisation Dendreo | Admin |
| Historique d'actions | Audit des interventions humaines | Manager, Direction |

La plateforme est utilisée quotidiennement par l'équipe pédagogique. La fraîcheur des données est garantie par un service de synchronisation programmé **du lundi au vendredi à 10 h** — fenêtre choisie pour livrer aux conseillers une vue à jour en début de journée tout en évitant les heures de pointe sur l'API Dendreo. La disponibilité repose sur une infrastructure Docker auto-hébergée sur un VPS Scaleway.

**Chronologie synthétique de la mission** :

- **Novembre 2024 – avril 2025** : intégration à l'organisme, prise en main de l'écosystème (Dendreo, HubSpot, processus internes), entretiens avec les conseillers, premières missions d'outillage interne et cadrage du projet de plateforme.
- **Mai – juin 2025** : prise de contact technique avec l'API Dendreo, premier client API, conception du modèle de données, premiers commits du dépôt `DendreoProgression`.
- **Juin – juillet 2025** : ajout du frontend React, première version du dashboard ADF, intégration HubSpot v1.
- **Juillet 2025** : dockerisation, mise en place d'un service de sync conteneurisé (cron), premier déploiement production.
- **Été – automne 2025** : extension du périmètre fonctionnel (fiches détaillées, recherche, caches).
- **Hiver 2025 – début 2026** : refonte de la détection d'inactivité, ajout du module liveroom, intégration HubSpot v2 (deals, notes, appels), authentification SSO Microsoft.
- **Printemps – été 2026** : industrialisation finale — Terraform/Ansible, CI/CD GitHub Actions, supervision Netdata, refonte du module Module Management, exports Excel/PDF.
- **Septembre 2026** : clôture de l'alternance, transfert de connaissance et rédaction du présent rapport.

### 2.2 Architecture technique et choix structurants

L'architecture retenue (figure A en annexe) repose sur les briques suivantes :

```
[Navigateur React] → [Nginx] → [API FastAPI] → [PostgreSQL]
                                       ↑
                                       │
                  [Conteneur Sync (cron + Python)] → [API Dendreo / HubSpot]
```

**Choix technologiques principaux et justifications** :

- **FastAPI (Python 3.11)** comme framework backend : typage strict via Pydantic, génération automatique de la documentation OpenAPI (utile pour l'auto-test et la communication avec mon tuteur), excellentes performances asynchrones, écosystème mûr. Alternatives écartées : Django (trop monolithique pour le besoin), Flask (typage et docs moins natifs).
- **SQLAlchemy 2.x** comme ORM : modèle riche, migrations explicites, compatibilité avec PostgreSQL avancé.
- **PostgreSQL 15** comme base relationnelle : modèle de données fortement relationnel (ADF, participants, modules, créneaux, interventions), besoin d'index et de requêtes complexes.
- **Redis** comme cache mémoire pour les endpoints les plus lourds (liste des inactifs paginée notamment).
- **React 18 + Tailwind CSS + Lucide** côté frontend : vélocité de développement, design system simple à maintenir, écosystème massif.
- **Docker Compose** pour l'orchestration des services en production (Nginx, backend, sync, frontend bundlé, PostgreSQL, Redis, Netdata).
- **Microsoft Entra ID via MSAL** pour le SSO : intégration native avec l'annuaire interne, gestion des rôles par groupes Azure (Admin, Manager).

**Principes d'architecture suivis** :

- **Séparation des préoccupations** : l'API ne sait rien de Dendreo (sauf au démarrage pour des actions admin), la sync ne connaît pas le frontend, le frontend ne parle qu'à l'API.
- **Source de vérité unique** : la base PostgreSQL interne est la référence pour toutes les vues ; Dendreo n'est appelé qu'en lecture par le service de sync.
- **Idempotence** : les opérations de sync sont rejouables sans effet de bord ; les actions utilisateur (intervention) sont traçables et réversibles.
- **Garde-fous contre les écrasements** : lorsque l'utilisateur saisit manuellement une donnée (liaison ADF↔deal HubSpot par exemple), un drapeau `is_manual_link` empêche la prochaine sync d'écraser la valeur.

### 2.3 Le moteur de synchronisation Dendreo

Le service de synchronisation est la pierre angulaire technique du projet. Il est responsable de maintenir la base PostgreSQL alignée sur Dendreo avec une fraîcheur de l'ordre de l'heure.

**Architecture** :
- Conteneur Docker dédié (`sync`) embarquant Python, le code de l'application et `cron`.
- Tâches `cron` déclenchant un script `sync_wrapper_prod.sh` qui appelle le moteur Python.
- Périodicité retenue : **du lundi au vendredi à 10 h** (heure de Paris, calée sur le fuseau du conteneur). Ce créneau a été choisi avec l'équipe pédagogique : la sync est terminée avant la « revue des inactifs » que les conseillers font en milieu de matinée, et le week-end est volontairement exclu pour ne pas brûler du quota API sans valeur métier.
- Au démarrage du conteneur, un script d'entrypoint génère un fichier `cron_env.sh` qui exporte les variables d'environnement nécessaires. Sans cela, les jobs `cron` n'héritent pas des variables Docker — un piège classique que j'ai dû identifier et corriger.

**Contraintes traitées** :

1. **Rate limit Dendreo** (~100 req/10 s). Le moteur respecte une limite configurée volontairement plus basse (90 req/10 s, paramètre `DENDREO_RATE_LIMIT_REQUESTS`) afin de laisser une marge pour les éventuels appels manuels ou pour d'autres consommateurs partageant le quota. Cette décision a été prise après un incident où un script ad-hoc avait saturé l'API en pleine sync.
2. **Pagination** : la majorité des endpoints Dendreo paginent les résultats. Le moteur de sync gère la pagination de manière transparente.
3. **Reprise sur erreur** : une sync est composée de plusieurs phases ; en cas d'échec d'une phase, les suivantes peuvent continuer ou s'arrêter selon la criticité (`fail-fast` configurable).
4. **Détachement de sessions SQLAlchemy** : un piège que j'ai rencontré tôt et qui mérite d'être documenté. La fonction utilitaire `get_db_session()` ferme la session à la sortie. Un objet créé dans une session devient « détaché » lorsqu'on tente de le modifier dans une nouvelle session — les modifications sont silencieusement perdues. La règle adoptée : **toujours stocker l'identifiant et refetcher l'objet dans la nouvelle session** (`db.query(Model).get(id)`).
5. **Échecs silencieux dans les checks shell** : un bug subtil identifié dans `sync_wrapper_prod.sh` — un `if python3 -c "..."` retourne un code de sortie non nul aussi bien pour une condition fausse que pour un crash Python (import error, configuration absente). J'ai introduit des codes de sortie distincts (0 = vrai, 2 = faux, 1 = crash) afin de différencier le comportement attendu de l'incident.

**Tâches synchronisées** :
- Liste et statuts des ADF (filtrage des ADF archivés statuts 5/6/7)
- Participants et leurs inscriptions
- Modules et leur progression individuelle
- Créneaux de classe virtuelle (`creneaux`) et présences (`creneau_participants`)
- Données HubSpot associées (deals liés aux apprenants)

**Mesure et observabilité** :
- Une page « Sync Dashboard » expose l'historique des syncs : durée, nombre d'objets traités, erreurs.
- Les compteurs d'appels API sont calés sur le calendrier (Dendreo facture par tranches calendaires).
- Les logs de chaque sync sont archivés et téléchargeables individuellement, avec rotation automatique.

### 2.4 Le module de détection des inactivités

C'est le cœur métier de la plateforme.

**Définition de l'inactivité** :

Un apprenant est considéré comme inactif lorsque la date `max(dernière activité e-learning, dernier créneau liveroom avec présence='1')` dépasse un seuil paramétrable. Le détail :

- `dernière activité e-learning` provient des modules tracés par Dendreo (last access par module, agrégé).
- `dernier créneau liveroom` provient de `creneau_participants` filtré sur `presence='1'` — seule une présence confirmée compte, pas une simple inscription.
- Le calcul intègre le **mode de formation** : un apprenant inscrit à une formation purement présentielle n'est pas surveillé sur l'inactivité e-learning.

Cette définition n'a pas été figée d'emblée. Elle a évolué au moins quatre fois sur les douze mois, à la suite de retours utilisateurs :
1. Version 1 : uniquement la dernière activité e-learning (trop strict — exclut les apprenants assidus en liveroom).
2. Version 2 : ajout de la composante liveroom (mais comptait toute inscription comme activité — biais).
3. Version 3 : restriction aux `presence='1'` confirmées.
4. Version 4 : suppression du tier intermédiaire `at_risk` jugé bruyant par les conseillers, après débrief en réunion.

**Implémentation technique** :

- Endpoint REST paginé `/api/inactive/...`, fortement instrumenté par Redis pour absorber la charge.
- Tri par dernière activité, ajout récent, alphabétique.
- Filtres par tier, par mode de formation, par module, par conseiller référent.
- Déduplication par titre de module (un même module peut exister sur plusieurs ADF — il était pollué d'apparaître plusieurs fois).
- Page React `InactiveManagement.js` avec pagination côté serveur, vues sauvegardées par utilisateur.

**Interaction avec l'utilisateur** :

L'apprenant inactif est l'**unité d'action** centrale du conseiller pédagogique. Pour chaque ligne, le conseiller peut déclencher une action via le panneau d'intervention (cf. section suivante).

### 2.5 Le journal d'interventions et l'intégration HubSpot

L'objectif de ce module est de **rendre traçable et collaboratif** le suivi des relances et accompagnements personnalisés.

**Actions disponibles depuis la fiche d'un apprenant inactif** :

| Action | Effet |
|---|---|
| Snooze | Met en sommeil l'alerte pour une durée définie |
| Note | Saisie d'une note interne, optionnellement poussée dans HubSpot |
| Mail | Envoi (ou journalisation) d'un mail de relance |
| Appel | Journalisation d'un appel ; lecture des enregistrements Ringover via proxy audio |
| Dismiss | Retrait définitif de l'apprenant de la liste d'alertes |

**Timeline unifiée** :

La timeline d'un apprenant est l'élément le plus apprécié des utilisateurs car elle agrège **sans double saisie** :
- les notes internes saisies depuis la plateforme ;
- les notes natives Dendreo ;
- les notes HubSpot (récupérées via l'API HubSpot) ;
- les appels HubSpot (récupérés via l'API des associations HubSpot) ;
- les actions automatiques journalisées (snooze, dismiss…).

Des filtres par type et une recherche permettent de naviguer rapidement. Les notes trop longues sont tronquées avec un « voir plus » pour préserver la lisibilité.

**Intégration HubSpot — détails techniques** :

- Récupération des deals d'un apprenant via les **associations contact → deal**, puis lecture batch des deals (titre, prix EUR).
- Une fonctionnalité majeure ajoutée en cours d'année est la **liaison manuelle ADF ↔ deal** : un conseiller peut, depuis la fiche participant, sélectionner le deal HubSpot correspondant à une inscription. La liaison est marquée par `is_manual_link=True` sur le modèle `ParticipantHubspotData`, ce qui empêche la sync automatique de l'écraser. Deux points de garde ont été instrumentés dans `dendreo_sync.py` pour matérialiser cette règle.
- Lors du push d'une note vers HubSpot, l'attribution au propriétaire (owner) est effectuée. Une difficulté résiduelle : la lecture des owners HubSpot exige le scope `crm.objects.owners.read` sur l'app privée, encore en attente d'activation côté administrateur HubSpot. Le code est prêt et factorisé, l'activation côté HubSpot débloquera la fonctionnalité immédiatement.
- Progression poussée vers une propriété personnalisée du deal HubSpot, encodée en fraction (0 à 1) avec décimale au point pour conformité avec le format attendu. Conformité avec une précision d'une décimale en pourcentage (donc trois décimales en fraction).

### 2.6 La gestion des modules et les exports

La page **Module Management** offre une vision transverse de tous les modules e-learning actifs, indépendamment de l'ADF dans laquelle ils sont rattachés.

Fonctionnalités principales :
- Filtre unique par module (déduplication par titre).
- Filtre par échéance (mode `deadline manager`) avec mise en avant des dépassements.
- Compteur d'apprenants concernés.
- Exports **Excel** (via la librairie `xlsx`) et **PDF** avec sélection de colonnes.
- Vues sauvegardées propres à la page (la portée des vues a été scopée par page pour éviter la confusion avec celles de la liste ADF).

L'export Excel est une fonctionnalité fréquemment demandée par la direction pour ses reporting Qualiopi ou ses analyses ponctuelles. Sa qualité est un indicateur direct de la confiance des utilisateurs dans la plateforme.

### 2.7 L'industrialisation : infrastructure, CI/CD, supervision

#### 2.7.1 Infrastructure as Code

Le VPS de production est hébergé chez **Scaleway** (région fr-par-1). Le provisioning est entièrement automatisé :

- **Terraform** crée le serveur, le bloc IP, les règles de sécurité et les enregistrements DNS.
- **Ansible** configure le serveur : utilisateurs, Docker, fail2ban, mises à jour de sécurité, certificats SSL Let's Encrypt, déploiement de Netdata, configuration nginx.

Le choix VPS plutôt qu'une plateforme managée a été motivé par :
- la maîtrise des coûts (un VPS unique vs. plusieurs services managés) ;
- la maîtrise des données (donnée apprenant, contexte RGPD) ;
- la valeur formative de l'exercice côté infrastructure.

Les compromis assumés sont la responsabilité de l'exploitation et un effort initial plus élevé. Ce dernier est largement amorti par la reproductibilité de la configuration (un nouveau serveur identique peut être recréé en moins d'une heure).

#### 2.7.2 Pipeline CI/CD

Le pipeline GitHub Actions (figure B en annexe) se déclenche sur chaque push :

1. **Build des trois images Docker** (backend, sync, frontend) en parallèle, push vers GHCR.
2. **Métadonnées** : tags issus de la branche, du SHA, des tags Git sémantiques.
3. **Cache GHA** pour accélérer les rebuilds.
4. **Sur `main` uniquement** : déploiement automatique
   - Synchronisation du `docker-compose.prod.yml` vers le VPS via SCP.
   - Connexion SSH sur le VPS, `docker compose pull`, attente de la fin d'une sync éventuellement en cours (timeout 30 minutes), redéploiement, purge des images dangling.

Deux décisions tardives importantes ont contribué à la robustesse :
- **Attente de fin de sync avant redéploiement** : sans cela, une sync en cours était brutalement interrompue, laissant la base dans un état partiel.
- **Suppression de Portainer** au profit de scripts explicites : Portainer apportait peu de valeur ajoutée et alourdissait la stack.

#### 2.7.3 Supervision

La supervision repose sur deux niveaux :

1. **Netdata**, déployé via Ansible, exposé sur un sous-domaine protégé par basic auth. Configuration d'une alerte de **mémoire faible** (`ram_available`), avec un correctif notable : la version initiale utilisait une formule `calc` qui produisait des faux positifs ; j'ai migré l'alerte vers une formule `lookup` plus stable.
2. **Healthchecks Docker** : leur portée a été limitée à la **liveness** pour le conteneur sync (le conteneur est-il vivant ?). Les contrôles métier (« est-ce qu'une sync a réussi récemment ? ») sont délégués au **dashboard de sync** côté application, plus pertinent et déjà visible par l'équipe technique.

Cette distinction entre liveness conteneur et health métier est un apprentissage que je retiens : tenter de tout faire faire à Docker conduit à des healthchecks fragiles et peu lisibles.

#### 2.7.4 Sécurité et gestion des secrets

- Tous les secrets (clés API Dendreo, HubSpot, MSAL, mots de passe DB) sont chiffrés via **SOPS + age**. Les fichiers chiffrés sont commités dans le dépôt ; seules les clés privées autorisées peuvent les déchiffrer.
- Le serveur n'expose que les ports nécessaires (443 web, 22 SSH).
- L'application repose sur le SSO Microsoft : aucun mot de passe n'est stocké côté plateforme.
- Les rôles sont matérialisés par des **groupes Azure** : l'appartenance au groupe `AZURE_AD_MANAGER_GROUP_ID` donne accès au panneau d'interventions.

---

## III. Missions effectuées

Cette partie décrit non plus le **produit livré**, mais les **missions** que j'ai effectivement accomplies au quotidien, et les compétences que ces missions ont mobilisées et développées.

### 3.1 Cadrage et recueil de besoins

Au commencement de la mission, le besoin était formulé en termes très généraux : « un tableau de bord pour suivre la progression ». Une des premières missions a donc consisté à **transformer cette demande en spécifications opérationnelles**.

Activités menées :
- Entretiens individuels avec [trois à cinq] conseillers pédagogiques, dans une posture d'écoute active, pour comprendre leur workflow réel et les frictions.
- Observation directe de l'utilisation de Dendreo et HubSpot par les utilisateurs.
- Maquettage rapide (croquis papier, puis maquettes basse fidélité dans le code) pour faire converger les attentes.
- Itérations courtes : chaque livraison déclenchait un retour utilisateur, parfois remettant en cause des hypothèses initiales.

Exemple concret : la **définition de l'inactivité** a été itérée quatre fois. Sans ces aller-retours réguliers avec les conseillers, j'aurais construit une fonctionnalité techniquement correcte mais inutile dans le quotidien métier.

### 3.2 Développement et livraison continue

La majeure partie de mon temps a été consacrée au **développement** : conception détaillée, implémentation, revue, déploiement.

Pratiques adoptées :
- **Branches feature** par fonctionnalité, **pull requests** systématiques sur le dépôt GitHub Competences-et-Metiers.
- Convention de commit explicite : un commit décrit une intention claire (ex. « Hide archived ADFs (status not in 5/6/7) from course and participant listings »).
- Revue de code à mon initiative, parfois en sollicitant des outils externes (revue par agent, paire technique).
- Déploiement continu sur la branche `main` : chaque merge déclenche un build et un déploiement automatique en production.
- Conventions de nommage cohérentes côté backend (snake_case) et frontend (camelCase).

Cette discipline n'a pas été un choix esthétique : avec un déploiement automatique sur `main`, l'absence de filet de sécurité (peu de tests automatisés) impose une **revue scrupuleuse** et une **réversibilité** par PR. Pendant la mission, le nombre de retours en arrière en production a pu être maintenu à un niveau très bas malgré une cadence de livraison soutenue.

### 3.3 Accompagnement utilisateur et formation interne

Une plateforme inutilisée est une plateforme inutile. Une partie significative de mon temps a été consacrée à :
- **Démonstrations** régulières des nouvelles fonctionnalités lors des points d'équipe.
- **Rédaction de petites notes d'utilisation** pour les fonctionnalités les plus subtiles (ex. : différence entre snooze et dismiss, fonctionnement du tier d'inactivité).
- **Réponse aux questions utilisateur** : très fréquentes en début de mission, espacées au fil du temps à mesure que les habitudes se prenaient.
- **Recueil de bugs et de demandes** : j'ai instauré un canal de remontée simple pour collecter les irritants et les prioriser.

Cette dimension « produit » de la mission a été particulièrement formatrice. Elle m'a appris à :
- distinguer une demande superficielle d'un besoin sous-jacent ;
- arbitrer entre la dette technique et l'ajout de fonctionnalités ;
- accepter de retirer une fonctionnalité (le tier `at_risk`) lorsqu'elle nuit à l'utilisabilité.

### 3.4 Maintien en condition opérationnelle

Le maintien en condition opérationnelle (MCO) a représenté une part variable mais constante de la charge. Activités principales :
- **Surveillance** quotidienne du dashboard de sync et des alertes Netdata.
- **Réaction aux incidents** : changements d'API Dendreo, mises à jour HubSpot, certificats SSL à renouveler, espace disque à libérer.
- **Sauvegardes** : configuration et vérification périodique de la restauration.
- **Mises à jour de sécurité** sur le VPS, sur les dépendances Python (`pip-audit`) et JavaScript (`npm audit`).

Un incident marquant : un changement non documenté de la pagination Dendreo a fait sauter une boucle pendant une nuit. La sync a été restaurée en moins d'une heure le lendemain matin grâce à la lisibilité du log et à la séparation phase par phase. L'enseignement retenu : un code de production se conçoit comme **un dispositif de diagnostic**, pas seulement comme une logique fonctionnelle.

### 3.5 Compétences mobilisées et acquises

Cette section regroupe les compétences techniques et transverses que la mission a permis de consolider ou d'acquérir. Elle peut servir de support à l'auto-évaluation et au référentiel école [adapter selon le référentiel EPITECH : compétences AC, Apprentissages Critiques].

#### Compétences techniques

| Domaine | Compétences mobilisées | Preuves |
|---|---|---|
| Architecture logicielle | Conception d'une architecture distribuée (API/sync/front), choix de patterns adaptés | Section 2.2 ; figure A |
| Back-end | FastAPI, SQLAlchemy avancé, gestion de sessions, performance d'API | Section 2.3 ; pattern « refetch par id » |
| Front-end | React, hooks, état asynchrone, design system Tailwind | Sections 2.4–2.6 |
| Base de données | Modélisation relationnelle, indexation, requêtes complexes | Annexe B (ERD) |
| Intégration | Consommation d'API tierces, gestion du rate limit, idempotence | Section 2.3 |
| DevOps | Docker, Docker Compose, IaC (Terraform/Ansible), CI/CD GitHub Actions | Section 2.7 |
| Observabilité | Netdata, logs structurés, dashboard métier de sync | Section 2.7.3 |
| Sécurité | SSO MSAL, gestion de rôles, chiffrement de secrets (SOPS), durcissement VPS | Section 2.7.4 |
| Qualité | Convention de commit, PR, revue de code, déploiement progressif | Section 3.2 |

#### Compétences transverses

| Compétence | Illustration |
|---|---|
| Recueil de besoins | Entretiens avec les conseillers pédagogiques, itération de la définition d'inactivité |
| Communication | Démonstrations régulières, notes d'utilisation, vulgarisation auprès de profils non techniques |
| Arbitrage produit | Retrait du tier `at_risk`, suppression de Portainer, priorisation continue |
| Gestion d'incident | Diagnostic et correction de l'incident de pagination Dendreo |
| Autonomie | Cadrage initial très ouvert transformé en feuille de route opérationnelle |
| Veille | Suivi de l'évolution des API Dendreo et HubSpot, choix technologiques motivés |

---

## Conclusion

Au terme de cette alternance, je peux apporter une réponse étayée à la problématique posée en introduction. **Oui**, il est possible d'outiller un organisme de formation pour détecter les décrochages e-learning et orchestrer des interventions correctives, en s'appuyant sur les données du LMS et du CRM — mais cela suppose plusieurs conditions, que l'expérience de cette mission permet d'expliciter.

Premièrement, il faut **renoncer à considérer le LMS comme la seule source de vérité**. Dendreo, comme tout LMS, est conçu pour la gestion administrative d'actions de formation, non pour le pilotage transversal de l'engagement. Une **couche de consolidation interne** est nécessaire — c'est le rôle du moteur de synchronisation et de la base PostgreSQL interne.

Deuxièmement, il faut **définir l'inactivité de manière pragmatique et itérative**, en associant les utilisateurs métier. La définition technique d'un décrochage n'a pas de sens si elle ne correspond pas à la réalité de l'accompagnement pédagogique. Les quatre itérations de notre algorithme d'inactivité en sont la preuve.

Troisièmement, il faut **fermer la boucle** : détecter ne suffit pas, encore faut-il pouvoir agir et tracer l'action. Le journal d'interventions et la timeline unifiée HubSpot ↔ plateforme constituent ce maillon.

Quatrièmement, il faut **traiter l'industrialisation comme une fonctionnalité produit**, et non comme une corvée tardive. Sans la sécurité du déploiement continu et de la supervision, l'itération rapide aurait été impossible — et la plateforme aurait probablement été abandonnée.

**Limites assumées**.
Plusieurs angles morts subsistent et méritent d'être nommés. Le périmètre de tests automatisés reste limité ; la confiance dans le code repose surtout sur la lisibilité du diff et la revue. La dépendance à l'API Dendreo est forte : un changement contractuel peut paralyser la plateforme — un mécanisme de bascule en mode dégradé pourrait être envisagé. Enfin, certains aspects du RGPD (procédure de purge des données apprenant, gestion fine des droits d'accès) gagneraient à être renforcés avant un éventuel passage à l'échelle.

**Perspectives produit**.
Plusieurs pistes sont déjà identifiées pour la suite : push de la progression vers des propriétés HubSpot avancées (déjà partiellement en place), notifications proactives par mail ou Slack au franchissement de seuils, ouverture à un usage multi-organisme.

**Bilan personnel**.
Au plan technique, cette alternance m'a permis de pratiquer en conditions réelles l'ensemble de la chaîne de conception et d'industrialisation d'une application web métier, depuis le recueil de besoins jusqu'à la supervision en production. Trois apprentissages me semblent particulièrement structurants :

1. **La simplicité est une discipline**. Les décisions les plus utiles ont souvent été des suppressions (Portainer, tier `at_risk`, dépendances inutiles), pas des ajouts.
2. **Comprendre le métier précède le code**. Les meilleures sessions de développement ont été précédées d'une discussion utilisateur ; les pires ont été initiées sur la base d'hypothèses non vérifiées.
3. **Itérer en production avec un filet de sécurité**. Un déploiement automatique sans PR, sans logs structurés et sans supervision est imprudent ; un déploiement avec tout cela est libérateur.

Au plan personnel, cette expérience confirme mon projet professionnel : exercer un métier d'**ingénieur logiciel à fort enjeu produit**, en évoluant sur l'axe architecture/conception sans renoncer à la dimension exploitation.

---

## Annexes

> *Insérer les figures et documents en pleine page après la conclusion.*
> **TODO — figures à produire avant remise** : Annexe A (schéma archi), Annexe B (ERD), Annexe C (pipeline CI/CD), Annexe D (captures d'écran). Prévoir une demi-journée dédiée. Outils suggérés : draw.io / excalidraw pour les schémas, pgAdmin export pour l'ERD, captures plein écran navigateur pour les pages.

**Annexe A — Schéma d'architecture détaillé de la plateforme**
> Schéma système : navigateur, nginx, FastAPI, PostgreSQL, Redis, sync, intégrations Dendreo et HubSpot. Mentionner les ports, les flux d'authentification, et la séparation prod/dev.

**Annexe B — Modèle de données (ERD)**
> Entités principales : `Course/ADF`, `Participant`, `Module`, `ModuleProgression`, `Creneau`, `CreneauParticipant`, `Intervention`, `Note`, `ParticipantHubspotData`. Préciser les clés et les contraintes notables (ex. `is_manual_link`).

**Annexe C — Pipeline CI/CD**
> Diagramme du workflow GitHub Actions : build matrix, push GHCR, scp du compose, ssh deploy, attente de la sync, purge dangling.

**Annexe D — Captures d'écran**
> Page de connexion SSO, ADF List, fiche participant, gestion des inactifs avec panel d'interventions, dashboard de sync, page d'historique d'actions.

**Annexe E — Extraits de code commentés**
> 1. Extrait du wrapper de sync illustrant la gestion des codes de sortie distincts ;
> 2. Le pattern « store id, refetch in new session » pour SQLAlchemy ;
> 3. La logique de garde `is_manual_link` dans `dendreo_sync.py`.

**Annexe F — Extrait Terraform et Ansible**
> Exemples illustratifs : ressource serveur Scaleway, rôle Ansible pour Netdata.

**Annexe G — Matrice compétences école / réalisations**
> Tableau croisé : pour chaque compétence du référentiel de [Nom de l'école], liste des réalisations couvrant cette compétence et page de référence dans le rapport.

---

## Bibliographie

> *Référencer les sources réellement consultées. Modèle indicatif ci-dessous, à compléter et nettoyer.*

### Documentation officielle

- Dendreo, *Documentation API*, consulté entre mai 2025 et mai 2026. [URL à compléter]
- HubSpot Developer, *CRM API Reference — Contacts, Deals, Notes, Calls, Associations*. https://developers.hubspot.com/docs/api
- FastAPI, *Documentation officielle*. https://fastapi.tiangolo.com
- SQLAlchemy, *Documentation 2.x*. https://docs.sqlalchemy.org
- React, *Documentation officielle*. https://react.dev
- Tailwind CSS, *Documentation officielle*. https://tailwindcss.com/docs
- Terraform, *Provider Scaleway*. https://registry.terraform.io/providers/scaleway/scaleway
- Ansible, *Documentation officielle*. https://docs.ansible.com
- Netdata, *Documentation officielle*. https://learn.netdata.cloud
- Microsoft, *MSAL.js — Documentation*. https://learn.microsoft.com/azure/active-directory/develop/msal-overview
- Mozilla SOPS, *Documentation*. https://github.com/getsops/sops

### Articles et ressources techniques

- Martin Fowler, « Idempotent Receiver », *Enterprise Integration Patterns*. https://martinfowler.com
- Mike Bayer, « Asynchronous I/O with SQLAlchemy », blog technique SQLAlchemy.
- Articles consultés sur la gestion du rate limit et les patterns de synchronisation incrémentale.

### Cadre réglementaire et sectoriel

- France compétences, *Référentiel national qualité Qualiopi*.
- CNIL, *Guide RGPD*, sections relatives aux outils de suivi des apprenants.

### Ouvrages

- [Ajouter les ouvrages méthodologiques effectivement lus, par exemple Martin Kleppmann, *Designing Data-Intensive Applications*, ou Eric Evans, *Domain-Driven Design*, si pertinents.]

---

*Fin du rapport — version brouillon. Avant remise : vérifier orthographe, typographie française (espaces insécables, guillemets « »), pagination, numérotation des figures, table des matières automatique, mise en page Times New Roman 12 / interligne 1,5 / justifié.*
