# TeamSpeak 6 Server Docker for Unraid

A Docker container for running TeamSpeak 6 Server (Beta) optimized for Unraid. This container is based on the ich777/debian-baseimage and provides an easy way to deploy a TeamSpeak 6 server with persistent data storage.

## Key Changes from TeamSpeak 3

- **New binary**: Uses `tsserver` instead of `ts3server`
- **YAML configuration**: Uses `tsserver.yaml` instead of `ts3server.ini`
- **Updated environment variables**: Uses `TSSERVER_` prefix instead of `TS3_`
- **New ports**: HTTP Query interface on port 10080 (instead of raw query on 10011)
- **Beta licensing**: Includes a 32-slot preview license valid for 2 months

## Unraid Template

Use these settings in your Unraid Docker template:

**Repository:** `popplej/teamspeak6-server:latest`

**Network Type:** `Bridge`

### Port Mappings:
- **Container Port:** `9987/udp` → **Host Port:** `9987` (Voice Port)
- **Container Port:** `30033/tcp` → **Host Port:** `30033` (File Transfer Port)  
- **Container Port:** `10080/tcp` → **Host Port:** `10080` (HTTP Query Port - Optional)

### Volume Mappings:
- **Container Path:** `/teamspeak` → **Host Path:** `/mnt/user/appdata/teamspeak6`

### Environment Variables:
- **TSSERVER_LICENSE_ACCEPTED:** `accept` (Required)
- **UID:** `99` (Unraid default)
- **GID:** `100` (Unraid default)
- **UMASK:** `000`
- **DATA_PERM:** `770`

## Docker Run Command (for manual setup)

```bash
docker run -d \
  --name TeamSpeak6-Server \
  -p 9987:9987/udp \
  -p 30033:30033 \
  -p 10080:10080 \
  -e TSSERVER_LICENSE_ACCEPTED=accept \
  -e UID=99 \
  -e GID=100 \
  -v /mnt/user/appdata/teamspeak6:/teamspeak \
  popplej/teamspeak6-server:latest
```

## Environment Variables

| Variable | Default | Description |
|----------|---------|-------------|
| `TSSERVER_LICENSE_ACCEPTED` | (empty) | **Required:** Must be set to `accept` to accept the license agreement |
| `EXTRA_START_PARAMS` | (empty) | Additional parameters to pass to the tsserver binary |
| `UID` | `99` | User ID for the teamspeak user (use 99 for Unraid) |
| `GID` | `100` | Group ID for the teamspeak user (use 100 for Unraid) |
| `UMASK` | `000` | umask for file creation |
| `DATA_PERM` | `770` | Permissions for data directory |

## Exposed Ports

| Port | Protocol | Description |
|------|----------|-------------|
| 9987 | UDP | Voice communication |
| 30033 | TCP | File transfer |
| 10080 | TCP | HTTP Query interface (optional) |

## Data Persistence

The container stores all TeamSpeak 6 data in `/teamspeak` directory including:
- Server database (`tsserver.sqlitedb`)
- Configuration file (`tsserver.yaml`)
- License file (`licensekey.dat`)
- Log files (`logs/`)
- File transfer storage (`files/`)

## First Run

On first run, the container will:
1. Download the latest TeamSpeak 6 server files
2. Create a default `tsserver.yaml` configuration
3. Display the server admin token in the logs (check your Unraid Docker logs)

**Important:** Make sure to accept the license by setting `TSSERVER_LICENSE_ACCEPTED=accept`

## Configuration

The server uses a YAML configuration file (`tsserver.yaml`) instead of the INI format used by TeamSpeak 3. The container automatically creates a default configuration if none exists.

You can customize the configuration by:
1. Editing the generated `tsserver.yaml` file in your appdata folder
2. Using environment variables
3. Passing command-line arguments via `EXTRA_START_PARAMS`

## Update Notice

The container will check on every start/restart if there is a newer version of TeamSpeak 6 available and install it automatically, preserving your data and configuration.

## Important Notes

- **Beta Software**: TeamSpeak 6 is currently in beta. Some features may be unstable.
- **License Compatibility**: TeamSpeak 3 licenses are NOT compatible with TeamSpeak 6.
- **Preview License**: The server includes a temporary 32-slot preview license valid for 2 months.
- **Migration**: There is currently no migration path from TeamSpeak 3 to TeamSpeak 6.

## Support

For issues specific to TeamSpeak 6 Server, please refer to:
- [TeamSpeak 6 Community Forum](https://community.teamspeak.com/c/teamspeak-6-server/45)
- [GitHub Issues](https://github.com/teamspeak/teamspeak6-server/issues)

For Unraid-specific support:
- [Unraid Community Forums](https://forums.unraid.net/)

This Docker container was optimized for Unraid. If you don't use Unraid, you should definitely try it!