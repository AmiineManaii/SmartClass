# SmartClass — Guide de Développement Local : Enregistrement Vidéo & IA Studio

Ce guide décrit l'architecture complète, la configuration locale et la procédure de test de la chaîne d'enregistrement de cours et d'apprentissage par IA sur SmartClass.

---

## 1. Vue d'Ensemble de l'Architecture Locale

```text
Flutter Web / Android / iOS (WebRTC : Caméra + Micro + Partage d'écran)
                      |
                      v
      LiveKit Server (smartclass-livekit :7880)
                      |
                      +---> Redis (smartclass-redis :6379)
                      |
                      v
      LiveKit Egress (smartclass-egress)
                      |
                      v
     Volume Partagé Local (C:/SmartClassStorage)
                      |
                      +--> lecture.mp4 (H.264 + AAC réel)
                      |
                      v
       FFmpeg / FFprobe (Extraction Audio & Frames)
                      |
                      +--> lecture_16k.wav
                      |
                      v
     SmartClass ASR (smartclass-asr / Faster-Whisper :8000)
                      |
                      +--> Transcription réelle avec horodatages précis
                      |
                      v
       Pipeline IA & Modèles Locaux (Ollama :11434)
                      |
                      +--> gemma4:e4b (Vision & Pédagogie)
                      +--> Qwen3.5 (Notes structurées & Synthèse)
                      |
                      v
    Studio de Révision Enseignant & Espace Replay Étudiant
```

---

## 2. Prérequis Techniques sur le Poste Développeur

- **Système d'exploitation** : Windows 11 avec WSL2 et Docker Desktop.
- **Ressources matérielles recommandées** :
  - Processeur : Intel Core i5 (12e génération ou supérieure).
  - RAM : 16 Go minimum (32 Go recommandé).
  - Carte graphique : NVIDIA GeForce RTX avec CUDA (ex: RTX 4060 8 Go).
- **Outils installés** :
  - Docker Desktop avec moteur WSL2 actif.
  - Ollama configuré pour écouter sur `0.0.0.0:11434` (`OLLAMA_HOST=0.0.0.0:11434`).
  - Flutter SDK 3.x.
  - Node.js 20+ & npm.

---

## 3. Services Docker Compose

Le fichier `Backend/docker-compose.yml` orchestre tous les conteneurs requis :

| Conteneur | Service | Port | Description |
| :--- | :--- | :--- | :--- |
| `smartclass-db` | PostgreSQL 17 + pgvector | 5432 | Base relationnelle et embeddings vectoriels |
| `smartclass-redis` | Redis 7 Alpine | 6379 | Bus d'événements et dispatch LiveKit Egress |
| `smartclass-livekit` | LiveKit Server | 7880, 7881, 7882 | Serveur SFU WebRTC temps réel |
| `smartclass-egress` | LiveKit Egress | - | Enregistreur composite serveur (Headless Chrome + GStreamer) |
| `smartclass-asr` | Faster-Whisper | 8000 | Moteur Speech-to-Text local (FR / EN / AR / Derja) |
| `smartclass-searxng` | SearXNG | 8080 | Moteur de recherche web respectueux de la vie privée |
| `smartclass-api` | SmartClass Backend API | 3000 | API Express, Prisma, Worker Multimédia |

---

## 4. Configuration des Fichiers Clés

### A. `Backend/livekit/livekit.yaml`
```yaml
port: 7880
bind_addresses:
  - "0.0.0.0"

rtc:
  tcp_port: 7881
  udp_port: 7882
  use_external_ip: false
  node_ip: 192.168.100.107

redis:
  address: redis:6379

keys:
  devkey: secretsecretsecretsecretsecretsecret32

webhook:
  api_key: devkey
  urls:
    - "http://api:3000/api/v1/videoconference/webhooks/livekit"

logging:
  level: info
```

### B. `Backend/livekit/egress.yaml`
```yaml
api_key: devkey
api_secret: secretsecretsecretsecretsecretsecret32
ws_url: ws://livekit:7880

redis:
  address: redis:6379

insecure: true
log_level: info
```

### C. Volume de Stockage Partagé
Le volume hôte `C:/SmartClassStorage` est monté sur `/var/lib/smartclass-storage` dans `smartclass-api` et `smartclass-egress`. Ainsi, tout fichier MP4 produit par Egress est immédiatement accessible par l'API sans transfert réseau.

---

## 5. Démarrage et Vérification

### 1. Démarrer les services Docker
```powershell
cd Backend
docker compose up -d
```

### 2. Vérifier l'état de santé des conteneurs
```powershell
docker ps
```
Tous les conteneurs doivent être `Up` ou `Up (healthy)`.

### 3. Tester le service ASR local
```powershell
curl http://localhost:8000/health
```
Réponse attendue :
```json
{"status":"ok","service":"smartclass-asr","model":"small"}
```

### 4. Démarrer l'application Flutter Web
```powershell
cd Frontend
flutter run -d chrome
```

---

## 6. Procédure de Test de Bout en Bout

1. **Connexion Enseignant** :
   - Se connecter avec un compte enseignant (ex: `amine.manai@smartclass.tn`).
2. **Rejoindre ou Démarrer une Séance** :
   - Accéder à la visioconférence.
   - Activer le micro et la caméra.
   - Cliquer sur le bouton **Partager l'écran** et sélectionner une fenêtre (ex: PowerPoint ou présentation PDF).
3. **Démarrer l'Enregistrement** :
   - Cliquer sur le bouton d'enregistrement (point rouge).
   - Le badge `REC` s'allume en haut à gauche et LiveKit Egress commence l'enregistrement composite sur le serveur.
4. **Parler et Présenter** :
   - Expliquer les concepts affichés sur les diapositives (en Français, Arabe ou Derja tunisienne).
5. **Arrêter l'Enregistrement** :
   - Cliquer sur le bouton d'arrêt d'enregistrement ou terminer l'appel pour tout le monde.
   - La vidéo est finalisée dans `C:/SmartClassStorage/recordings/${sessionId}/lecture.mp4`.
   - Le pipeline d'analyse IA démarre automatiquement en arrière-plan.
6. **Révision dans le Studio IA** :
   - Le studio affiche la progression en temps réel (`VALIDATION` → `AUDIO_EXTRACTION` → `TRANSCRIPTION` → `VISUAL_ANALYSIS` → `LESSON_GENERATION` → `READY_FOR_REVIEW`).
   - L'enseignant vérifie la vidéo réelle, la transcription fidèle avec horodatages réels, les chapitres, le résumé, les quiz et flashcards générés.
   - L'enseignant approuve et publie le cours pour les étudiants.

