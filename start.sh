#!/bin/bash

echo "Database : $DATABASE_NAME"
DATABASE_FILE=/var/www/data/${DATABASE_NAME}.sqlite

DATA_DIR=/var/www/data
DATABASE_FILE=${DATA_DIR}/${DATABASE_NAME}.sqlite
LOG_DIR=${DATA_DIR}/log
CFG_DIR=${DATA_DIR}/config

function maintenance {
  #maintenance
  echo "Starting Mediawiki maintenance ..."
  maintenance/update.php --quick > ${LOG_DIR}/mw_update.log 

  #cd extensions/Wikibase/
  #php lib/maintenance/populateSitesTable.php >> ${LOG_DIR}/mw_update.log 
  #cd ../..
}

mkdir -p ${DATA_DIR}/images ${LOG_DIR} ${CFG_DIR}
chown www-data:www-data ${DATA_DIR}
chown www-data:www-data ${DATA_DIR}/images 
chown www-data:www-data ${LOG_DIR} ${CFG_DIR}

#if LocalSettings.custom.php is not a sym link,
# then move this file and create the link
if [ -f ./LocalSettings.custom.php ]
then
  mv ./LocalSettings.custom.php ${CFG_DIR}/LocalSettings.custom.php
  ln -s ${CFG_DIR}/LocalSettings.custom.php ./LocalSettings.custom.php
fi

#Fix latence problem
rm -rf ${DATA_DIR}/locks

#Init database
if [ -e ${DATABASE_FILE} ]
then 
  echo "Database already initialized" 
else 
  echo "Database not exist -> Initialize database" 
  #Copy the "empty" database
  cp /tmp/my_wiki.sqlite ${DATABASE_FILE}
  #Allow to write on database
  chmod 644 ${DATABASE_FILE} && chown www-data:www-data ${DATABASE_FILE}
  
  #change Admin password
  php maintenance/createAndPromote.php --bureaucrat --sysop --bot --force Admin ${MEDIAWIKI_ADMIN_PASSWORD}  
  
  maintenance
  
  # if new databse, always mirroring
  MIRRORING=1
fi

echo "Starting Persoid ..."
cd parsoid
node bin/server.js > ${LOG_DIR}/parsoid.log  &
cd .. 

service memcached start 

if [ ${MIRRORING} ]
then
  #mirroring
  service apache2 start
  echo "Starting mirroring ..."
  wikimedia_sync ${MIRRORING_OPTIONS} -e "${LOG_DIR}" mirroring.json | tee -a ${LOG_DIR}/mirroring.log 
  service apache2 stop
  
  maintenance
  
  php maintenance/refreshLinks.php -e 100 >> ${LOG_DIR}/mw_update.log 
  
  #build tarbals
  #echo "Build tarbal"
  #cd ${DATA_DIR}
  #tar -czvvf data-${DATABASE_NAME}.tgz ${DATABASE_NAME}.sqlite log config >> ${LOG_DIR}/mirroring.log 
  #tar -cvvf images-${DATABASE_NAME}.tar images >> ${LOG_DIR}/mirroring.log 
  #cd ../html
fi

# create links to allow download tarbals
#ln -s ${DATA_DIR}/data-${DATABASE_NAME}.tgz
#ln -s ${DATA_DIR}/images-${DATABASE_NAME}.tar
ln -s ${DATA_DIR} data

maintenance

#finnaly, start apache and wait
echo "Starting Apache 2 ..."
apache2ctl -D FOREGROUND

# for debug
#service apache2 start
#/bin/bash

#if [ -z "$1" ]
#then
#  echo "Starting Apache 2 ..."
#  apache2ctl -D FOREGROUND
#else
#service apache2 start
#exec "$@"
#fi

