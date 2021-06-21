#!/bin/bash

PROJECTS_PATH=NULL

portalBranchs=(
  "master"
  "7.3.x"
  "7.2.x"
  "7.1.x"
  "7.0.x"
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
  bundlesName="bundles-${portalVersion}-${portalBranch}"
  bundlesPath="${PROJECTS_PATH}/$bundlesName"
  portalPath="${PROJECTS_PATH}/${portalVersion}"
  
  echo ""
  echo "Go to: $portalPath"
  cd $portalPath
  
  echo ""
  echo "Run git checkout ${portalBranch}"
  git checkout ${portalBranch}
  
  gitClean

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

  clearAppServerProperties
  createAppServerProperties
  
  echo ""
  echo "[Creating bundles]"
  echo "Bundles path: $bundlesPath"
  aa
  
  esti $bundlesPath
  
  createPortalExt $bundlesPath
  
  successMessage="Bundles creation success!"
  failureMessage="Bundles creation failure!"
  
  existsDir $bundlesPath $successMessage $failureMessage
}

function clearAppServerProperties() {
  user="$(whoami)"
  appServerPath=${PROJECTS_PATH}/${portalVersion}

  echo ""
  echo "[Deleting app.server.${user}.properties]"
  echo "App server path: $appServerPath"

  successMessage="Deleted app.server.${user}.properties]"
  failureMessage="App server does not exists!"

  if [[ -f app.server.${user}.properties] ]] ; then
    rm app.server.${user}.properties
    echo "$successMessage"
  else
    echo "$failureMessage"
  fi
}

function clearBundle() {
  echo ""
  echo "[Deleting bundles]"
  echo "Bundles path: ${PROJECTS_PATH}/bundles-${portalVersion}-${portalBranch}"

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

  sed -i "s/bundles/$bundlesName/g" app.server.$user.properties

  echo "App server was created!"
}

function createPortalExt() {
  cd $path
  
  if [[ -f portal-ext.properties ]] ; then
    echo "Deleting portal-ext.properties"
    rm portal-ext.properties
  fi
  
  echo "module.framework.properties.osgi.console=localhost:11311
        company.security.strangers.verify=false
        terms.of.use.required=false
        admin.email.from.address=test@liferay.com
        admin.email.from.name=Test Test
        company.default.locale=en_US
        company.default.time.zone=UTC
        company.default.web.id=liferay.com
        default.admin.email.address.prefix=test
        setup.wizard.enabled=false
        index.on.startup=true
        mail.session.jndi.name=
        axis.servlet.hosts.allowed=
        tunnel.servlet.hosts.allowed=
        theme.css.fast.load=true
        theme.images.fast.load=true
        javascript.fast.load=false
        layout.template.cache.enabled=false
        combo.check.timestamp=true
        freemarker.engine.cache.storage=soft:1
        freemarker.engine.modification.check.interval=0
        minifier.enabled=false
        com.liferay.portal.servlet.filters.cache.CacheFilter=false
        com.liferay.portal.servlet.filters.etag.ETagFilter=false
        com.liferay.portal.servlet.filters.header.HeaderFilter=false
        com.liferay.portal.servlet.filters.themepreview.ThemePreviewFilter=true
        users.reminder.queries.enabled=false
        users.reminder.queries.custom.question.enabled=false
        ##
        ## Monitoring
        ##
            #
            # Configure the appropriate level for monitoring Liferay.
            # Valid values are: HIGH, LOW, MEDIUM, OFF.
            #
            monitoring.level.com.liferay.monitoring.Portal=HIGH
            monitoring.level.com.liferay.monitoring.Portlet=HIGH
            #
            # Set this to true to monitor portal requests.
            #
            monitoring.portal.request=true
            #
            # Set this to true to monitor portlet action requests.
            #
            monitoring.portlet.action.request=true
            #
            # Set this to true to monitor portlet event requests.
            #
            monitoring.portlet.event.request=true
            #
            # Set this to true to monitor portlet render requests.
            #
            monitoring.portlet.render.request=true
            #
            # Set this to true to monitor portlet resource requests.
            #
            monitoring.portlet.resource.request=true
            #
            # Set this to true to show data samples at the bottom of each portal page
            # as HTML comment. In order for data to show, the property
            # \"monitoring.data.sample.thread.local\" must be set to true.
            #
            monitoring.show.per.request.data.sample=true
            #
            # Set the date format used for storing dates as text in the index.
            #
            #index.date.format.pattern=YYYY-MM-DDThh:mm:ssZ
                #
            # Set how often index updates will be committed. Set the batch size to
            # configure how many consecutive updates will trigger a commit. If the value
            # is 0, then the index will be committed on every update. Set the time
            # interval in milliseconds to configure how often to commit the index. The
            # time interval is not read unless the batch size is greater than 0 because
            # the time interval works in conjunction with the batch size to guarantee
            # that the index is committed after a specified time interval. Set the time
            # interval to 0 to disable committing the index by a time interval.
            #
            lucene.commit.batch.size=1
            lucene.commit.time.interval=1" > portal-ext.properties

  echo "Portal-ext.properties was created."
}

function esti() {
  echo ""

  tomcatPath="$(find $bundlesPath -name 'tomcat-[0-9]*\.[0-9]*\.[0-9]*' -type d)"

  successMessage="Tomcat exists."
  failureMessage="Tomcat not found."

  existsDir $tomcatPath $successMessage $failureMessage

  echo ""
  echo "Tomcat path: ${tomcatPath}"

  if [[ -d $tomcatPath ]]; then
    echo "system.properties was created."
    cd $tomcatPath && cd webapps/ROOT/WEB-INF/classes && touch system-ext.properties && echo 'liferay.mode=test' > system-ext.properties
  else
    echo "$tomcatPath not found."
  fi
}

function existsDir() {
  if [[ -d ${1} ]] ; then
    echo ${successMessage}
    return 0
  else
    echo ${failureMessage}
    return 1
  fi
}

function gitClean() {
  user="$(whoami)"

  echo ""
  echo "Run git clean -dfx"
  git clean -dfx -e build.$user.properties -e app.server.$user.properties -e portal-ext.properties -e release.$user.properties -e portal-test-ext.properties -e .project -e .classpath -e .iml
}

function gSyncBranch() {
  echo ""

  git pull -r upstream $portalBranch
  echo "Upstream $portalBranch was updated."

  git push origin $portalBranch
  echo "Origin $portalBranch was updated."
}

function help() {
  echo ""

  echo "usage: ./main.sh COMMAND"
  echo ""

  echo "List of Commands:"
  echo ""

  echo "build             Build the Liferay Portal"
  echo "help              Display a helpful usage message"
  echo "runPortal         Run the Liferay Portal"
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