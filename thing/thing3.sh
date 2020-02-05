nvm_echo() {
  command printf %s\\n "$*" 2>/dev/null
}

nvm_has() {
  type "${1-}" >/dev/null 2>&1
}

nvm_version_greater() {
  command awk 'BEGIN {
    if (ARGV[1] == "" || ARGV[2] == "") exit(1)
    split(ARGV[1], a, /\./);
    split(ARGV[2], b, /\./);
    for (i=1; i<=3; i++) {
      if (a[i] && a[i] !~ /^[0-9]+$/) exit(2);
      if (b[i] && b[i] !~ /^[0-9]+$/) { exit(0); }
      if (a[i] < b[i]) exit(3);
      else if (a[i] > b[i]) exit(0);
    }
    exit(4)
  }' "${1#v}" "${2#v}"
}

nvm_version_greater_than_or_equal_to() {
  command awk 'BEGIN {
    if (ARGV[1] == "" || ARGV[2] == "") exit(1)
    split(ARGV[1], a, /\./);
    split(ARGV[2], b, /\./);
    for (i=1; i<=3; i++) {
      if (a[i] && a[i] !~ /^[0-9]+$/) exit(2);
      if (a[i] < b[i]) exit(3);
      else if (a[i] > b[i]) exit(0);
    }
    exit(0)
  }' "${1#v}" "${2#v}"
}

nvm_is_merged_node_version() {
  nvm_version_greater_than_or_equal_to "$1" v4.0.0
}

nvm_get_os() {
  local NVM_UNAME
  NVM_UNAME="$(command uname -a)"
  local NVM_OS
  case "${NVM_UNAME}" in
    Linux\ *) NVM_OS=linux ;;
    Darwin\ *) NVM_OS=darwin ;;
    SunOS\ *) NVM_OS=sunos ;;
    FreeBSD\ *) NVM_OS=freebsd ;;
    AIX\ *) NVM_OS=aix ;;
  esac
  nvm_echo "${NVM_OS-}"
}

nvm_supports_xz() {
  if [ -z "${1-}" ]; then
    return 1
  fi

  # macOS 10.9.0 and later support extracting xz with tar
  if [ "$(nvm_get_os)" = 'linux' ]; then
    local MACOS_VERSION
    nvm_has "sw_vers" && MACOS_VERSION="$(sw_vers -productVersion)"
    if nvm_version_greater "10.9.0" "${MACOS_VERSION}"; then
      return 1
    fi
  # Conservatively assume other operating systems require an xz executable on the PATH
  elif ! command which xz >/dev/null 2>&1; then
    return 1
  fi

  # all node versions v4.0.0 and later have xz
  if nvm_is_merged_node_version "${1}"; then
    return 0
  fi

  # 0.12x: node v0.12.10 and later have xz
  if nvm_version_greater_than_or_equal_to "${1}" "0.12.10" && nvm_version_greater "0.13.0" "${1}"; then
    return 0
  fi

  # 0.10x: node v0.10.42 and later have xz
  if nvm_version_greater_than_or_equal_to "${1}" "0.10.42" && nvm_version_greater "0.11.0" "${1}"; then
    return 0
  fi

  local NVM_OS
  NVM_OS="$(nvm_get_os)"
  case "${NVM_OS}" in
    darwin)
      # darwin only has xz for io.js v2.3.2 and later
      nvm_version_greater_than_or_equal_to "${1}" "2.3.2"
    ;;
    *)
      nvm_version_greater_than_or_equal_to "${1}" "1.0.0"
    ;;
  esac
  return $?
}

if nvm_supports_xz "${1}"; then
  echo "supports xz"
else
  echo "doesn't support xz"
fi
