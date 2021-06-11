#!/bin/bash

PROJECTS_PATH=/home/me/dev/projects

portalBranchs=(
  "master"
  "7.3.x"
  "7.2.x"
)

portalVersions=(
  "liferay-portal"
  "liferay-portal-ee"
)

function aa() {
  echo ""

  echo "Executing: ant setup-profile-dxp"
  echo ""
  ant setup-profile-dxp

  echo "Executing: ant all"
  echo ""
  ant all
}

function buildPortal() {
  dir=${PROJECTS_PATH}/bundles-${portalVersion}-${portalBranch}
  portalPath=${PROJECTS_PATH}/${portalVersion}
  
  echo ""
  echo "Go to: $portalPath"
  cd $portalPath
  
  echo ""
  echo "Run git checkout ${portalBranch}"
  git checkout ${portalBranch}
  
  gSyncBranch

  gStatus="$(git status --short)"
  
  if [[ ! -z $gStatus ]] ; then
    echo "You have some modified files to resolve."
    read -p "Do you want to checkout all? [Y/n]" string
    
    if [[ $string == "Y" || $string == "y" ]] ; then
      echo ""
      echo "Running git checkout . and git clean -f ."
      git checkout .
      git clean -f .
    else
      echo ""
      echo "Resolve it and try again."
      exit 1
    fi
  fi

  #createAppServerProperties
  
  echo ""
  echo "[Creating bundles]"
  echo "Bundles path: $dir"
  aa
  
  esti $dir
  
  # createPortalExt $dir
  
  successMessage="Bundles creation success!"
  failureMessage="Bundles creation failure!"
  
  existsDir $dir $successMessage $failureMessage
}

function clearAppServerProperties() {
  user="$(whoami)"
  dir=${PROJECTS_PATH}/${portalVersion}

  echo ""
  echo "[Deleting app.server.${user}.properties]"
  echo "App server path: ${PROJECTS_PATH}/${portalVersion}"

  successMessage="Deleted $dir/app.server.${user}.properties]"
  failureMessage="App server does not exists!"

  if [[ -f $dir/app.server.${user}.properties] ]] ; then
    rm $dir/app.server.${user}.properties
    echo "$successMessage"
  else
    echo "$failureMessage"
  fi
}

function clearBundle() {
  echo ""
  echo "[Deleting bundles]"
  echo "Bundles path: ${PROJECTS_PATH}/bundles-${portalVersion}-${portalBranch}"

  dir=${PROJECTS_PATH}/bundles-${portalVersion}-${portalBranch}
  successMessage="Deleted ${PROJECTS_PATH}/bundles-${portalVersion}-${portalBranch}"
  failureMessage="Bundles does not exists!"

  existsDir $dir $successMessage $failureMessage

  rm -rf ${PROJECTS_PATH}/bundles
  if [ $? == 1 ] ; then
    rm -rf $dir
  fi
}

function createAppServerProperties() {
  user="$(whoami)"

  echo ""
  echo "[Creating app.server.${user}.properties]"
  echo "App server path: ${PROJECTS_PATH}/${portalVersion}"

  cp -R app.server.properties app.server.$user.properties
  # adicionar a bundles-ee no arquivo app.server.$user

  echo "App server was created!"
}

function createPortalExt() {
  cd $path
  if [[ -f portal-ext.properties ]] ; then
    echo "Deleting portal-ext.properties"
    rm portal-ext.properties
  fi
  
  echo "code portal-ext..." > portal-ext.properties
  echo "Portal-ext.properties was created."
}

function esti() {
  echo ""

  tomcatName="$(find $path -name 'tomcat-*')"
  
  successMessage="Tomcat exists."
  failureMessage="Tomcat not found."

  existsDir $path/$tomcatName $successMessage $failureMessage

  if [[ -d $path/$tomcatName ]]; then
    echo "system.properties was created."
    cd $path/$tomcatName/webapps/ROOT/WEB-INF/classes && touch system-ext.properties && echo 'liferay.mode=test' > system-ext.properties
  else
    echo "$path/$tomcatName not found."
  fi
}

function existsDir() {
  if [[ -d ${dir} ]]; then
    echo ${successMessage}
    return 1
  else
    echo ${failureMessage}
    return 0
  fi
}

function gSyncBranch() {
  echo ""

  git pull -r upstream $portalBranch
  echo "Upstream $portalBranch was updated."

  git push origin $portalBranch
  echo "Origin $portalBranch was updated."
}

function selectLiferayPortalBranch() {
  echo ""

  PS3="Choose the Liferay portal branch: "

  select portalBranch in ${portalBranchs[@]}
  do
      echo ""
      echo "Selected branch: $portalBranch"
      break
  done
}

function selectLiferayPortalVersion() {
  echo ""

  PS3="Choose the Liferay portal version: "

  select portalVersion in ${portalVersions[@]}
  do
      echo ""
      echo "Selected version: $portalVersion"
      break
  done
}

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