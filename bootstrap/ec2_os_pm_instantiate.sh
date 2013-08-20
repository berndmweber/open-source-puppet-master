#!/bin/bash -l
# This has been tested on Ubuntu 12.04 LTS - Precise Pangolin only
#

# Find executables
CAT=`which cat`
CURL=`which curl`
TEE="`which tee` -a"
GREP=`which grep`
DATE=`which date`
ECHO="echo -e"

# Some usage feedback
${ECHO}
${ECHO} "#####################################################"
${ECHO} " Open source PUPPET MASTER auto-instantiation script"
${ECHO} "#####################################################"
${ECHO} " This script will download and install a basic"
${ECHO} " puppet master and uses puppet to self instantiate."
${ECHO}
${ECHO} " This code is licensed under GPL v2"
${ECHO} " Please contribute!"
${ECHO} "#####################################################"
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
GITHUBREPO="https://github.com/berndmweber/open-source-puppet-master.git"
TEMPPUPPETDIR="puppet"
VERBOSE=0
CURRENT_DATE=`${DATE}`
INITIAL_TIME=`${DATE} +"%s"`

# Define correct usage
usage ()
{
  ${ECHO} " Usage:"
  ${ECHO}
  ${ECHO} " ${0} [options]"
  ${ECHO}
  ${ECHO} " Options:"
  ${ECHO} "  --verbose [0|1|2]                   Choose a verbose level"
  ${ECHO} "  --logdir <some writable directory>  Define a log directory"
  ${ECHO} "  --logfile <log file name>           Define a log file name"
  ${ECHO} "  --help                              This usage information"
  ${ECHO}
  ${ECHO} " Auto-detected options. These do not normally have to be provided."
  ${ECHO} "  --os [Ubuntu|CentOS]"
  ${ECHO} "  --osversion [12.04|6]"
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
    
  ${ECHO} " Execution time was: ${ehours} hours, ${eminutes} minutes, ${eseconds} seconds" >> ${LOG}
}

# Evaluate the /etc/issue file to automatically extract OS
eval_issue_os ()
{
  if [ ${VERBOSE} -gt 1 ]; then
    ${ECHO} "eval_issue_os \$1: ${1}"
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
  if [ ${VERBOSE} -gt 1 ]; then
    ${ECHO} "eval_issue_osversion \$1: ${1}" | ${TEE} ${LOG}
  fi
  if [ -n "${1}" ]; then
    case "${1}" in
      Ubuntu)
        OSVERSION="${2:0:5}"
        if [ ${VERBOSE} -gt 1 ]; then
          ${ECHO} "version \$2: ${2}" | ${TEE} ${LOG}
        fi
        ;;
      CentOS)
        OSVERSION="${3:0:1}"
        if [ ${VERBOSE} -gt 1 ]; then
          ${ECHO} "version \$3: ${3}" | ${TEE} ${LOG}
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
  if [ ${VERBOSE} -gt 1 ]; then
    ${ECHO} "eval_os \$1: ${1}" | ${TEE} ${LOG}
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
  if [ ${VERBOSE} -gt 1 ]; then
    ${ECHO} "eval_osversion" | ${TEE} ${LOG}
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
      ${ECHO} "TEMPOS:${TEMPOS}" | ${TEE} ${LOG}
    fi
  else
    if [ ${VERBOSE} -gt 0 ]; then
      ${ECHO} "Could not find '${ISSUE}' file" | ${TEE} ${LOG}
    fi
  fi
else
  if [ ${VERBOSE} -gt 0 ]; then
    ${ECHO} "Could not find 'cat' executable" | ${TEE} ${LOG}
  fi
fi

# Make sure we have all answers. Otherwise ask the user for input on missing information
if [ -z "${OS}" ]; then
  foundos=0
  if [ ${VERBOSE} -gt 1 ]; then
    ${ECHO} "OS not found" | ${TEE} ${LOG}
  fi
  eval_issue_os ${TEMPOS}
  foundos=$?
  if [ ${VERBOSE} -gt 1 ]; then
    ${ECHO} "foundos:${foundos}" | ${TEE} ${LOG}
  fi
else
  foundos=1
  if [ ${VERBOSE} -gt 1 ]; then
    ${ECHO} "OS found" | ${TEE} ${LOG}
  fi
fi
if [ ${foundos} -eq 1 ]; then
  if [ ${VERBOSE} -gt 1 ]; then
    ${ECHO} "foundos is true" | ${TEE} ${LOG}
  fi
  eval_os ${OS}
  validos=$?
  if [ ${validos} -eq 0 ]; then
    if [ ${VERBOSE} -gt 1 ]; then
      ${ECHO} "invalid OS found: ${OS}" | ${TEE} ${LOG}
    fi
    foundos=0
  fi
fi
if [ ${foundos} -eq 0 ]; then
  ${ECHO} " Please provide a valid OS (Distribution) for this script." | ${TEE} ${LOG}
  ${ECHO} " Valid Distributions are:" | ${TEE} ${LOG}
  ${ECHO} | ${TEE} ${LOG}
  ${ECHO} "  * Ubuntu" | ${TEE} ${LOG}
  ${ECHO} "  * CentOS" | ${TEE} ${LOG}
  ${ECHO} | ${TEE} ${LOG}
  ${ECHO} -n " > " | ${TEE} ${LOG}
  read replyos
  if [ ${VERBOSE} -gt 1 ]; then
    ${ECHO} "replyos: ${replyos}" | ${TEE} ${LOG}
  fi
  if [ -z "${replyos}" ]; then
    ${ECHO} "No valid OS was given. Exiting now." | ${TEE} ${LOG}
    exit 1
  else
    OS=${replyos}
  fi
  eval_os ${OS}
  validos=$?
  if [ ${validos} -eq 0 ]; then
    ${ECHO} "No valid OS was given. Exiting now." | ${TEE} ${LOG}
    exit 1
  fi
fi
if [ -z "${OSVERSION}" ]; then
  foundosversion=0
  if [ ${VERBOSE} -gt 1 ]; then
    ${ECHO} "OS version not found" | ${TEE} ${LOG}
  fi
  eval_issue_osversion ${TEMPOS}
  foundosversion=$?
  if [ ${VERBOSE} -gt 1 ]; then
    ${ECHO} "foundosversion: ${foundosversion}" | ${TEE} ${LOG}
  fi
else
  foundosversion=1
  if [ ${VERBOSE} -gt 1 ]; then
    ${ECHO} "OS version found: ${foundosversion}" | ${TEE} ${LOG}
  fi
fi
if [ ${foundosversion} -eq 1 ]; then
  if [ ${VERBOSE} -gt 1 ]; then
    ${ECHO} "foundosversion is true" | ${TEE} ${LOG}
  fi
  eval_osversion ${OS}
  validosversion=$?
  if [ ${validosversion} -eq 0 ]; then
    if [ ${VERBOSE} -gt 1 ]; then
      ${ECHO} "invalid OS found: ${OSVERSION}" | ${TEE} ${LOG}
    fi
    foundosversion=0
  fi
fi
if [ ${foundosversion} -eq 0 ]; then
  ${ECHO} " Please provide a valid OS Version for ${OS} for this script." | ${TEE} ${LOG}
  ${ECHO} " Valid Versions are:" | ${TEE} ${LOG}
  ${ECHO} | ${TEE} ${LOG}
  case ${OS} in
    ubuntu)
      ${ECHO} "  * 12.04" | ${TEE} ${LOG}
      ;;
    centos)
      ${ECHO} "  * 6" | ${TEE} ${LOG}
      ;;
  esac
  ${ECHO} | ${TEE} ${LOG}
  ${ECHO} -n " > " | ${TEE} ${LOG}
  read replyosversion
  if [ ${VERBOSE} -gt 1 ]; then
    ${ECHO} "replyosversion: ${replyosversion}" | ${TEE} ${LOG}
  fi
  if [ -z "${replyosversion}" ]; then
    ${ECHO} "No valid OS version was given. Exiting now." | ${TEE} ${LOG}
    exit 1
  else
    OSVERSION=${replyosversion}
  fi
  eval_osversion ${OSVERSION}
  validosversion=$?
  if [ ${validosversion} -eq 0 ]; then
    ${ECHO} "No valid OS version was given. Exiting now." | ${TEE} ${LOG}
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
    ${ECHO} "${OS} not supported. Exiting!" | ${TEE} ${LOG}
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
  OP=" Configured Params\n"
  OP=${OP}" OS:\t\t           ${OS}\n"
  OP=${OP}" OSVERSION:\t      ${OSVERSION}\n"
  OP=${OP}" VERBOSE:\t        ${VERBOSE}\n"
  OP=${OP}"\n"
  OP=${OP}" SCRIPTDIR:\t      ${SCRIPTDIR}\n"
  OP=${OP}" GITHUBREPO:\t     ${GITHUBREPO}\n"
  OP=${OP}" TEMPPUPPETDIR:\t  ${TEMPPUPPETDIR}\n"
  OP=${OP}"\n"
  OP=${OP}" REPOPATH:\t       ${REPOPATH}\n"
  OP=${OP}" REPOFILEBASE:\t   ${REPOFILEBASE}\n"
  OP=${OP}" REPOFILE:\t       ${REPOFILE}\n"
  OP=${OP}" REPOINSTALL:\t    ${REPOINSTALL}\n"
  OP=${OP}" REPOCHECK:\t      ${REPOCHECK}\n"
  OP=${OP}" REPOINSTCHECK:\t  ${REPOINSTCHECK}\n"
  OP=${OP}" REPOSEXEC:\t      ${REPOSEXEC}\n"
  OP=${OP}" REPOUPDATE:\t     ${REPOUPDATE}\n"
  OP=${OP}" PKGINSTALL:\t     ${PKGINSTALL}\n"
  OP=${OP}" BASEPACKAGES:\t   ${BASEPACKAGES}\n"
  OP=${OP}"\n"
  OP=${OP}" CAT:\t\t          ${CAT}\n"
  OP=${OP}" CURL:\t\t         ${CURL}\n"
  OP=${OP}" TEE:\t\t          ${TEE}\n"
    
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
${ECHO} " Downloading Puppetlabs repository information..." | ${TEE} ${LOG}
if [ ${VERBOSE} -lt 1 ]; then
  silent="-s -S"
fi
if [ ! -e "${REPOFILE}" ]; then
	dl="${CURL} ${silent} -o /tmp/${REPOFILE} http://${REPOPATH}/${REPOFILE}"
	if [ ${VERBOSE} -gt 1 ]; then
	  ${ECHO} "${dl}" | ${TEE} ${LOG}
	fi
	if [ ${VERBOSE} -gt 0 ]; then
	  ${dl} &>1 | ${TEE} ${LOG}
	else
	  ${dl} >> ${LOG}
	fi
else
  ${ECHO} " Skipping since ${REPOFILE} already exists" | ${TEE} ${LOG}
fi
repo_check ${REPOFILEBASE}
if [ "$?" -gt 0 ]; then
	rinstall="${REPOINSTALL} /tmp/${REPOFILE}"
	if [ ${VERBOSE} -gt 1 ]; then
	  ${ECHO} "${rinstall}" | ${TEE} ${LOG}
	fi
	if [ ${VERBOSE} -gt 0 ]; then
	  ${rinstall} &>1 | ${TEE} ${LOG}
	else
	  ${rinstall} >> ${LOG}
	fi
else
  ${ECHO} " Skipping since ${REPOFILEBASE} is already installed" | ${TEE} ${LOG}
fi
${ECHO} " Done." | ${TEE} ${LOG}
${ECHO} | ${TEE} ${LOG}

# Update the repository information
${ECHO} " Updaing APT with new information..." | ${TEE} ${LOG}
if [ ${VERBOSE} -gt 1 ]; then
  ${ECHO} "${REPOUPDATE}" | ${TEE} ${LOG}
fi
if [ ${VERBOSE} -gt 0 ]; then
  ${REPOUPDATE} &>1 | ${TEE} ${LOG}
else
  ${REPOUPDATE} >> ${LOG}
fi
${ECHO} " Done." | ${TEE} ${LOG}
${ECHO} | ${TEE} ${LOG}

# Install a basic puppet master configuration
${ECHO} " Installing ${BASEPACKAGES[@]}..." | ${TEE} ${LOG}
bpc=${#BASEPACKAGES[@]}
bpi=0
while [ ${bpi} -lt ${bpc} ]; do
	repo_check ${BASEPACKAGES[${bpi}]}
  if [ "$?" -gt 0 ]; then
		pkginst="${PKGINSTALL} ${BASEPACKAGES[${bpi}]}"
		if [ ${VERBOSE} -gt 1 ]; then
		  ${ECHO} "${pkginst}" | ${TEE} ${LOG}
		fi
		if [ ${VERBOSE} -gt 0 ]; then
		  ${pkginst} &>1 | ${TEE} ${LOG}
		else
		  ${pkginst} >> ${LOG}
		fi
  else
    ${ECHO} " Skipping since ${BASEPACKAGES[${bpi}]} is already installed" | ${TEE} ${LOG}
	fi
	((bpi++))
done
${ECHO} " Done." | ${TEE} ${LOG}
${ECHO} | ${TEE} ${LOG}

# Grab the GitHub puppet configuration
${ECHO} " Downloading puppet master configuration from GitHub for final provisioning..." | ${TEE} ${LOG}
if [ "${PUPPETDIR}" == "${SCRIPTDIR}/${TEMPPUPPETDIR}" ]; then
  if [ ! -e "${PUPPETDIR}/.git" ]; then
	  if [ ${VERBOSE} -gt 0 ]; then
	    ${ECHO} " Puppet dir ${PUPPETDIR} already exists. Removing now." | ${TEE} ${LOG}
	  fi
	  rm -rvf ${PUPPETDIR} >> ${LOG}
  fi
fi
if [ ! -d "${TEMPPUPPETDIR}" ]; then
	dlghrepo="git clone --progress ${GITHUBREPO} ${TEMPPUPPETDIR}"
	if [ ${VERBOSE} -gt 1 ]; then
	  ${ECHO} "${dlghrepo}" | ${TEE} ${LOG}
	fi
	if [ ${VERBOSE} -gt 0 ]; then
	  ${dlghrepo} &>1 | ${TEE} ${LOG}
	else
	  ${dlghrepo} &>> ${LOG}
	fi
else
  ${ECHO} " Skipping since ${GITHUBREPO} is already installed" | ${TEE} ${LOG}
fi
${ECHO} " Done." | ${TEE} ${LOG}
${ECHO} | ${TEE} ${LOG}

# Install Puppet master through puppet base installation
${ECHO} " Install puppet master through puppet base installation..." | ${TEE} ${LOG}
PUPPET=`which puppet`
puppetize="${PUPPET} apply --modulepath=${SCRIPTDIR}/${TEMPPUPPETDIR}/modules ${SCRIPTDIR}/${TEMPPUPPETDIR}/${PUPPETINSTALLCONFIG}"
if [ ${VERBOSE} -gt 1 ]; then
  ${ECHO} "${puppetize}" | ${TEE} ${LOG}
fi
if [ ${VERBOSE} -gt 0 ]; then
  ${puppetize} &>1 | ${TEE} ${LOG}
else
  ${puppetize} >> ${LOG}
fi
${ECHO} " Done." | ${TEE} ${LOG}
${ECHO} | ${TEE} ${LOG}

calculate_exec_time

${ECHO} "#####################################################" | ${TEE} ${LOG}
${ECHO} " The install log can be found here: ${LOG}"
${ECHO} " Execution finished!" | ${TEE} ${LOG}
${ECHO} "#####################################################" | ${TEE} ${LOG}
${ECHO} | ${TEE} ${LOG}
