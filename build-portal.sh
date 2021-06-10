#!/bin/bash

PATH=/home/me/dev/projects

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
  ant setup-profile-dxp && ant all
}

function buildPortal() {
  echo ""
  echo "[Creating bundles]"

  dir=${PATH}/bundles-${portalVersion}-${portalBranch}
  portalPath=${PATH}/bundles-${portalVersion}

  echo "Bundles path: $dir"
  
  cd $portalPath
  git checkout ${portalBranch}
  gSyncBranch
  clearAppServerProperties
  createAppServerProperties
  aa
  esti $dir
  createPortalExt
  
  successMessage="Bundles creation success!"
  failureMessage="Bundles creation failure!"
  
  existsDir $dir $successMessage $failureMessage
}

function clearAppServerProperties() {
  user="$(whoami)"
  dir=${PATH}/${portalVersion}

  echo ""
  echo "[Deleting app.server.${user}.properties]"
  echo "App server path: ${PATH}/${portalVersion}"

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
  echo "Bundles path: ${PATH}/bundles-${portalVersion}-${portalBranch}"

  dir=${PATH}/bundles-${portalVersion}-${portalBranch}
  successMessage="Deleted ${PATH}/bundles-${portalVersion}-${portalBranch}"
  failureMessage="Bundles does not exists!"

  existsDir $dir $successMessage $failureMessage

  if [ $? == 1 ] ; then
    rm -rf $dir
  fi
}

function createAppServerProperties() {
  user="$(whoami)"

  echo ""
  echo "[Creating app.server.${user}.properties]"
  echo "App server path: ${PATH}/${portalVersion}"

  cp -R app.server.properties app.server.$user.properties
  # adicionar a bundles-ee no arquivo app.server.$user

  echo "App server was created!"
}

function createPortalExt() {
  cd $path
  if [[ -f portal-ext.properties ]] ; then
    rm portal-ext.properties
  else
    echo "code portal-ext..." > portal-ext.properties
  fi
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

# Clear bundles
clearBundle

# Build Portal
buildPortal

echo ""
echo "Go to: ${PATH}/${portalVersion}"

cd ${PATH}/$portalVersion 

echo "Branch: ${portalBranch}"
