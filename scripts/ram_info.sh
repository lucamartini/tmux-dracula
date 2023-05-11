#!/usr/bin/env bash
# setting the locale, some users have issues with different locales, this forces the correct one
export LC_ALL=en_US.UTF-8

current_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source $current_dir/utils.sh

get_ratio() {
  case $(uname -s) in
  Linux)
    usage="$(free -h | awk 'NR==2 {print $3}')"
    total="$(free -h | awk 'NR==2 {print $2}')"
    formated="${usage}/${total}"

    echo "${formated//i/B}"
    ;;

  Darwin)
    # Get used memory blocks with vm_stat, multiply by page size to get size in bytes, then convert to GB
    hw_pagesize="$(pagesize)"
    anonymous_pages="$(vm_stat | grep 'Anonymous pages' | sed 's/[^0-9]//g')"
    pages_purgeable="$(vm_stat | grep 'Pages purgeable' | sed 's/[^0-9]//g')"
    pages_wired_down="$(vm_stat | grep 'Pages wired down' | sed 's/[^0-9]//g')"
    pages_occupied_by_compressor="$(vm_stat | grep 'Pages occupied by compressor' | sed 's/[^0-9]//g')"
    app_pages="$((anonymous_pages - pages_purgeable))"
    used_pages=$((app_pages + pages_wired_down + pages_occupied_by_compressor))
    used_mem=$((used_pages * hw_pagesize))
    total_mem="$(sysctl -n hw.memsize)"
    total_mem_GB="$((total_mem / 1073741824))"
    used_mem_GB="$((used_mem / 1073741824))"
    echo "${used_mem_GB}GB/${total_mem_GB}GB"
    ;;

  FreeBSD)
    # Looked at the code from neofetch
    hw_pagesize="$(sysctl -n hw.pagesize)"
    mem_inactive="$(($(sysctl -n vm.stats.vm.v_inactive_count) * hw_pagesize))"
    mem_unused="$(($(sysctl -n vm.stats.vm.v_free_count) * hw_pagesize))"
    mem_cache="$(($(sysctl -n vm.stats.vm.v_cache_count) * hw_pagesize))"

    free_mem=$(((mem_inactive + mem_unused + mem_cache) / 1024 / 1024))
    total_mem=$(($(sysctl -n hw.physmem) / 1024 / 1024))
    used_mem=$((total_mem - free_mem))
    echo $used_mem
    if ((used_mem < 1024)); then
      echo "${used_mem}MB/$total_mem"
    else
      memory=$((used_mem / 1024))
      echo "${memory}GB/$total_mem"
    fi
    ;;

  CYGWIN* | MINGW32* | MSYS* | MINGW*)
    # TODO - windows compatability
    ;;
  esac
}

main() {
  ram_label=$(get_tmux_option "@dracula-ram-usage-label" "RAM")
  ram_ratio=$(get_ratio)
  echo "$ram_label $ram_ratio"
}

#run main driver
main
