function setProjectsPath() {
  read -p "Where is your Liferay Portal? [/home/me/dev/projects] " dirName

  if [[ -z "$dirName" ]]; then
    dirName="\/home\/me\/dev\/projects"
  fi

  sed -i "s/NULL/$dirName/g" build-portal.sh
}