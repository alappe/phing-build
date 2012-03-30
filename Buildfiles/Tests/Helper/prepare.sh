#!/bin/bash
#  Copyright (c) 2011, kuehlhaus AG
#  All rights reserved.
#  
#  Redistribution and use in source and binary forms, with or without
#  modification, are permitted provided that the following conditions are
#  met:
#  
#  - Redistributions of source code must retain the above copyright notice,
#    this list of conditions and the following disclaimer.
#  - Redistributions in binary form must reproduce the above copyright
#    notice, this list of conditions and the following disclaimer in the
#    documentation and/or other materials provided with the distribution.
#  - Neither the name of the kuehlhaus AG nor the names of its
#    contributors may be used to endorse or promote products derived from
#    this software without specific prior written permission.
# 
#  THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
#  "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
#  LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR
#  A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT
#  HOLDER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL,
#  SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT
#  LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE,
#  DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY
#  THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
#  (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
#  OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
#
###
# 
# Prepare TYPO3 UnitTests by executing the following tasks:
#
# - Check if extension already is in destination directory
#   If so, delete it.
# - Copy extension to destination directory
# - Activate extension
# - Update tables
# - Clear temporary files (aka clear cache)

EXT=$2;
TYPO3INSTALLATION=$3;
TYPO3EXTENSIONDIRECTORY="${TYPO3INSTALLATION}/typo3conf/ext";

# Get the database credentials by grepping them out of the localconf.php serving this
# installation. This is not really save, consider using | tail -n 1 | in the future…
function getDatabaseCredentials () {
	if [ ! -r "${TYPO3INSTALLATION}/typo3conf/localconf.php" ]; then
		echo "No previous installation of ${EXT} found… exiting";
		exit 0;
	fi

	MYSQL_USER=$(grep typo_db_username ${TYPO3INSTALLATION}/typo3conf/localconf.php | sed "s/^.*'\(.*\)'.*$/\1/g");
	if [ -z ${MYSQL_USER} ]; then
		echo "Cannot get typo3_db_username from localconf.php!";
		exit 1;
	fi

	MYSQL_PASS=$(grep typo_db_password ${TYPO3INSTALLATION}/typo3conf/localconf.php | sed "s/^.*'\(.*\)'.*$/\1/g");
	if [ -z ${MYSQL_PASS} ]; then
		echo "Cannot get typo3_db_password from localconf.php!";
		exit 1;
	fi

	MYSQL_DB=$(grep "typo_db " ${TYPO3INSTALLATION}/typo3conf/localconf.php | sed "s/^.*'\(.*\)'.*$/\1/g");
	if [ -z ${MYSQL_DB} ]; then
		echo "Cannot get typo3_db from localconf.php!";
		exit 1;
	fi

	MYSQL_HOST=$(grep "typo_db_host" ${TYPO3INSTALLATION}/typo3conf/localconf.php | sed "s/^.*'\(.*\)'.*$/\1/g");
	if [ -z ${MYSQL_HOST} ]; then
		echo "Cannot get typo3_db_host from localconf.php!";
		exit 1;
	fi
}

# Get the tables the extension requires by grepping them out of the ext_tables.sql
# supplied with the extension.
function dropExtensionDatabaseTables () {
	if [ -r "${TYPO3EXTENSIONDIRECTORY}/${EXT}/ext_tables.sql" ]; then
		DROP_TABLES_STATEMENT=$(grep "CREATE TABLE" ${TYPO3EXTENSIONDIRECTORY}/${EXT}/ext_tables.sql | sed "s/CREATE TABLE \(.*\) (/\1/g" | tr "\n" ", " | sed "s/\(.*\),$/DROP TABLE IF EXISTS \1;/g");
		mysql --user=${MYSQL_USER} --password=${MYSQL_PASS} --host=${MYSQL_HOST} ${MYSQL_DB} --execute="${DROP_TABLES_STATEMENT}";
		if [ $? -ne 0 ]; then
			echo "Cannot drop tables from ext_tables.sql!";
			return 1;
		fi
	else
		echo "ext_tables.sql not found, skipping drop tables!";
	fi
}

# Insert the tables from ext_tables.sql
function createExtensionDatabaseTables () {
	mysql --user=${MYSQL_USER} --password=${MYSQL_PASS} --host=${MYSQL_HOST} ${MYSQL_DB} < ${TYPO3EXTENSIONDIRECTORY}/${EXT}/ext_tables.sql;
	if [ $? -ne 0 ]; then
		echo "Cannot insert tables from ext_tables.sql!";
		return 1;
	fi
}

# Check if there are leftover directories and delete
# them if that is the case;
function removeLeftovers () {
	if [ -d "${TYPO3EXTENSIONDIRECTORY}/${EXT}" ]; then
		echo "Leftover directory found, will delete";
		id;
		rm -rf ${TYPO3EXTENSIONDIRECTORY}/${EXT}
	fi
}

# Check if extension is already activated:
function checkExtensionActivationStatus () {
	grep ".*extList_FE.*${EXT}.*" "${TYPO3INSTALLATION}/typo3conf/localconf.php" > /dev/null 2>&1
	if [ $? -ne 0 ]; then
		# Activate 
		echo "Activate…";
		activateExtension;
	else
		echo "Extension already activated…";
	fi
}

# Activate extension
function activateExtension () {
	# Activate in extList and extList_FE
	sed -i "s/\(.*extList.*\)';\(.*\/\/.*$\)/\1,${EXT}';\2/g" "${TYPO3INSTALLATION}/typo3conf/localconf.php"
	if [ $? -ne 0 ]; then
		echo "Activation failed!";
		return 1;
	fi
}

# Deactivate extension
function deactivateExtension () {
	# Activate in extList and extList_FE
	sed -i "s/\(.*extList.*\),${EXT}\(.*$\)/\1\2/g" "${TYPO3INSTALLATION}/typo3conf/localconf.php"
	if [ $? -ne 0 ]; then
		echo "Deactivation failed!";
		return 1;
	fi
}

# Delete cached files
function cleanCachedFiles () {
	echo "Cleaning cache...";
	rm -f ${TYPO3INSTALLATION}/typo3conf/temp_*;
}

if [ $1 = "clean" ]; then
	getDatabaseCredentials;
	dropExtensionDatabaseTables
	removeLeftovers;
elif [ $1 = "install" ]; then
	getDatabaseCredentials;
	checkExtensionActivationStatus;
	createExtensionDatabaseTables;
	cleanCachedFiles;
fi

#deactivateExtension;
