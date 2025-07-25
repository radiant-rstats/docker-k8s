#!/usr/bin/env bash

function docker_setup() {
  echo "Usage: $0 [-d]"
  echo "  -d, --dev   Setup using development repo"
  echo ""
  exit 1
}

## parse command-line arguments
while [[ "$#" > 0 ]]; do case $1 in
  -d|--dev) ARG_TAG="$1"; shift;shift;;
  *) echo "Unknown parameter passed: $1"; echo ""; docker_setup; shift; shift;;
esac; done

ostype=`uname`
if [[ "$ostype" == "Linux" ]]; then
  HOMEDIR=~
  sed_fun () {
    sed -i $1 "$2"
  }
  is_wsl=$(which explorer.exe)
  if [[ "$is_wsl" != "" ]]; then
    ostype="WSL2"
    HOMEDIR=~
  fi
elif [[ "$ostype" == "Darwin" ]]; then
  ostype="macOS"
  HOMEDIR=~
  sed_fun () {
    sed -i '' -e $1 "$2"
  }
else
  ostype="Windows"
  HOMEDIR="C:/Users/$USERNAME"
  sed_fun () {
    sed -i $1 "$2"
  }
fi

echo "-----------------------------------------------------------------------"
echo "Set report generation options for Radiant"
echo "-----------------------------------------------------------------------"

RPROF="${HOMEDIR}/.Rprofile"
touch "${RPROF}"

sed_fun '/^options(radiant.maxRequestSize/d' "${RPROF}"
sed_fun '/^options(radiant.report/d' "${RPROF}" 
sed_fun '/^options(radiant.shinyFiles/d' "${RPROF}"
sed_fun '/^options(radiant.ace_autoComplete/d' "${RPROF}"
sed_fun '/^options(radiant.ace_theme/d' "${RPROF}"
sed_fun '/^#.*List.*specific.*directories.*you.*want.*to.*use.*with.*radiant/d' "${RPROF}"
sed_fun '/^#.*options(radiant\.sf_volumes.*=.*c(Git.*=.*"\/home\/jovyan\/git"))/d' "${RPROF}"
echo ''
echo 'options(radiant.maxRequestSize = -1)' >> "${RPROF}"
echo 'options(radiant.report = TRUE)' >> "${RPROF}"
echo 'options(radiant.shinyFiles = TRUE)' >> "${RPROF}"
echo 'options(radiant.ace_autoComplete = "live")' >> "${RPROF}"
echo 'options(radiant.ace_theme = "tomorrow")' >> "${RPROF}"
if ! grep -q 'options(\s*repos\s*' ${RPROF}; then
  echo '
  if (Sys.info()["sysname"] == "Linux") {
    options(repos = c(
      RSPM = "https://packagemanager.posit.co/cran/__linux__/noble/latest",
      CRAN = "https://cloud.r-project.org"
    ))
  } else {
    options(repos = c(
      CRAN = "https://cloud.r-project.org"
    ))
  }
  ' >> "${RPROF}"
fi
echo '# List specific directories you want to use with radiant' >> "${RPROF}"
echo '# options(radiant.sf_volumes = c(Git = "/home/jovyan/git"))' >> "${RPROF}"
echo '' >> "${RPROF}"
sed_fun '/^[\s]*$/d' "${RPROF}"

echo "-----------------------------------------------------------------------"
echo "Setting up oh-my-zsh shell"
echo "-----------------------------------------------------------------------"

## adding an dir for zsh to use
if [ ! -d "${HOMEDIR}/.rsm-msba/zsh" ]; then
  mkdir -p "${HOMEDIR}/.rsm-msba/zsh"
fi

if [ ! -f "${HOMEDIR}/.rsm-msba/zsh/.p10k.zsh" ]; then
  cp /etc/skel/.p10k.zsh "${HOMEDIR}/.rsm-msba/zsh/.p10k.zsh"
else
  echo "-----------------------------------------------------"
  echo "You have an existing .p10k.zsh file. Do you want to"
  echo "replace it with the recommended version for this" 
  echo "docker container (y/n)?"
  echo "-----------------------------------------------------"
  read overwrite
  if [ "${overwrite}" == "y" ]; then
    cp /etc/skel/.p10k.zsh "${HOMEDIR}/.rsm-msba/zsh/.p10k.zsh"
  fi
fi

if [ ! -d "${HOMEDIR}/.rsm-msba/zsh/.oh-my-zsh" ]; then
  cp -r /etc/skel/.oh-my-zsh "${HOMEDIR}/.rsm-msba/zsh/"
else
  echo "-----------------------------------------------------"
  echo "You have an existing .oh-my-zsh directory. Do you"
  echo "want to replace it with the recommended version for"
  echo "this docker container (y/n)?"
  echo "-----------------------------------------------------"
  read overwrite
  if [ "${overwrite}" == "y" ]; then
    cp -r /etc/skel/.oh-my-zsh "${HOMEDIR}/.rsm-msba/zsh/"
  fi
fi

if [ ! -f "${HOMEDIR}/.rsm-msba/zsh/.zshrc" ]; then
  cp /etc/skel/.zshrc "${HOMEDIR}/.rsm-msba/zsh/.zshrc"
  source ~/.rsm-msba/zsh/.zshrc 2>/dev/null
else
  echo "---------------------------------------------------"
  echo "You have an existing .zshrc file. Do you want to"
  echo "replace it with the recommended version for this"
  echo "docker container (y/n)?"
  echo "---------------------------------------------------"
  read overwrite
  if [ "${overwrite}" == "y" ]; then
    cp /etc/skel/.zshrc "${HOMEDIR}/.rsm-msba/zsh/.zshrc"
    source ~/.rsm-msba/zsh/.zshrc 2>/dev/null
  fi
fi

if [ ! -f "${HOMEDIR}/.lintr" ]; then
  echo "---------------------------------------------------"
  echo "Adding a .lintr file to set linting preferences for"
  echo "R in VS Code"
  echo "---------------------------------------------------"
  echo 'linters: linters_with_defaults(
  object_name_linter = NULL,
  commented_code_linter = NULL,
  line_length_linter(120))
' > "${HOMEDIR}/.lintr"
fi

echo "-----------------------------------------------------------------------"
echo "Setup complete"
echo "-----------------------------------------------------------------------"
