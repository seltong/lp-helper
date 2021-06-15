#!/bin/bash

source build-portal.sh
source config.sh

if [ "$PROJECTS_PATH" == "NULL" ] ; then
  setProjectsPath
fi

if [[ "$1" == "aa" ]] ; then
    cd $PATH/$portalVersion
    
    gSyncBranch
    aa
elif [ "$1" == "build" ] ; then
  selectLiferayPortalVersion

  selectLiferayPortalBranch
  
  clearBundle

  buildPortal
elif [[ "${1}" == "runPortal" ]] ; then
  selectLiferayPortalVersion

  selectLiferayPortalBranch

  cd "$(find ${PROJECTS_PATH}/bundles-${portalVersion}-${portalBranch} -name 'bin' -type d)"
  ./catalina.sh run
fi