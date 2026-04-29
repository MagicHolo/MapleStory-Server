# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

MapleStory private server emulator (HeavenMS fork, based on OdinMS). Java 7+ project using Apache MINA for networking, MySQL/MariaDB for persistence, and Rhino JavaScript for game scripting. Licensed under AGPL v3.

## Build & Run

### Build (choose one)
```bash
# NetBeans IDE: Clean and Build (preferred — uses build.xml / nbproject/)
# POSIX command line:
./posix-compile.sh
```

### Run
```bash
# Windows:
launch.bat
# POSIX:
./posix-launch.sh
# Manual (from project root):
java -Xmx2048m -Dwzpath=wz -cp .:dist:cores/* net.server.Server
```

### Database Setup
MySQL/MariaDB required. Initialize with `sql/db_database.sql`, then optionally load `sql/db_drops.sql` and `sql/db_shopupdate.sql`. Connection configured in `configuration.ini`.

### No Test Suite
There are no automated tests. Verification is manual — run the server and connect with a MapleStory client.

## Architecture

### Entry Point
`net.server.Server` — singleton that initializes the database, Apache MINA acceptors, worlds/channels, data providers, and script managers. Login server listens on port 8484; channel servers on 7575+.

### Package Layout (`src/`)

| Package | Purpose |
|---------|---------|
| `net/` | Apache MINA networking: codec, encryption (`MapleAESOFB`), session handling (`MapleServerHandler`), and the `PacketProcessor` opcode router |
| `net/opcodes/` | `RecvOpcode` (client→server) and `SendOpcode` (server→client) enums |
| `net/server/` | Core server: `Server`, `World`, `Channel`, coordinator, guild/alliance systems, worker threads |
| `net/server/handlers/login/` | Login packet handlers (auth, char creation/selection, server list) |
| `net/server/channel/handlers/` | In-game packet handlers (~100+ handlers for movement, combat, skills, inventory, etc.) |
| `client/` | `MapleCharacter` (core player entity, ~10K lines), `MapleClient` (session wrapper), skills, inventory, jobs |
| `server/` | Game systems: maps (`MapleMap`, `MapleMapFactory`), monsters, items, quests, shops, cash shop, events, timers |
| `scripting/` | Rhino JS engine integration. `AbstractPlayerInteraction` is the scripting API exposed to scripts |
| `provider/` | WZ/XML game data loading from the `wz/` directory |
| `constants/` | `ServerConstants` (feature flags, intervals, server config), `GameConstants` (game mechanics), `ItemConstants`, `ExpTable`, per-job skill ID constants |
| `tools/` | `MaplePacketCreator` (massive packet factory), `DatabaseConnection` (HikariCP pool), `FilePrinter` (logging), binary I/O helpers |

### Packet Flow
1. Client sends encrypted binary packet → `MaplePacketDecoder` decrypts (AES-OFB)
2. `MapleServerHandler.messageReceived()` extracts the 2-byte opcode
3. `PacketProcessor` maps `RecvOpcode` → `MaplePacketHandler` implementation
4. Handler parses the payload using `SeekableLittleEndianAccessor` and executes game logic
5. Responses built via `MaplePacketCreator` static methods, sent through `MapleClient.announce()`

### Scripting (`scripts/`)
JavaScript files executed by Rhino, organized by type: `npc/`, `quest/`, `event/`, `portal/`, `reactor/`, `item/`, `map/`. Scripts interact with the server through `AbstractPlayerInteraction` and its subclasses (e.g., `NPCConversationManager`, `EventManager`). Script filenames correspond to game entity IDs (e.g., `scripts/npc/9010000.js`).

### Configuration
- `configuration.ini` — server name, bind host, DB connection, Java 8 flag
- `world.ini` — number of worlds (up to 5), channels per world (2–30), flags, messages
- `constants/ServerConstants.java` — compile-time feature flags and tuning (PIC/PIN, auto-register, debug, buyback, family system, intervals)
- `constants/GameConstants.java` — game mechanics constants (goto map IDs, rates)

### Dependencies (vendored in `cores/`)
Apache MINA 2.0.19, HikariCP 2.4.13, MySQL Connector/J, SLF4J 1.7.21, JavaTuples 1.2

### Concurrency
Custom `MonitoredReentrantLock` and `MonitoredReentrantReadWriteLock` with deadlock detection (see `net/server/audit/`). `ThreadTracker` audits thread activity. `TimerManager` runs scheduled/recurring tasks.

### Database
Direct JDBC with HikariCP connection pool (`tools/DatabaseConnection`). All queries use prepared statements. Schema in `sql/db_database.sql` (~50+ tables).
