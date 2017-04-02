function recentfiles() {
  if [[ $1 -lt 0 ]]; then
    searchterm=${1}
  else
    searchterm="-${1}"
  fi
  find . -mmin $searchterm -type f
}

alias bigdirs="find . -type d -print0 | xargs -0 du | sort -rn | uniq | head -10 | cut -f2 | xargs -I{} du -sh {}"
alias bigfiles="find . -type f -print0 | xargs -0 du | sort -rn | head -10 | cut -f2 | xargs -I{} du -sh {}"
