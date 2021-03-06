#!/bin/bash

# Thanks goes to @pete-otaqui for the initial gist:
# https://gist.github.com/pete-otaqui/4188238
#
# Original version modified by Marek Suscak
#
# works with a file called VERSION in the current directory,
# the contents of which should be a semantic version number
# such as "1.2.3" or even "1.2.3-beta+001.ab"

# this script will display the current version, automatically
# suggest a "minor" version update, and ask for input to use
# the suggestion, or a newly entered value.

# New revision modified by Nomane Oulali
# - Add some reliability stuff like controlling that last commit is
#   not already tagged
# - Allow custom comment when you apply your tags
# - Increment patch field instead of minor
# Thanks to Marek Suscak for the original version
# https://gist.github.com/mareksuscak/1f206fbc3bb9d97dec9c

# once the new version number is determined, the script will
# pull a list of changes from git history, prepend this to
# a file called CHANGELOG.md (under the title of the new version
# number), give user a chance to review and update the changelist
# manually if needed and create a GIT tag.

NOW="$(date +'%B %d, %Y')"
RED="\033[1;31m"
GREEN="\033[0;32m"
YELLOW="\033[1;33m"
BLUE="\033[1;34m"
PURPLE="\033[1;35m"
CYAN="\033[1;36m"
WHITE="\033[1;37m"
RESET="\033[0m"

LATEST_HASH=`git log --pretty=format:'%h' -n 1`

QUESTION_FLAG="${GREEN}?"
WARNING_FLAG="${YELLOW}!"
NOTICE_FLAG="${CYAN}❯"

ADJUSTMENTS_MSG="${QUESTION_FLAG} ${CYAN}Now you can make adjustments to ${WHITE}CHANGELOG.md${CYAN}. Then press enter to continue."
PUSHING_MSG="${NOTICE_FLAG} Pushing new version to the ${WHITE}origin${CYAN}..."

RELEASE_NOTE=""
is_minor=false

while true; do
  case "$1" in
    -m | --message ) RELEASE_NOTE=$2; shift; shift ;;
    --minor ) is_minor=true; shift ;;
    * ) break ;;
  esac
done

# $1 : version
# $2 : release note
function tag {
  if [ -z "$2" ]; then
    # Default release note
    git tag -a "$1" -m "Tag version $1."
  else
    # Custom release note
    git tag -a "$1" -m "$2"
  fi
}

# Check if the current branch is master, otherwise exit
CURRENT_BRANCH=`git rev-parse --abbrev-ref HEAD`
DEFAULT_BRANCH="develop"
if [ "$CURRENT_BRANCH" != "$DEFAULT_BRANCH" ] && [ "$is_minor" != true ]; then
  echo -ne "${WARNING_FLAG} You must be in the ${WHITE}${DEFAULT_BRANCH}${YELLOW} branch to call the script !";
  exit 1;
fi


VERSION_FILE="VERSION"
has_VERSION=true
if [ ! -f ${VERSION_FILE} ]; then
  has_VERSION=false
    echo -ne "${WARNING_FLAG} No ${WHITE}${VERSION_FILE}${YELLOW} or ${WHITE}${PY_VERSION_FILE}${YELLOW} file found in the current directory !";
    exit 1;
fi

n_lines=`wc -l < ${VERSION_FILE}`
if [ ${n_lines} -eq 1 ] ; then
  PWD_STRING=(`pwd | tr '/' ' '`)
  PY_VERSION_FILE="${PWD_STRING[@]:(-1)}/_version.py"
  has_py_version=true
fi

BASE_STRING=`tail -n 1 ${VERSION_FILE} | awk -F= '{print $2}'`
if [ "$has_py_version" = true ] ; then
  BASE_STRING=`echo "${BASE_STRING//\"}"`
else
  BASE_STRING=`echo "${BASE_STRING//\'}"`
fi

# Remove leading/trailing spaces (see https://stackoverflow.com/a/40962059)
BASE_STRING=`echo ${BASE_STRING} | xargs echo -n`

BASE_LIST=(`echo $BASE_STRING | tr '.' ' '`)

V_MAJOR=${BASE_LIST[0]}
V_MINOR=${BASE_LIST[1]}
V_PATCH=${BASE_LIST[2]}
echo -e "${NOTICE_FLAG} Current version: ${WHITE}$BASE_STRING"
echo -e "${NOTICE_FLAG} Latest commit hash: ${WHITE}$LATEST_HASH"

if [ "$is_minor" = true ] ; then
  V_MINOR=$((V_MINOR + 1))
  V_PATCH=0
else
  V_PATCH=$((V_PATCH + 1))
fi
SUGGESTED_VERSION="$V_MAJOR.$V_MINOR.$V_PATCH"

echo -ne "${QUESTION_FLAG} ${CYAN}Enter a version number [${WHITE}$SUGGESTED_VERSION${CYAN}]: "
read INPUT_STRING
if [ "$INPUT_STRING" = "" ]; then
    INPUT_STRING=$SUGGESTED_VERSION
fi
# Check if your current source is not already tagged by using current hash
GIT_COMMIT=`git rev-parse HEAD`
NEEDS_TAG=`git describe --contains $GIT_COMMIT`
# Only tag if no tag already (would be better if the git describe command above could have a silent option)
if [ -n "$NEEDS_TAG" ]; then
    echo -e "${WARNING_FLAG} Current code is already released."
    exit 0
fi
echo -e "${NOTICE_FLAG} Will set new version to be ${WHITE}$INPUT_STRING"

if [ "$has_py_version" = true ] ; then
  echo __version__ = \"${INPUT_STRING}\" > ${VERSION_FILE}
else
  echo "character(len=:),allocatable :: GITFLOW_VERSION" > ${VERSION_FILE}
  echo "GITFLOW_VERSION='$INPUT_STRING'" >> ${VERSION_FILE}
fi


echo "## $INPUT_STRING ($NOW)" > tmpfile
git log --pretty=format:"  - %s" "$BASE_STRING"...HEAD >> tmpfile
echo "" >> tmpfile
echo "" >> tmpfile
cat CHANGELOG.md >> tmpfile
mv tmpfile CHANGELOG.md
echo -e "$ADJUSTMENTS_MSG"
read
echo -e "$PUSHING_MSG"

if [ "$has_py_version" = true ] ; then
  git add CHANGELOG.md ${PY_VERSION_FILE}
else
  git add CHANGELOG.md git-flow-version
fi

if [ -d "changelog" ]; then
  scripts/create_netlify_changelog.py -i CHANGELOG.md --folder changelog
  git add $(git ls-files -o --exclude-standard changelog)
fi

git commit -m "Version bump ${INPUT_STRING}"

if [ "$is_minor" = true ] ; then
  git checkout master
  git merge --no-ff $CURRENT_BRANCH
  tag "${INPUT_STRING}" "${RELEASE_NOTE}"
  git push origin master
  git checkout develop
  git rebase master
  git push origin develop
  git push origin --tags
else
  tag "${INPUT_STRING}" "${RELEASE_NOTE}"
  git push origin develop
  git checkout master
  git rebase develop
  git push origin master
  git push origin --tags
  git checkout develop
fi

CURRENT_BRANCH=`git rev-parse --abbrev-ref HEAD`
echo -e "${NOTICE_FLAG} Finished. You're now in the ${WHITE}${CURRENT_BRANCH}${CYAN} branch."
