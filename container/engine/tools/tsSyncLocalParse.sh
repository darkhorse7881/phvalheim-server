#!/bin/bash
source /opt/stateless/engine/includes/phvalheim-static.conf

/opt/stateless/engine/tools/sql "UPDATE systemstats SET tsSyncLocalLastExecStatus='running';"
/opt/stateless/engine/tools/sql "UPDATE systemstats SET tsSyncLocalLastRun=NOW();"


# error setter
function errorSetter() {
	RESULT=$1

	if [ $RESULT -ne 0 ]; then
		/opt/stateless/engine/tools/sql "UPDATE systemstats SET tsSyncLocalLastExecStatus='error';"
		exit 1
	fi
}


#PID stuff
touch /tmp/tsSync.pid
previousPID=$(cat /tmp/tsSync.pid)
echo $$ > /tmp/tsSync.pid
ps -p $previousPID > /dev/null 2>&1
RESULT=$?
if [ "$RESULT" = 0 ]; then
	#echo
	echo "`date` [WARN : phvalheim] A previous Thunderstore sync is running, killing..."
	kill -9 $previousPID
fi


#echo
echo "`date` [NOTICE : phvalheim] Downloading Thunderstore's Valheim database..."
curl -s -X GET "$tsApiUrl" -H  "accept: application/json" |jq '.[]' > $tsWIP/json
errorSetter $?


echo "`date` [phvalheim] Mangling Thunderstore JSON..."
json=$(cat $tsWIP/json)
errorSetter $?

allMods=$(jq -r ".uuid4" <<<$json)
errorSetter $?


function getParent(){
	ts_uuid4="$1"
        errorSetter $?
	ts_modJson=$(jq ". | select(.uuid4 == \"$ts_uuid4\") | {name,owner,package_url,date_created,date_updated,versions}|."<<<$json)
        errorSetter $?
        ts_name=$(jq -r ".name" <<<$ts_modJson)
        errorSetter $?
        ts_owner=$(jq -r ".owner" <<<$ts_modJson)
        errorSetter $?
        ts_package_url=$(jq -r ".package_url" <<<$ts_modJson)
        errorSetter $?
        ts_date_created=$(jq -r ".date_created" <<<$ts_modJson)
        errorSetter $?
        ts_date_updated=$(jq -r ".date_updated" <<<$ts_modJson)
        errorSetter $?
	ts_versions=$(jq ".versions|.[]" <<<$ts_modJson)
	errorSetter $?
}


function toDatabase(){
	ts_owner="${1}"
	ts_name="${2}"
	ts_package_url="${3}"
	ts_date_created="${4}"
	ts_date_updated="${5}"
	ts_uuid4="${6}"
	ts_versionUUID="${7}"
	ts_version="${8}"
	ts_deps="${9}"
	ts_version_date_created="${10}"

	ts_date_created=$(echo $ts_date_created|sed -e 's/^"//' -e 's/"$//')
	errorSetter $?

	ts_date_created=$(date -d"$ts_date_created" "+%Y-%m-%d %T")
	errorSetter $?

	ts_date_updated=$(echo $ts_date_updated|sed -e 's/^"//' -e 's/"$//')
	errorSetter $?

	ts_date_updated=$(date -d"$ts_date_updated" "+%Y-%m-%d %T")
	errorSetter $?

	ts_version_date_created=$(echo $ts_version_date_created|sed -e 's/^"//' -e 's/"$//')
	errorSetter $?

	ts_version_date_created=$(date -d "$ts_version_date_created" "+%Y-%m-%d %T")
	errorSetter $?

	existCheck=$(SQL "SELECT id FROM tsmods WHERE versionuuid='$ts_versionUUID';")

	if [ -z $existCheck ]; then
		echo "`date` [phvalheim] Thunderstore: $ts_name ($ts_versionUUID : $ts_version) does not exist in the database, adding..."
		SQL "INSERT INTO tsmods (owner,name,url,created,updated,moduuid,versionuuid,version,deps,version_date_created) VALUES ('$ts_owner','$ts_name','$ts_package_url','$ts_date_created','$ts_date_updated','$ts_uuid4','$ts_versionUUID','$ts_version','$ts_deps','$ts_version_date_created');"
	else
		echo "`date` [phvalheim] Thunderstore: $ts_name ($ts_versionUUID : $ts_version) already exists in database, updating..."
		SQL "UPDATE tsmods SET owner='$ts_owner',name='$ts_name',url='$ts_package_url',created='$ts_date_created',updated='$ts_date_updated',moduuid='$ts_uuid4',versionuuid='$ts_versionUUID',version='$ts_version',deps='$ts_deps',version_date_created='$ts_version_date_created' WHERE versionUUID='$ts_versionUUID';"

	fi
}


#Get all versions and dependencies for each version under parent
for ts_uuid4 in $allMods; do
	getParent "$ts_uuid4"

	#toDatabase "parent" "$ts_owner" "$ts_name" "$ts_package_url" "$ts_date_created" "$ts_date_updated" "$ts_uuid4"

        #echo
        #echo "UUID: $ts_uuid4"
        #echo "Name: $ts_name"
        #echo "Owner: $ts_owner"
        #echo "URL: $ts_package_url"
        #echo "Created: $ts_date_created"
        #echo "Updated: $ts_date_updated"
        #echo
        #echo "Versions:"

	ts_versionUUIDs=$(jq -r ".uuid4" <<<$ts_versions)
	for ts_versionUUID in $ts_versionUUIDs; do
		ts_version=$(jq ". | select(.uuid4 == \"$ts_versionUUID\") | {version_number}|.[]"<<<$ts_versions)
		errorSetter $?

		ts_deps=$(jq ". | select(.uuid4 == \"$ts_versionUUID\") | {dependencies}|.[]"<<<$ts_versions)
		errorSetter $?

		ts_version_date_created=$(jq ". | select(.uuid4 == \"$ts_versionUUID\") | {date_created}|.[]"<<<$ts_versions)
		errorSetter $?

		toDatabase "$ts_owner" "$ts_name" "$ts_package_url" "$ts_date_created" "$ts_date_updated" "$ts_uuid4" "$ts_versionUUID" "$ts_version" "$ts_deps" "$ts_version_date_created"
		errorSetter $?
		#echo " Version Number: $ts_version"
		#echo " Version UUID: $ts_versionUUID"
		#echo " Dependencies: $ts_deps"
		#echo
	done
done

echo "`date` [NOTICE : phvalheim] Thunderstore's sync is complete..."


# update the database
/opt/stateless/engine/tools/sql "UPDATE systemstats SET tsSyncLocalLastExecStatus='idle';"
/opt/stateless/engine/tools/sql "UPDATE systemstats SET tsUpdated=NOW();"
/opt/stateless/engine/tools/sql "UPDATE systemstats SET tsSyncLocalLastRun=NOW();"
