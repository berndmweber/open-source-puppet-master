#!/bin/bash
# This has been tested on Ubuntu 12.04 LTS - Precise Pangolin only
#

# Escape code
esc=`echo -en "\033"`

# Set colors
cc_red="${esc}[0;31m"
cc_green="${esc}[0;32m"
cc_yellow="${esc}[0;33m"
cc_blue="${esc}[0;34m"
cc_normal=`echo -en "${esc}[m\017"`

# Find executables
CAT=`which cat`
CURL=`which curl`

# Some global system variables
ISSUE="/etc/issue" # For OS and version detection

# Set some global variables
SCRIPTDIR="/root"
LOGDIR="/var/log"
LOGFILE="pm_instantiate.log"
LOG="${LOGDIR}/${LOGFILE}"
GITHUBREPO="https://github.com/bernd-copperfroghosting/open-source-puppet-master.git"
TEMPPUPPETDIR="puppet"
VERBOSE=0
DATE=`date`

# Define correct usage
usage ()
{
  echo "${cc_blue}${0}${cc_normal} [options]"
  echo
  echo "  --verbose [0|1|2]"
  echo "  --logdir  <some writable directory>"
  echo "  --logfile <log file name>"
  echo
  echo " ${cc_blue}Auto-detected options. These do not normally have to be provided.${cc_normal}"
  echo "  --os    [${cc_yellow}Ubuntu${cc_blue}|${cc_yellow}CentOS${cc_normal}]"
  echo "  --osversion [${cc_yellow}12.04${cc_blue}|${cc_yellow}6${cc_normal}]"
  echo
  echo " e.g. ${0} --os Ubuntu --osversion 12.04 --logdir /tmp --logfile mylog.txt"
  echo
  exit 1
}

# Check the parameters
while [ $# -gt 0 ]; do
  case "${1}" in
    --os)
      if [ -n "${2}" ]; then
        OS=${2}
        shift
      else
        usage
      fi
      ;;
    --osversion)
      if [ -n "${2}" ]; then
        OSVERSION=${2}
        shift
      else
        usage
      fi
      ;;
    --verbose)
      if [ -n "${2}" ]; then
        VERBOSE=${2}
        shift
      else
        usage
      fi
      ;;
    --logdir)
      if [ -n "${2}" ]; then
        LOGDIR=${2}
        shift
      else
        usage
      fi
      ;;
    --logfile)
      if [ -n "${2}" ]; then
        LOGFILE=${2}
        shift
      else
        usage
      fi
      ;;
    *)
      usage
      ;;
  esac
  shift
done

# Initialize log
touch ${LOG}
echo "${DATE}" > ${LOG}
echo >> ${LOG}

# Evaluate the /etc/issue file to automatically extract OS
eval_issue_os ()
{
  if [ ${VERBOSE} -gt 2 ]; then
  echo "${cc_yellow}eval_issue_os \$1: ${1}${cc_normal}"
  fi
  if [ -n "${1}" ]; then
    case "${1}" in
      Ubuntu)
        OS="ubuntu"
        ;;
      CentOS)
        OS="centos"
        ;;
      *)
        exit 0
        ;;
    esac
  fi
  return 1
}
# Evaluate the /etc/issue file to automatically extract OS version
eval_issue_osversion ()
{
  if [ ${VERBOSE} -gt 2 ]; then
  echo "${cc_yellow}eval_issue_osversion \$1: ${1}${cc_normal}"
  fi
  if [ -n "${1}" ]; then
    case "${1}" in
      Ubuntu)
        OSVERSION="${2:0:5}"
        if [ ${VERBOSE} -gt 2 ]; then
      echo "${cc_yellow}version \$2: ${2}${cc_normal}"
    fi
        ;;
      CentOS)
        OSVERSION="${3:0:1}"
        if [ ${VERBOSE} -gt 2 ]; then
      echo "${cc_yellow}version \$3: ${3}${cc_normal}"
    fi
        ;;
      *)
        exit 0
        ;;
    esac
  fi
  return 1
}


# Make sure we have a valid OS
eval_os ()
{
  if [ ${VERBOSE} -gt 2 ]; then
  echo "${cc_yellow}eval_os \$1: ${1}${cc_normal}"
  fi
  if [ -n "${1}" ]; then
  case "${OS}" in
    Ubuntu)
    OS="ubuntu"
    ;;
    ubuntu)
    # good
    ;;
    CentOS)
    OS="centos"
    ;;
    centos)
    # good
    ;;
    *)
    return 0
    ;;
  esac
  fi
  return 1
}

# Make sure the OS-version matches the OS and is supported
eval_osversion ()
{
  if [ ${VERBOSE} -gt 2 ]; then
  echo "${cc_yellow}eval_osversion${cc_normal}"
  fi
  case "${OS}" in
    ubuntu)
    case "${OSVERSION}" in
      12.04)
      # good
      ;;
      *)
        return 0
      ;;
    esac
    ;;
    centos)
    case "${OSVERSION}" in
      6)
      # good
      ;;
      *)
        return 0
      ;;
    esac
    ;;
    *)
      return 0
    ;;
  esac
  return 1
}

# Grab information from /etc/issue
if [ ! -z "$CAT}" ]; then
  if [ -e "${ISSUE}" ]; then
    TEMPOS=`${CAT} ${ISSUE}`
    if [ ${VERBOSE} -gt 1 ]; then
    echo "${cc_yellow}TEMPOS:${cc_green}${TEMPOS}${cc_normal}"
    fi
  else
    if [ ${VERBOSE} -gt 0 ]; then
      echo "${cc_red}Could not find '${cc_yellow}${ISSUE}${cc_red}' file${cc_normal}"
  fi
  fi
else
  if [ ${VERBOSE} -gt 0 ]; then
    echo "${cc_red}Could not find '${cc_yellow}cat${cc_red}' executable${cc_normal}"
  fi
fi

# Make sure we have all answers. Otherwise ask the user for input on missing information
if [ -z "${OS}" ]; then
  foundos=0
  if [ ${VERBOSE} -gt 2 ]; then
  echo "${cc_yellow}OS not found${cc_normal}"
  fi
  eval_issue_os ${TEMPOS}
  foundos=$?
  if [ ${VERBOSE} -gt 1 ]; then
  echo "${cc_yellow}foundos:${cc_green}${foundos}${cc_normal}"
  fi
else
  foundos=1
  if [ ${VERBOSE} -gt 2 ]; then
  echo "${cc_green}OS found${cc_normal}"
  fi
fi
if [ ${foundos} -eq 1 ]; then
  if [ ${VERBOSE} -gt 2 ]; then
  echo "${cc_green}foundos is true${cc_normal}"
  fi
  eval_os ${OS}
  validos=$?
  if [ ${validos} -eq 0 ]; then
    if [ ${VERBOSE} -gt 2 ]; then
      echo "${cc_red}invalid OS found: ${cc_yellow}${OS}${cc_normal}"
    fi
    foundos=0
  fi
fi
if [ ${foundos} -eq 0 ]; then
  echo " ${cc_blue}Please provide a valid OS (Distribution) for this script."
  echo " Valid Distributions are:"
  echo
  echo "  * ${cc_yellow}Ubuntu${cc_blue}"
  echo "  * ${cc_yellow}CentOS${cc_normal}"
  echo
  echo -n " > "
  read replyos
  if [ ${VERBOSE} -gt 1 ]; then
  echo "${cc_yellow}replyos: ${cc_green}${replyos}${cc_normal}"
  fi
  if [ -z "${replyos}" ]; then
    echo "${cc_red}No valid OS was given. Exiting now.${cc_normal}"
    exit 1
  else
    OS=${replyos}
  fi
  eval_os ${OS}
  validos=$?
  if [ ${validos} -eq 0 ]; then
    echo "${cc_red}No valid OS was given. Exiting now.${cc_normal}"
    exit 1
  fi
fi
if [ -z "${OSVERSION}" ]; then
  foundosversion=0
  if [ ${VERBOSE} -gt 2 ]; then
  echo "${cc_yellow}OS version not found${cc_normal}"
  fi
  eval_issue_osversion ${TEMPOS}
  foundosversion=$?
  if [ ${VERBOSE} -gt 1 ]; then
  echo "${cc_yellow}foundosversion: ${cc_green}${foundosversion}${cc_normal}"
  fi
else
  foundosversion=1
  if [ ${VERBOSE} -gt 2 ]; then
  echo "${cc_green}OS version found: ${foundosversion}${cc_normal}"
  fi
fi
if [ ${foundosversion} -eq 1 ]; then
  if [ ${VERBOSE} -gt 2 ]; then
  echo "${cc_green}foundosversion is true${cc_normal}"
  fi
  eval_osversion ${OS}
  validosversion=$?
  if [ ${validosversion} -eq 0 ]; then
    if [ ${VERBOSE} -gt 2 ]; then
      echo "${cc_red}invalid OS found: ${cc_yellow}${OSVERSION}${cc_normal}"
    fi
    foundosversion=0
  fi
fi
if [ ${foundosversion} -eq 0 ]; then
  echo " ${cc_blue}Please provide a valid OS Version for ${OS} for this script."
  echo " Valid Versions are:"
  echo
  case ${OS} in
    ubuntu)
      echo "  * ${cc_yellow}12.04${cc_blue}"
      ;;
    centos)
      echo "  * ${cc_yellow}6${cc_normal}"
      ;;
  esac
  echo
  echo -n " > "
  read replyosversion
  if [ ${VERBOSE} -gt 1 ]; then
  echo "${cc_yellow}replyosversion: ${cc_green}${replyosversion}${cc_normal}"
  fi
  if [ -z "${replyosversion}" ]; then
    echo "${cc_red}No valid OS version was given. Exiting now.${cc_normal}"
    exit 1
  else
    OSVERSION=${replyosversion}
  fi
  eval_osversion ${OSVERSION}
  validosversion=$?
  if [ ${validosversion} -eq 0 ]; then
    echo "${cc_red}No valid OS version was given. Exiting now.${cc_normal}"
    exit 1
  fi
fi

# Now some OS specific definitions
case ${OS} in
  ubuntu)
    REPOPATH="apt.puppetlabs.com"
    REPOFILE="puppetlabs-release-precise.deb"
    REPOINSTALL="dpkg -i"
    REPOSEXEC="apt-get"
    REPOUPDATE="${REPOSEXEC} update"
    PKGINSTALL="${REPOSEXEC} install -y"
    BASEPACKAGES="puppet-common git-core"
    ;;
  *)
    # Final fallback
    echo "${cc_red}${OS} not supported. Exiting!${cc_normal}"
    exit 1
  ;;
esac

# Some debug output
print_params ()
{
  echo " ${cc_blue}Configured Params" >> ${LOG}
  echo " OS:      ${cc_green}${OS}${cc_blue}" >> ${LOG}
  echo " OSVERSION:   ${cc_green}${OSVERSION}${cc_blue}" >> ${LOG}
  echo " VERBOSE:   ${cc_green}${VERBOSE}${cc_blue}" >> ${LOG}
  echo >> ${LOG}
  echo " SCRIPTDIR:   ${cc_green}${SCRIPTDIR}${cc_blue}" >> ${LOG}
  echo " GITHUBREPO:    ${cc_green}${GITHUBREPO}${cc_blue}" >> ${LOG}
  echo " TEMPPUPPETDIR:   ${cc_green}${TEMPPUPPETDIR}${cc_blue}" >> ${LOG}
  echo >> ${LOG}
  echo " REPOPATH:    ${cc_green}${REPOPATH}${cc_blue}" >> ${LOG}
  echo " REPOFILE:    ${cc_green}${REPOFILE}${cc_blue}" >> ${LOG}
  echo " REPOINSTALL:   ${cc_green}${REPOINSTALL}${cc_blue}" >> ${LOG}
  echo " REPOSEXEC:   ${cc_green}${REPOSEXEC}${cc_blue}" >> ${LOG}
  echo " REPOUPDATE:    ${cc_green}${REPOUPDATE}${cc_blue}" >> ${LOG}
  echo " PKGINSTALL:    ${cc_green}${PKGINSTALL}${cc_blue}" >> ${LOG}
  echo " BASEPACKAGES:    ${cc_green}${BASEPACKAGES}${cc_blue}" >> ${LOG}
  echo >> ${LOG}
  echo " CAT:     ${cc_green}${CAT}${cc_blue}" >> ${LOG}
  echo " CURL:      ${cc_green}${CURL}${cc_normal}" >> ${LOG}
  echo >> ${LOG}
}

print_params

if [ ${VERBOSE} -gt 0 ]; then
  cat ${LOG}
fi

# Enter the required directory and get started
cd $SCRIPTDIR

# Configure Puppetlabs repo
echo -e " ${cc_blue}Downloading Puppetlabs repository information...${cc_normal}"
${CURL} -s -S -o ${REPOFILE} http://${REPOPATH}/${REPOFILE} >> ${LOG}
${REPOINSTALL} ${REPOFILE} >> ${LOG}
echo " ${cc_green}Done.${cc_normal}"
echo

# Update the repository information
echo " ${cc_blue}Updaing APT with new information...${cc_normal}"
${REPOUPDATE} >> ${LOG}
echo " ${cc_green}Done.${cc_normal}"
echo

# Install a basic puppet master configuration
echo " ${cc_blue}Installing ${cc_yellow}${BASEPACKAGES}${cc_blue}...${cc_normal}"
${PKGINSTALL} ${BASEPACKAGES} >> ${LOG}
echo " ${cc_green}Done.${cc_normal}"
echo

# Grab the GitHub puppet configuration
echo " ${cc_blue}Downloading puppet master configuration from ${cc_yellow}GitHub${cc_blue} for final provisioning...${cc_normal}"
git clone ${GITHUBREPO} ${TEMPPUPPETDIR} --progress &>> ${LOG}
echo " ${cc_green}Done.${cc_normal}"
echo

# Install Puppet master through puppet base installation
echo " ${cc_blue}Install Puppet master through puppet base installation...${cc_normal}"
puppet apply --modulepath=${SCRIPTDIR}/${TEMPPUPPETDIR}/modules -e "include puppet" >> ${LOG}
echo " ${cc_green}Done.${cc_normal}"
echo
