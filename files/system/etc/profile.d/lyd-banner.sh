# Lyd Atomic interactive terminal welcome banner.
# Loaded by Fedora's system shell startup files.
[[ $- == *i* ]] || return 0
[[ -n "${LYD_BANNER_SHOWN:-}" ]] && return 0
LYD_BANNER_SHOWN=1

lyd_banner_version() {
  local command_name="$1" version=""
  if command -v "$command_name" >/dev/null 2>&1; then
    version="$("$command_name" --version 2>/dev/null | awk 'NR == 1 { print $2; exit }')"
  fi
  printf '%s' "${version:-not installed}"
}

purple=$'\033[1;35m'
cyan=$'\033[1;36m'
muted=$'\033[0;37m'
reset=$'\033[0m'

printf '\n%s╭──────────────────────────────────────────────────────────╮%s\n' "$purple" "$reset"
printf '%s│%s  %sLYD ATOMIC%s  %sCustom system commands%s\n' "$purple" "$reset" "$cyan" "$reset" "$muted" "$reset"
printf '%s├──────────────────────────────────────────────────────────┤%s\n' "$purple" "$reset"
printf '%s│%s  %slydhelp%s     v%-10s Linux command reference\n' "$purple" "$reset" "$cyan" "$reset" "$(lyd_banner_version lydhelp)"
printf '%s│%s  %slydsetup%s    v%-10s Optional feature manager\n' "$purple" "$reset" "$cyan" "$reset" "$(lyd_banner_version lydsetup)"
printf '%s│%s  %slydmanage%s   v%-10s System, Flatpak and firmware updates\n' "$purple" "$reset" "$cyan" "$reset" "$(lyd_banner_version lydmanage)"
printf '%s├──────────────────────────────────────────────────────────┤%s\n' "$purple" "$reset"
printf '%s│%s  Run %slydhelp%s, %slydsetup%s or %slydmanage --help%s to get started.\n' "$purple" "$reset" "$cyan" "$reset" "$cyan" "$reset" "$cyan" "$reset"
printf '%s╰──────────────────────────────────────────────────────────╯%s\n\n' "$purple" "$reset"
