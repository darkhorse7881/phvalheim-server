#!/bin/bash

# all dbUpdater scripts must be executable!

# is this update already applied?
sql "DESCRIBE worlds"|grep public > /dev/null 2>&1
if [ ! $? = 0 ]; then
	echo "`date` [NOTICE : phvalheim] Applying database schema update for phvalheim-server >=v2.19"

	## BEGIN UPDATE ##
	# new column for public flag
	sql "ALTER TABLE worlds ADD COLUMN public BOOL DEFAULT 0;"

	# fix beta column
	sql "ALTER TABLE worlds MODIFY beta BOOL DEFAULT 0"

	if [ ! $? = 0 ]; then
		# update failed to apply
		exit 1
	fi

	## END UPDATE ##
else
	# update is already applied
	exit 2
fi
