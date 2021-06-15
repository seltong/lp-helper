#!/bin/bash

if [ "$1" == "build" ] ; then
  source build-portal.sh

  # Select portal version:
  selectLiferayPortalVersion

  # Select portal branch:
  selectLiferayPortalBranch

  if [[ "$1" == "aa" ]] ; then
    cd $PATH/$portalVersion
    
    gSyncBranch
    aa
  else
    # Clear bundles
    clearBundle

    # Build Portal
    buildPortal
  fi
elif [[ "${1}" == "runPortal" ]] ; then
  source build-portal.sh

  # Select portal version:
  selectLiferayPortalVersion

  # Select portal branch:
  selectLiferayPortalBranch

  cd "$(find ${PROJECTS_PATH}/bundles-${portalVersion}-${portalBranch} -name 'bin' -type d)"
  ./catalina.sh run
fi