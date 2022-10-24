# PhValheim Server

[![made-with-Docker](https://img.shields.io/badge/Made%20with-Docker-2496ed.svg)](https://www.docker.com/)
[![made-with-BASH](https://img.shields.io/badge/Made%20with-BASH-a32c29.svg)](https://www.gnu.org/software/bash/)
[![made-with-PHP](https://img.shields.io/badge/Made%20with-PHP-7a86b8.svg)](https://www.php.net/)
[![made-with-MariaDB](https://img.shields.io/badge/Made%20with-MariaDB-013545.svg)](https://mariadb.org/)
[![login-with-Steam](https://img.shields.io/badge/Login%20with-Steam-5d7e0f.svg)](https://store.steampowered.com/)
[![Open Source Love png1](https://badges.frapsoft.com/os/v1/open-source.png?v=103)](https://en.wikipedia.org/wiki/Open-source_software)

#### What is it?
PhValheim is a two-part world and client manager for Valheim (with aspirations of becoming game agnostic), it keeps server and client files in lock-step, ensuring all players have the same experience.

#### Why?
Valheim is a fantastic game and the more we play the more we want. Modding Valheim is simple to do but difficult to manage across all players. Keeping the remote server and clients in-sync are nearly impossible without something like PhValheim.  While mod managers work well (Thunderstore and Nexus Mods), they don't work in a federated manner, eventaully resulting in clients being out of sync with each other and the remote server. PhValheim's primary goal is to solve this problem.

#### What are the features of PhValheim?
- Runs in a single Docker container
- Login with Steam (SteamAPIKey is required)
- Quickly deploy unique worlds at the click of a button, with any combination of mods.
- Deploy any world with a specified Seed, or NULL will deploy a "default" Seed, provided during container deployment.
- Automatically deploys "required" mods, ensuring mandatory mods are always running.
- Manage a unique "allowlist" of users for each world.
- Global and unique world logs files for every aspect of PhValheim and its running processes.
- Update a world and all linked mods at the click of a button.
- Stores copies of recently downloaded mods for reuseability.
- Automatically backs up all world files every 30 minutes (can be pointed to disparate disks to ensure storage diversity).
- The Public web interface displays current MD5SUM of world client payload, created and last updated timestamps, active memory that the world is consuming, "PhValheim Client Download Link", and an instant "Launch!" link.
- The Admin web interface provides access to all manager features, which are completely isolated from the public interface.

#### How does it work?
As mentioned above, PhValheim Server runs in a docker container.  Out-of-the-box the container runs a few services:
 - PhValheim Engine
    - The engine is responsible for all communication and execution between the supporting services mentioned below and the game's engine.
        - Listens for engine commands (create, start, stop, update, delete)
        - Builds client payloads after world creation and world updates.
 - CRON
    - tsStoreStync
      - Syncs Thunderstore's entire Valheim Mod database every 12hrs (just the metadata)
    - worldBackup
      - Backs up all worlds every 30 minutes (default is 10 backups to keep, configurable)
    - utilizationMonitor
      - Brings real-time utilization of each world and process. Currently only provides real-time memory utilization for each world which is displayed on the public interface.
 - Supervisor
   - The process watcher and executor. Supervisor manages all PhValheim processes, including every world deployed.
 - NGINX
   - All Public and Admin interfaces are published via NGINX.
 - MariaDB
   - All stateful (minus the Valheim and Steam binaries) are stored in MariaDB

