#!/bin/sh
set -e

if [ ! -z "${ENABLE_CRONTAB}" ]; then
	cron -f &
fi

# first arg is `-f` or `--some-option`
if [ "${1#-}" != "$1" ]; then
	set -- nginx "$@"
fi

exec "$@"
