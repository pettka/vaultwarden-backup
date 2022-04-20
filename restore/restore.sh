#!/bin/bash

#HOWTO decrypt:  gpg --pinentry-mode=loopback -d vaultwarden-20220111-2100.tar.xz.gpg

set -ex

# Use the value of the corresponding environment variable, or the
# default if none exists.
# : ${VAULTWARDEN_ROOT:="$(realpath "${0%/*}"/..)"}
: ${VAULTWARDEN_ROOT:="$(realpath "${0%/*}"/)"}
: ${SQLITE3:="/usr/bin/sqlite3"}
: ${RCLONE:="/usr/bin/rclone"}
: ${GPG:="/usr/bin/gpg"}
: ${AGE:="/usr/local/bin/age"}

DATA_DIR="${VAULTWARDEN_ROOT}/vw-data"
BACKUP_ROOT="${VAULTWARDEN_ROOT}/backup"
REMOTE_PATH="storj-connection-name:backup-folder"
REMOTE_FILE_NAME="$(${RCLONE} lsjson ${REMOTE_PATH} | jq -r '.[-1].Path')" # latest file item
REMOTE_FILE_PATH="${REMOTE_PATH}/${REMOTE_FILE_NAME}"

/usr/local/bin/docker-compose down

source "${BACKUP_ROOT}"/backup.conf
rm -rf "${BACKUP_ROOT}/tmp"
rm -rf "${DATA_DIR}" && mkdir "${DATA_DIR}"
mkdir "${BACKUP_ROOT}/tmp"

cd "${BACKUP_ROOT}/tmp"
${RCLONE} -vv --no-check-dest copy "${REMOTE_FILE_PATH}" . # download backup file

# decrypt & untar
printf '%s' "${GPG_PASSPHRASE}" | ${GPG} --pinentry-mode=loopback --batch --yes --passphrase-fd 0 -d "${REMOTE_FILE_NAME}" | tar xJf -

rsync -arvhz "${BACKUP_ROOT}/tmp/$(echo $REMOTE_FILE_NAME | sed 's/\(.*\).\(tar.xz.gpg\)/\1/')/" "${DATA_DIR}/"


cd "${VAULTWARDEN_ROOT}"
/usr/local/bin/docker-compose up -d

rm -rf "${BACKUP_ROOT}/tmp