#!/bin/bash

# TeamSpeak 6 Server Download URLs - Get latest from GitHub releases
GITHUB_API_URL="https://api.github.com/repos/teamspeak/teamspeak6-server/releases/latest"
DL_URL=""
LAT_V=""

echo "---Checking for TeamSpeak 6 release information---"
if command -v curl >/dev/null 2>&1; then
    RELEASE_INFO=$(curl -s "$GITHUB_API_URL")
    if [ $? -eq 0 ] && [ -n "$RELEASE_INFO" ]; then
        LAT_V=$(echo "$RELEASE_INFO" | jq -r '.tag_name' 2>/dev/null)
        DL_URL=$(echo "$RELEASE_INFO" | jq -r '.assets[] | select(.name | contains("linux")) | .browser_download_url' 2>/dev/null | head -1)
    fi
fi

# Fallback to manual URL construction if API fails
if [ -z "$DL_URL" ]; then
    echo "---API fetch failed, using fallback download method---"
    DL_URL="https://files.teamspeak-services.com/releases/server/6.0.0%2Bbeta5/teamspeak6-server_linux_amd64-6.0.0+beta5.tar.bz2"
    LAT_V="v6.0.0+beta5"
fi

if [ -f ${DATA_DIR}/tsserver ]; then
	CUR_V="$(${DATA_DIR}/tsserver --version 2>/dev/null | head -1 | awk '{print $NF}' || echo 'unknown')"
fi

echo "---Checking if TeamSpeak 6 is installed---"
if [ ! -f ${DATA_DIR}/tsserver ]; then
	echo "---TeamSpeak 6 not found, downloading v${LAT_V}---"
    cd ${DATA_DIR}
	if wget -q -nc --show-progress --progress=bar:force:noscroll -O tsserver.tar.bz2 "$DL_URL" ; then
		echo "---Successfully downloaded TeamSpeak 6!---"
	else
		echo "---Something went wrong, can't download TeamSpeak 6, putting server in sleep mode---"
		sleep infinity
	fi
	tar -xvjf ${DATA_DIR}/tsserver.tar.bz2
	rm ${DATA_DIR}/tsserver.tar.bz2
	
	# Find the extracted directory and move contents
	EXTRACTED_DIR=$(find ${DATA_DIR} -maxdepth 1 -type d -name "teamspeak*server*" | head -1)
	if [ -n "$EXTRACTED_DIR" ]; then
		mv ${EXTRACTED_DIR}/* ${DATA_DIR}/
		rm -rf ${EXTRACTED_DIR}
	fi
	
	# Make tsserver executable
	chmod +x ${DATA_DIR}/tsserver
	
    CUR_V="$(${DATA_DIR}/tsserver --version 2>/dev/null | head -1 | awk '{print $NF}' || echo 'unknown')"
else
	echo "---TeamSpeak 6 found---"
fi

if [ ! -z "$LAT_V" ] && [ "$LAT_V" != "unknown" ]; then
	echo "---Version Check---"
	if [ "$LAT_V" != "$CUR_V" ]; then
		echo "---Version mismatch v$CUR_V installed, installing v$LAT_V---"
		if [ ! -d /tmp/TS6 ]; then
			mkdir -p /tmp/TS6
		fi
		
		# Backup important files for TeamSpeak 6
		if [ -f ${DATA_DIR}/licensekey.dat ]; then
			cp ${DATA_DIR}/licensekey.dat /tmp/TS6
		fi
		if [ -f ${DATA_DIR}/tsserver.yaml ]; then
			cp ${DATA_DIR}/tsserver.yaml /tmp/TS6
		fi
		if [ -f ${DATA_DIR}/tsserver.sqlitedb ]; then
			cp ${DATA_DIR}/tsserver.sqlitedb /tmp/TS6
		fi
		if [ -d ${DATA_DIR}/files ]; then
			cp -R ${DATA_DIR}/files /tmp/TS6
		fi
		if [ -d ${DATA_DIR}/logs ]; then
			cp -R ${DATA_DIR}/logs /tmp/TS6
		fi
		
		# Clean and reinstall
		find ${DATA_DIR} -mindepth 1 -not -path ${DATA_DIR}/logs -not -path ${DATA_DIR}/files -delete
		cd ${DATA_DIR}
		if wget -q -nc --show-progress --progress=bar:force:noscroll -O tsserver.tar.bz2 "$DL_URL" ; then
			echo "---Successfully downloaded TeamSpeak 6!---"
		else
			echo "---Something went wrong, can't download TeamSpeak 6, putting server in sleep mode---"
			sleep infinity
		fi
		tar -xvjf ${DATA_DIR}/tsserver.tar.bz2
		rm ${DATA_DIR}/tsserver.tar.bz2
		
		# Find the extracted directory and move contents
		EXTRACTED_DIR=$(find ${DATA_DIR} -maxdepth 1 -type d -name "teamspeak*server*" | head -1)
		if [ -n "$EXTRACTED_DIR" ]; then
			mv ${EXTRACTED_DIR}/* ${DATA_DIR}/
			rm -rf ${EXTRACTED_DIR}
		fi
		
		# Restore backed up files
		cp -R /tmp/TS6/* ${DATA_DIR}/ 2>/dev/null || true
		rm -rf /tmp/TS6
		
		# Make tsserver executable
		chmod +x ${DATA_DIR}/tsserver
		CUR_V="$(${DATA_DIR}/tsserver --version 2>/dev/null | head -1 | awk '{print $NF}' || echo 'unknown')"
	else
		echo "---Server versions match! Installed: v$CUR_V | Latest: v${LAT_V}---"
	fi
else
	echo "---Couldn't get latest version number, Version check not possible, continuing---"
fi

echo "---Preparing server---"
echo "---Checking if 'tsserver.yaml' is present---"
if [ ! -f ${DATA_DIR}/tsserver.yaml ]; then
	echo "---'tsserver.yaml' not found, creating default configuration---"
	cat > ${DATA_DIR}/tsserver.yaml << 'EOF'
server:
  license-path: .
  default-voice-port: 9987
  voice-ip:
    - 0.0.0.0
    - "::"
  machine-id: ""
  threads-voice-udp: 5
  log-path: logs
  log-append: 0
  filetransfer-port: 30033
  filetransfer-ip:
    - 0.0.0.0
    - "::"
  accept-license: accept

  database:
    plugin: sqlite3
    sql-path: sql/
    sql-create-path: create_sqlite/
    client-keep-days: 30
    config:
      skip-integrity-check: 0

  query:
    pool-size: 2
    log-timing: 3600
    ip-allow-list: query_ip_allowlist.txt
    ip-block-list: query_ip_denylist.txt
    admin-password: ""
    log-commands: 0
    skip-brute-force-check: 0
    buffer-mb: 20
    documentation-path: serverquerydocs
    timeout: 300

    ssh:
      enable: 0
      port: 10022
      ip:
        - 0.0.0.0
        - "::"
      rsa-key: ssh_host_rsa_key

    http:
      enable: 1
      port: 10080
      ip:
        - 0.0.0.0
        - "::"
EOF
	echo "---Successfully created 'tsserver.yaml'!---"
else
	echo "---'tsserver.yaml' found---"
fi

chmod -R ${DATA_PERM} ${DATA_DIR}

echo "---Checking License---"
if [ "${TSSERVER_LICENSE_ACCEPTED}" != "accept" ]; then
	echo "---License not accepted---"
	echo 'Please set the environment variable TSSERVER_LICENSE_ACCEPTED to "accept" in order to accept the license agreement.'
	echo "---Putting server into sleep mode---"
	sleep infinity
fi

echo "---Starting TeamSpeak 6---"
cd ${DATA_DIR}
${DATA_DIR}/tsserver --config-file ${DATA_DIR}/tsserver.yaml ${EXTRA_START_PARAMS}