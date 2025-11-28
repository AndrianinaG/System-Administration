# QUOTA REPORT SCRIPT

Ce dépôt contient un script Bash permettant de configurer les quotas utilisateurs sur deux partitions, de surveiller leur utilisation et d'envoyer des alertes lorsque les limites sont atteintes.

## Fonctionnalités

* Configuration automatique des quotas utilisateur sur deux partitions (`/HOME_TEST` et `/data`)
* Activation des quotas dans `/etc/fstab` si nécessaire
* Génération de rapports avec `repquota`
* Alerte automatique aux utilisateurs si leur quota est atteint
* Enregistrement d'un message dans `/var/mail/<user>`
* Ajout d'une entrée dans `/etc/crontab` pour surveiller les dépassements
* Planification hebdomadaire d'un rapport quota (chaque lundi à 09h00)

---

## Arborescence du script

```
QUOTA_REPORT.sh   → Script principal
README.md         → Documentation du projet
```

---

## Description du script

Le script effectue plusieurs étapes :

### 1. Configuration des quotas

* Exécute `quotacheck` sur les partitions
* Active les quotas (`quotaon`)
* Initialise les soft et hard limits pour chaque utilisateur utilisant `/bin/bash`

### 2. Mise à jour de /etc/fstab

Ajoute automatiquement les entrées nécessaires pour activer les quotas :

```
/home_partition   /HOME_TEST   ext4   defaults,usrquota   0   2
/data_partition   /data        ext4   defaults,usrquota   0   2
```

### 3. Analyse des rapports quota (repquota)

* Extraction des valeurs utilisées
* Comparaison avec les limites fixées
* Envoi d’un message d'avertissement ou d'information aux utilisateurs

### 4. Planification CRON

Le script s’ajoute au crontab système :

```
0 9 * * 1   root   /bin/bash /chemin/QUOTA_REPORT.sh
```

---

## Installation

1. Cloner le dépôt :

```
git clone <URL_DU_DEPOT>
```

2. Rendre le script exécutable :

```
chmod +x QUOTA_REPORT.sh
```

3. Lancer une première fois en root :

```
sudo ./QUOTA_REPORT.sh
```

---

## Pré-requis

* Linux (Ubuntu, Debian ou équivalent)
* Paquet : `quota`, `quotatool`
* Accès root

Installation des paquets :

```
sudo apt install quota quotatool
```

---

## Notes importantes

* Le script écrit directement dans `/etc/fstab` et `/etc/crontab` : vérifiez toujours le contenu avant redémarrage.
* Le script utilise `/var/mail/<user>` pour les notifications.
* Le script doit être exécuté en root.

---

## Auteur

Projet réalisé par Andrianina Geoffroy.

---

## Licence

Ce projet est sous licence libre MIT.
