# Regiedeck Proxmox Installer

Automatische installatie van **Regiedeck** in een **Proxmox LXC-container**.

Dit script maakt een nieuwe Debian 12-container aan, installeert alle benodigde software en downloadt de laatste versie van Regiedeck vanuit GitHub.

> **Let op:** De Regiedeck-repository is momenteel privé. Tijdens de installatie wordt daarom gevraagd om een GitHub-gebruikersnaam en een Personal Access Token (PAT) met leesrechten op de repository.

---

## Vereisten

* Proxmox VE 8 of hoger
* Internetverbinding
* Een bestaande externe MySQL/MariaDB-server
* Een GitHub Personal Access Token met minimaal **Contents: Read** rechten

---

## Installeren

Voer op de Proxmox-host uit:

```bash
bash -c "$(curl -fsSL https://raw.githubusercontent.com/rorymeijer/regiedeck-install/main/proxmox-unattended-install.sh)"
```

Tijdens de installatie wordt gevraagd om:

* GitHub gebruikersnaam
* GitHub Personal Access Token
* MySQL-host
* MySQL-poort
* Databasenaam
* Databasegebruiker
* Databasewachtwoord

---

## Wat installeert het script?

Het script:

* maakt een nieuwe Debian 12 LXC-container aan;
* installeert Apache;
* installeert PHP 8.x en alle benodigde extensies;
* activeert Apache Rewrite;
* downloadt de laatste versie van Regiedeck vanaf de `main` branch;
* configureert de Apache Virtual Host;
* stelt de juiste bestandsrechten in;
* laat de webinstaller gereedstaan.

De database wordt **niet** lokaal geïnstalleerd. Er wordt gebruikgemaakt van een bestaande externe MySQL/MariaDB-server.

---

## Na de installatie

Open in de browser:

```text
http://<container-ip>/install/
```

Volg vervolgens de webinstaller en vul de gegevens van de externe database in.

Na een succesvolle installatie wordt aangeraden de installer te verwijderen:

```bash
rm -rf /var/www/regiedeck/public/install
```

---

## GitHub Token

Maak een Personal Access Token aan via:

https://github.com/settings/personal-access-tokens

Benodigde rechten:

* Repository access: **Only select repositories**
* Selecteer **Regiedeck**
* Permissions:

  * **Contents → Read-only**

---

## Ondersteunde configuratie

| Onderdeel   | Waarde                |
| ----------- | --------------------- |
| OS          | Debian 12             |
| Webserver   | Apache 2.4            |
| PHP         | 8.1+                  |
| Database    | Externe MySQL/MariaDB |
| Installatie | Proxmox LXC           |

---

## Roadmap

Geplande uitbreidingen:

* Automatische updates vanuit GitHub
* SSL-configuratie via Nginx Proxy Manager
* Ondersteuning voor Docker-installaties
* Ondersteuning voor meerdere deployment-profielen
* Back-up- en restorefunctionaliteit

---

## Licentie

Zie de licentie in de hoofdrepository van Regiedeck.

---

## Hoofdrepository

https://github.com/rorymeijer/Regiedeck
