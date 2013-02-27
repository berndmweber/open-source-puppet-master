#!/bin/bash -l
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
TEE="`which tee` -a"
GREP=`which grep`
DATE=`which date`
ECHO="echo -e"

# Some usage feedback
${ECHO}
${ECHO} "${cc_blue}#####################################################${cc_normal}"
${ECHO} "${cc_blue} Open source ${cc_yellow}PUPPET MASTER${cc_blue} auto-instantiation script${cc_normal}"
${ECHO} "${cc_blue}#####################################################${cc_normal}"
${ECHO} "${cc_blue} This script will download and install a basic${cc_normal}"
${ECHO} "${cc_blue} puppet master and uses puppet to self instantiate.${cc_normal}"
${ECHO}
${ECHO} "${cc_blue} This code is licensed under ${cc_yellow}GPL v2${cc_normal}"
${ECHO} "${cc_blue} Please contribute!${cc_normal}"
${ECHO} "${cc_blue}#####################################################${cc_normal}"
${ECHO}

# Some global system variables
ISSUE="/etc/issue" # For OS and version detection

# Set some global variables
SCRIPTDIR="/etc"
PUPPETDIR="/etc/puppet"
PUPPETINSTALLCONFIG="modules/puppet/tests/bootstrap.pp"
LOGDIR="/var/log"
LOGFILE="pm_instantiate.log"
LOG="${LOGDIR}/${LOGFILE}"
GITHUBREPO="https://github.com/bernd-copperfroghosting/open-source-puppet-master.git"
TEMPPUPPETDIR="puppet"
VERBOSE=0
CURRENT_DATE=`${DATE}`
INITIAL_TIME=`${DATE} +"%s"`

# Define correct usage
usage ()
{
  ${ECHO} " ${cc_blue}Usage:${cc_normal}"
  ${ECHO}
  ${ECHO} " ${0} [options]"
  ${ECHO}
  ${ECHO} " ${cc_blue}Options:${cc_normal}"
  ${ECHO} "  --verbose [${cc_yellow}0${cc_normal}|${cc_yellow}1${cc_normal}|${cc_yellow}2${cc_normal}]                   Choose a verbose level"
  ${ECHO} "  --logdir <some writable directory>  Define a log directory"
  ${ECHO} "  --logfile <log file name>           Define a log file name"
  ${ECHO} "  --help                              This usage information"
  ${ECHO}
  ${ECHO} " ${cc_blue}Auto-detected options. These do not normally have to be provided.${cc_normal}"
  ${ECHO} "  --os [${cc_yellow}Ubuntu${cc_normal}|${cc_yellow}CentOS${cc_normal}]"
  ${ECHO} "  --osversion [${cc_yellow}12.04${cc_normal}|${cc_yellow}6${cc_normal}]"
  ${ECHO}
  ${ECHO} " e.g. ${0} --os Ubuntu --osversion 12.04 --logdir /tmp --logfile mylog.txt --verbose 2"
  ${ECHO}
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
    --help)
      usage
      exit 0
      ;;
    *)
      usage
      ;;
  esac
  shift
done

# Initialize log
touch ${LOG}
${ECHO} "${CURRENT_DATE}" > ${LOG}
${ECHO} >> ${LOG}

calculate_exec_time ()
{
  now=`${DATE} +"%s"`
  
  let etime=${now}-${INITIAL_TIME}
  let ehours=${etime}/60/60
  let eminutes=${etime}/60
  let eseconds=${etime}%60
    
  ${ECHO} " ${cc_blue}Execution time was: ${cc_yellow}${ehours}${cc_blue} hours, ${cc_yellow}${eminutes}${cc_blue} minutes, ${cc_yellow}${eseconds}${cc_blue} seconds" >> ${LOG}
}

# Evaluate the /etc/issue file to automatically extract OS
eval_issue_os ()
{
  if [ ${VERBOSE} -gt 2 ]; then
    ${ECHO} "${cc_yellow}eval_issue_os \$1: ${1}${cc_normal}"
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
    ${ECHO} "${cc_yellow}eval_issue_osversion \$1: ${1}${cc_normal}" | ${TEE} ${LOG}
  fi
  if [ -n "${1}" ]; then
    case "${1}" in
      Ubuntu)
        OSVERSION="${2:0:5}"
        if [ ${VERBOSE} -gt 2 ]; then
          ${ECHO} "${cc_yellow}version \$2: ${2}${cc_normal}" | ${TEE} ${LOG}
        fi
        ;;
      CentOS)
        OSVERSION="${3:0:1}"
        if [ ${VERBOSE} -gt 2 ]; then
          ${ECHO} "${cc_yellow}version \$3: ${3}${cc_normal}" | ${TEE} ${LOG}
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
    ${ECHO} "${cc_yellow}eval_os \$1: ${1}${cc_normal}" | ${TEE} ${LOG}
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
    ${ECHO} "${cc_yellow}eval_osversion${cc_normal}" | ${TEE} ${LOG}
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
      ${ECHO} "${cc_yellow}TEMPOS:${cc_green}${TEMPOS}${cc_normal}" | ${TEE} ${LOG}
    fi
  else
    if [ ${VERBOSE} -gt 0 ]; then
      ${ECHO} "${cc_red}Could not find '${cc_yellow}${ISSUE}${cc_red}' file${cc_normal}" | ${TEE} ${LOG}
    fi
  fi
else
  if [ ${VERBOSE} -gt 0 ]; then
    ${ECHO} "${cc_red}Could not find '${cc_yellow}cat${cc_red}' executable${cc_normal}" | ${TEE} ${LOG}
  fi
fi

# Make sure we have all answers. Otherwise ask the user for input on missing information
if [ -z "${OS}" ]; then
  foundos=0
  if [ ${VERBOSE} -gt 2 ]; then
    ${ECHO} "${cc_yellow}OS not found${cc_normal}" | ${TEE} ${LOG}
  fi
  eval_issue_os ${TEMPOS}
  foundos=$?
  if [ ${VERBOSE} -gt 1 ]; then
    ${ECHO} "${cc_yellow}foundos:${cc_green}${foundos}${cc_normal}" | ${TEE} ${LOG}
  fi
else
  foundos=1
  if [ ${VERBOSE} -gt 2 ]; then
    ${ECHO} "${cc_green}OS found${cc_normal}" | ${TEE} ${LOG}
  fi
fi
if [ ${foundos} -eq 1 ]; then
  if [ ${VERBOSE} -gt 2 ]; then
    ${ECHO} "${cc_green}foundos is true${cc_normal}" | ${TEE} ${LOG}
  fi
  eval_os ${OS}
  validos=$?
  if [ ${validos} -eq 0 ]; then
    if [ ${VERBOSE} -gt 2 ]; then
      ${ECHO} "${cc_red}invalid OS found: ${cc_yellow}${OS}${cc_normal}" | ${TEE} ${LOG}
    fi
    foundos=0
  fi
fi
if [ ${foundos} -eq 0 ]; then
  ${ECHO} " ${cc_blue}Please provide a valid OS (Distribution) for this script." | ${TEE} ${LOG}
  ${ECHO} " Valid Distributions are:" | ${TEE} ${LOG}
  ${ECHO} | ${TEE} ${LOG}
  ${ECHO} "  * ${cc_yellow}Ubuntu${cc_blue}" | ${TEE} ${LOG}
  ${ECHO} "  * ${cc_yellow}CentOS${cc_normal}" | ${TEE} ${LOG}
  ${ECHO} | ${TEE} ${LOG}
  ${ECHO} -n " > " | ${TEE} ${LOG}
  read replyos
  if [ ${VERBOSE} -gt 1 ]; then
    ${ECHO} "${cc_yellow}replyos: ${cc_green}${replyos}${cc_normal}" | ${TEE} ${LOG}
  fi
  if [ -z "${replyos}" ]; then
    ${ECHO} "${cc_red}No valid OS was given. Exiting now.${cc_normal}" | ${TEE} ${LOG}
    exit 1
  else
    OS=${replyos}
  fi
  eval_os ${OS}
  validos=$?
  if [ ${validos} -eq 0 ]; then
    ${ECHO} "${cc_red}No valid OS was given. Exiting now.${cc_normal}" | ${TEE} ${LOG}
    exit 1
  fi
fi
if [ -z "${OSVERSION}" ]; then
  foundosversion=0
  if [ ${VERBOSE} -gt 2 ]; then
    ${ECHO} "${cc_yellow}OS version not found${cc_normal}" | ${TEE} ${LOG}
  fi
  eval_issue_osversion ${TEMPOS}
  foundosversion=$?
  if [ ${VERBOSE} -gt 1 ]; then
    ${ECHO} "${cc_yellow}foundosversion: ${cc_green}${foundosversion}${cc_normal}" | ${TEE} ${LOG}
  fi
else
  foundosversion=1
  if [ ${VERBOSE} -gt 2 ]; then
    ${ECHO} "${cc_green}OS version found: ${foundosversion}${cc_normal}" | ${TEE} ${LOG}
  fi
fi
if [ ${foundosversion} -eq 1 ]; then
  if [ ${VERBOSE} -gt 2 ]; then
    ${ECHO} "${cc_green}foundosversion is true${cc_normal}" | ${TEE} ${LOG}
  fi
  eval_osversion ${OS}
  validosversion=$?
  if [ ${validosversion} -eq 0 ]; then
    if [ ${VERBOSE} -gt 2 ]; then
      ${ECHO} "${cc_red}invalid OS found: ${cc_yellow}${OSVERSION}${cc_normal}" | ${TEE} ${LOG}
    fi
    foundosversion=0
  fi
fi
if [ ${foundosversion} -eq 0 ]; then
  ${ECHO} " ${cc_blue}Please provide a valid OS Version for ${OS} for this script." | ${TEE} ${LOG}
  ${ECHO} " Valid Versions are:" | ${TEE} ${LOG}
  ${ECHO} | ${TEE} ${LOG}
  case ${OS} in
    ubuntu)
      ${ECHO} "  * ${cc_yellow}12.04${cc_blue}" | ${TEE} ${LOG}
      ;;
    centos)
      ${ECHO} "  * ${cc_yellow}6${cc_normal}" | ${TEE} ${LOG}
      ;;
  esac
  ${ECHO} | ${TEE} ${LOG}
  ${ECHO} -n " > " | ${TEE} ${LOG}
  read replyosversion
  if [ ${VERBOSE} -gt 1 ]; then
    ${ECHO} "${cc_yellow}replyosversion: ${cc_green}${replyosversion}${cc_normal}" | ${TEE} ${LOG}
  fi
  if [ -z "${replyosversion}" ]; then
    ${ECHO} "${cc_red}No valid OS version was given. Exiting now.${cc_normal}" | ${TEE} ${LOG}
    exit 1
  else
    OSVERSION=${replyosversion}
  fi
  eval_osversion ${OSVERSION}
  validosversion=$?
  if [ ${validosversion} -eq 0 ]; then
    ${ECHO} "${cc_red}No valid OS version was given. Exiting now.${cc_normal}" | ${TEE} ${LOG}
    exit 1
  fi
fi

# Now some OS specific definitions
case ${OS} in
  ubuntu)
    REPOPATH="apt.puppetlabs.com"
    REPOFILEBASE="puppetlabs-release"
    REPOFILE="${REPOFILEBASE}-precise.deb"
    REPOINSTALL="dpkg -i"
    REPOCHECK="dpkg --list"
    REPOINSTCHECK="ii  "
    REPOSEXEC="apt-get"
    REPOUPDATE="${REPOSEXEC} update"
    PKGINSTALL="${REPOSEXEC} install -y"
    BASEPACKAGES=("puppet-common" "git-core")
    ;;
  *)
    # Final fallback
    ${ECHO} "${cc_red}${OS} not supported. Exiting!${cc_normal}" | ${TEE} ${LOG}
    exit 1
  ;;
esac

repo_check ()
{
  if [ ${VERBOSE} -gt 0 ]; then
    rc=`${REPOCHECK} | ${GREP} "${REPOINSTCHECK}${1} "`
    rv=$?
    else
    ${REPOCHECK} | ${GREP} "${REPOINSTCHECK}${1} " >> ${LOG}
    rv=$?
  fi
  return ${rv}
}

# Some debug output
print_params ()
{
  OP=" ${cc_blue}Configured Params\n"
  OP=${OP}" OS:\t\t           ${cc_green}${OS}${cc_blue}\n"
  OP=${OP}" OSVERSION:\t      ${cc_green}${OSVERSION}${cc_blue}\n"
  OP=${OP}" VERBOSE:\t        ${cc_green}${VERBOSE}${cc_blue}\n"
  OP=${OP}"\n"
  OP=${OP}" SCRIPTDIR:\t      ${cc_green}${SCRIPTDIR}${cc_blue}\n"
  OP=${OP}" GITHUBREPO:\t     ${cc_green}${GITHUBREPO}${cc_blue}\n"
  OP=${OP}" TEMPPUPPETDIR:\t  ${cc_green}${TEMPPUPPETDIR}${cc_blue}\n"
  OP=${OP}"\n"
  OP=${OP}" REPOPATH:\t       ${cc_green}${REPOPATH}${cc_blue}\n"
  OP=${OP}" REPOFILEBASE:\t   ${cc_green}${REPOFILEBASE}${cc_blue}\n"
  OP=${OP}" REPOFILE:\t       ${cc_green}${REPOFILE}${cc_blue}\n"
  OP=${OP}" REPOINSTALL:\t    ${cc_green}${REPOINSTALL}${cc_blue}\n"
  OP=${OP}" REPOCHECK:\t      ${cc_green}${REPOCHECK}${cc_blue}\n"
  OP=${OP}" REPOINSTCHECK:\t  ${cc_green}${REPOINSTCHECK}${cc_blue}\n"
  OP=${OP}" REPOSEXEC:\t      ${cc_green}${REPOSEXEC}${cc_blue}\n"
  OP=${OP}" REPOUPDATE:\t     ${cc_green}${REPOUPDATE}${cc_blue}\n"
  OP=${OP}" PKGINSTALL:\t     ${cc_green}${PKGINSTALL}${cc_blue}\n"
  OP=${OP}" BASEPACKAGES:\t   ${cc_green}${BASEPACKAGES}${cc_blue}\n"
  OP=${OP}"\n"
  OP=${OP}" CAT:\t\t          ${cc_green}${CAT}${cc_blue}\n"
  OP=${OP}" CURL:\t\t         ${cc_green}${CURL}${cc_blue}\n"
  OP=${OP}" TEE:\t\t          ${cc_green}${TEE}${cc_normal}\n"
    
  if [ -n "${1}" ]; then
    ${ECHO} ${OP} >> ${1}
  else
    ${ECHO} ${OP}
  fi
}

print_params ${LOG}

if [ ${VERBOSE} -gt 0 ]; then
  print_params
fi

# Enter the required directory and get started
cd $SCRIPTDIR

# Configure Puppetlabs repo
${ECHO} " ${cc_blue}Downloading ${cc_yellow}Puppetlabs${cc_blue} repository information...${cc_normal}" | ${TEE} ${LOG}
if [ ${VERBOSE} -lt 1 ]; then
  silent="-s -S"
fi
if [ ! -e "${REPOFILE}" ]; then
	dl="${CURL} ${silent} -o /tmp/${REPOFILE} http://${REPOPATH}/${REPOFILE}"
	if [ ${VERBOSE} -gt 2 ]; then
	  ${ECHO} "${dl}" | ${TEE} ${LOG}
	fi
	if [ ${VERBOSE} -gt 0 ]; then
	  ${dl} &>1 | ${TEE} ${LOG}
	else
	  ${dl} >> ${LOG}
	fi
else
  ${ECHO} " ${cc_green}Skipping since ${cc_yellow}${REPOFILE}${cc_green} already exists${cc_normal}" | ${TEE} ${LOG}
fi
repo_check ${REPOFILEBASE}
if [ "$?" -gt 0 ]; then
	rinstall="${REPOINSTALL} /tmp/${REPOFILE}"
	if [ ${VERBOSE} -gt 2 ]; then
	  ${ECHO} "${rinstall}" | ${TEE} ${LOG}
	fi
	if [ ${VERBOSE} -gt 0 ]; then
	  ${rinstall} &>1 | ${TEE} ${LOG}
	else
	  ${rinstall} >> ${LOG}
	fi
else
  ${ECHO} " ${cc_green}Skipping since ${cc_yellow}${REPOFILEBASE}${cc_green} is already installed${cc_normal}" | ${TEE} ${LOG}
fi
${ECHO} " ${cc_green}Done.${cc_normal}" | ${TEE} ${LOG}
${ECHO} | ${TEE} ${LOG}

# Update the repository information
${ECHO} " ${cc_blue}Updaing ${cc_yellow}APT${cc_blue} with new information...${cc_normal}" | ${TEE} ${LOG}
if [ ${VERBOSE} -gt 2 ]; then
  ${ECHO} "${REPOUPDATE}" | ${TEE} ${LOG}
fi
if [ ${VERBOSE} -gt 0 ]; then
  ${REPOUPDATE} &>1 | ${TEE} ${LOG}
else
  ${REPOUPDATE} >> ${LOG}
fi
${ECHO} " ${cc_green}Done.${cc_normal}" | ${TEE} ${LOG}
${ECHO} | ${TEE} ${LOG}

# Install a basic puppet master configuration
${ECHO} " ${cc_blue}Installing ${cc_yellow}${BASEPACKAGES[@]}${cc_blue}...${cc_normal}" | ${TEE} ${LOG}
bpc=${#BASEPACKAGES[@]}
bpi=0
while [ ${bpi} -lt ${bpc} ]; do
	repo_check ${BASEPACKAGES[${bpi}]}
  if [ "$?" -gt 0 ]; then
		pkginst="${PKGINSTALL} ${BASEPACKAGES[${bpi}]}"
		if [ ${VERBOSE} -gt 2 ]; then
		  ${ECHO} "${pkginst}" | ${TEE} ${LOG}
		fi
		if [ ${VERBOSE} -gt 0 ]; then
		  ${pkginst} &>1 | ${TEE} ${LOG}
		else
		  ${pkginst} >> ${LOG}
		fi
  else
    ${ECHO} " ${cc_green}Skipping since ${cc_yellow}${BASEPACKAGES[${bpi}]}${cc_green} is already installed${cc_normal}" | ${TEE} ${LOG}
	fi
	((bpi++))
done
${ECHO} " ${cc_green}Done.${cc_normal}" | ${TEE} ${LOG}
${ECHO} | ${TEE} ${LOG}

# Grab the GitHub puppet configuration
${ECHO} " ${cc_blue}Downloading puppet master configuration from ${cc_yellow}GitHub${cc_blue} for final provisioning...${cc_normal}" | ${TEE} ${LOG}
if [ "${PUPPETDIR}" == "${SCRIPTDIR}/${TEMPPUPPETDIR}" ]; then
  if [ ! -e "${PUPPETDIR}/.git" ]; then
	  if [ ${VERBOSE} -gt 0 ]; then
	    ${ECHO} " ${cc_blue}Puppet dir ${cc_yellow}${PUPPETDIR}${cc_blue} already exists. Removing now.${cc_normal}" | ${TEE} ${LOG}
	  fi
	  rm -rvf ${PUPPETDIR} >> ${LOG}
  fi
fi
if [ ! -d "${TEMPPUPPETDIR}" ]; then
	dlghrepo="git clone --progress ${GITHUBREPO} ${TEMPPUPPETDIR}"
	if [ ${VERBOSE} -gt 2 ]; then
	  ${ECHO} "${dlghrepo}" | ${TEE} ${LOG}
	fi
	if [ ${VERBOSE} -gt 0 ]; then
	  ${dlghrepo} &>1 | ${TEE} ${LOG}
	else
	  ${dlghrepo} &>> ${LOG}
	fi
else
  ${ECHO} " ${cc_green}Skipping since ${cc_yellow}${GITHUBREPO}${cc_green} is already installed${cc_normal}" | ${TEE} ${LOG}
fi
${ECHO} " ${cc_green}Done.${cc_normal}" | ${TEE} ${LOG}
${ECHO} | ${TEE} ${LOG}

# Install Puppet master through puppet base installation
${ECHO} " ${cc_blue}Install ${cc_yellow}puppet master${cc_blue} through puppet base installation...${cc_normal}" | ${TEE} ${LOG}
PUPPET=`which puppet`
puppetize="${PUPPET} apply --modulepath=${SCRIPTDIR}/${TEMPPUPPETDIR}/modules ${SCRIPTDIR}/${TEMPPUPPETDIR}/${PUPPETINSTALLCONFIG}"
if [ ${VERBOSE} -gt 2 ]; then
  ${ECHO} "${puppetize}" | ${TEE} ${LOG}
fi
if [ ${VERBOSE} -gt 0 ]; then
  ${puppetize} &>1 | ${TEE} ${LOG}
else
  ${puppetize} >> ${LOG}
fi
${ECHO} " ${cc_green}Done.${cc_normal}" | ${TEE} ${LOG}
${ECHO} | ${TEE} ${LOG}

calculate_exec_time

${ECHO} "${cc_blue}#####################################################${cc_normal}" | ${TEE} ${LOG}
${ECHO} "${cc_blue} The install log can be found here: ${cc_yellow}${LOG}${cc_normal}"
${ECHO} "${cc_blue} Execution ${cc_green}finished${cc_blue}!${cc_normal}" | ${TEE} ${LOG}
${ECHO} "${cc_blue}#####################################################${cc_normal}" | ${TEE} ${LOG}
${ECHO} | ${TEE} ${LOG}
