# Git bash for windows powerline theme
#
# Licensed under MIT
# Based on https://github.com/Bash-it/bash-it and https://github.com/Bash-it/bash-it/tree/master/themes/powerline
# Some ideas from https://github.com/speedenator/agnoster-bash
# Git code based on https://github.com/joeytwiddle/git-aware-prompt/blob/master/prompt.sh
# More info about color codes in https://en.wikipedia.org/wiki/ANSI_escape_code


PROMPT_CHAR=${POWERLINE_PROMPT_CHAR:=""}
POWERLINE_LEFT_SEPARATOR=" "
POWERLINE_PROMPT="last_status user_info cwd scm"

USER_INFO_SSH_CHAR=" "
USER_INFO_PROMPT_COLOR="C B"

SCM_GIT_CHAR=" "
SCM_PROMPT_CLEAN=""
SCM_PROMPT_DIRTY="*"
SCM_PROMPT_AHEAD="↑"
SCM_PROMPT_BEHIND="↓"
SCM_PROMPT_CLEAN_COLOR="G Bl"
SCM_PROMPT_DIRTY_COLOR="R Bl"
SCM_PROMPT_AHEAD_COLOR=""
SCM_PROMPT_BEHIND_COLOR=""
SCM_PROMPT_STAGED_COLOR="Y Bl"
SCM_PROMPT_UNSTAGED_COLOR="R Bl"
SCM_PROMPT_COLOR=${SCM_PROMPT_CLEAN_COLOR}

CWD_PROMPT_COLOR="B C"

STATUS_PROMPT_COLOR="Bl R B"
STATUS_PROMPT_ERROR="✘"
STATUS_PROMPT_ERROR_COLOR="Bl R B"
STATUS_PROMPT_ROOT="⚡"
STATUS_PROMPT_ROOT_COLOR="Bl Y B"
STATUS_PROMPT_JOBS="●"
STATUS_PROMPT_JOBS_COLOR="Bl Y B"

function __color {
  local bg
  local fg
  local mod
  case $1 in
     'Bl') bg=40;;
     'R') bg=41;;
     'G') bg=42;;
     'Y') bg=43;;
     'B') bg=44;;
     'M') bg=45;;
     'C') bg=46;;
     'W') bg=47;;
     *) bg=49;;
  esac

  case $2 in
     'Bl') fg=30;;
     'R') fg=31;;
     'G') fg=32;;
     'Y') fg=33;;
     'B') fg=34;;
     'M') fg=35;;
     'C') fg=36;;
     'W') fg=37;;
     *) fg=39;;
  esac

  case $3 in
     'B') mod=1;;
     *) mod=0;;
  esac

  # Control codes enclosed in \[\] to not pollute PS1
  # See http://unix.stackexchange.com/questions/71007/how-to-customize-ps1-properly
  echo "\[\e[${mod};${fg};${bg}m\]"
}

# Reset function to clear formatting (for resetting text color and style back to default)
function __reset {
  echo "\[\e[0m\]"
}

function __powerline_user_info_prompt {
  local user_info=""
  local color=${USER_INFO_PROMPT_COLOR}
  if [[ -n "${SSH_CLIENT}" ]]; then
    user_info="${USER_INFO_SSH_CHAR}\u@\h"
  else
    # user_info="\u@\h"
    user_info="" # Remove user and host info if not via SSH
  fi
  [[ -n "${user_info}" ]] && echo "${user_info}|${color}"
}

function __powerline_cwd_prompt {
  echo "\w|${CWD_PROMPT_COLOR}"
}

function __powerline_scm_prompt {
  git_local_branch=""
  git_branch=""
  git_dirty=""
  git_dirty_count=""
  git_ahead_count=""
  git_ahead=""
  git_behind_count=""
  git_behind=""

  find_git_branch() {
    # Based on: http://stackoverflow.com/a/13003854/170413
    git_local_branch=$(git rev-parse --abbrev-ref HEAD 2> /dev/null)

    if [[ -n "$git_local_branch" ]]; then
      if [[ "$git_local_branch" == "HEAD" ]]; then
        # Branc detached Could show the hash here
        git_branch=$(git rev-parse --short HEAD 2>/dev/null)
      else
        git_branch=$git_local_branch
      fi
    else
      git_branch=""
      return 1
    fi
  }

  find_git_dirty() {
    # All dirty files (modified and untracked)
    local status_count=$(git status --porcelain 2> /dev/null | wc -l)

    if [[ "$status_count" != 0 ]]; then
      git_dirty=true
      git_dirty_count="$status_count"
    else
      git_dirty=''
      git_dirty_count=''
    fi
  }

  find_git_ahead_behind() {
    if [[ -n "$git_local_branch" ]] && [[ "$git_branch" != "HEAD" ]]; then
      local upstream_branch=$(git rev-parse --abbrev-ref "@{upstream}" 2> /dev/null)
      # If we get back what we put in, then that means the upstream branch was not found.  (This was observed on git 1.7.10.4 on Ubuntu)
      [[ "$upstream_branch" = "@{upstream}" ]] && upstream_branch=''
      # If the branch is not tracking a specific remote branch, then assume we are tracking origin/[this_branch_name]
      [[ -z "$upstream_branch" ]] && upstream_branch="origin/$git_local_branch"
      if [[ -n "$upstream_branch" ]]; then
        git_ahead_count=$(git rev-list --left-right ${git_local_branch}...${upstream_branch} 2> /dev/null | grep -c '^<')
        git_behind_count=$(git rev-list --left-right ${git_local_branch}...${upstream_branch} 2> /dev/null | grep -c '^>')
        if [[ "$git_ahead_count" = 0 ]]; then
          git_ahead_count=''
        else
          git_ahead=true
        fi
        if [[ "$git_behind_count" = 0 ]]; then
          git_behind_count=''
        else
          git_behind=true
        fi
      fi
    fi
  }


  local color
  local scm_info

  find_git_branch && find_git_dirty && find_git_ahead_behind

  #not in Git repo
  [[ -z "$git_branch" ]] && return

  scm_info="${SCM_GIT_CHAR}${git_branch}"
  [[ -n "$git_dirty" ]] && color=${SCM_PROMPT_DIRTY_COLOR} || color=${SCM_PROMPT_CLEAN_COLOR}
  [[ -n "$git_behind" ]] && scm_info+="${SCM_PROMPT_BEHIND}${git_behind_count}"
  [[ -n "$git_ahead" ]] && scm_info+="${SCM_PROMPT_AHEAD}${git_ahead_count}"

  [[ -n "${scm_info}" ]] && echo "${scm_info}|${color}"
}

function __powerline_left_segment {
  local OLD_IFS="${IFS}"; IFS="|"
  local params=( $1 )
  IFS="${OLD_IFS}"
  local separator_char="${POWERLINE_LEFT_SEPARATOR}"
  local separator=""
  local styles=( ${params[1]} )

  if [[ "${SEGMENTS_AT_LEFT}" -gt 0 ]]; then
    styles[1]=${LAST_SEGMENT_COLOR}
    styles[2]=""
    separator="$(__color ${styles[@]})${separator_char}"
  fi

  styles=( ${params[1]} )
  LEFT_PROMPT+="${separator}$(__color ${styles[@]})${params[0]}"

  #Save last background for next segment
  LAST_SEGMENT_COLOR=${styles[0]}
  (( SEGMENTS_AT_LEFT += 1 ))
}

function __powerline_last_status_prompt {
  local symbols=()
  [[ $last_status -ne 0 ]] && symbols+="$(__color ${STATUS_PROMPT_ERROR_COLOR})${STATUS_PROMPT_ERROR}"
  [[ $UID -eq 0 ]] && symbols+="$(__color ${STATUS_PROMPT_ROOT_COLOR})${STATUS_PROMPT_ROOT}"
  [[ $(jobs -l | wc -l) -gt 0 ]] && symbols+="$(__color ${STATUS_PROMPT_JOBS_COLOR})${STATUS_PROMPT_JOBS}"

  [[ -n "$symbols" ]] && echo "$symbols|${STATUS_PROMPT_COLOR}"
}

#! UPDATED VERSION of the prompt command - use __reset and prevent duplicate appending
function __powerline_prompt_command {
  local last_status="$?" ## always the first
  local separator_char="${POWERLINE_LEFT_SEPARATOR}"
  local newline_prompt_char="${POWERLINE_PROMPT_CHAR}"

  LEFT_PROMPT=""
  SEGMENTS_AT_LEFT=0
  LAST_SEGMENT_COLOR=""

  ## Define Colors ##
  local time_text_color="Bl"        # Black text
  local time_bg_color="W"           # White background

  local path_text_color="W"         # White text
  local path_bg_color="B"           # Blue background

  local git_clean_bg_color="G"    # Green bg for clean Git
  local git_dirty_bg_color="R"    # Red bg for dirty Git

  # Divider Colors
  local time_divider_text_color="$time_bg_color"
  local time_divider_bg_color="$path_bg_color" 
  local path_divider_text_color="$path_bg_color"
  local path_divider_bg_color="-" # will be updated dynamically based on git status

  ## Time Segment ##
  local current_time="$(__color ${time_bg_color} ${time_text_color}) $(date +"%I:%M:%S %p") $(__color ${time_divider_bg_color} ${time_divider_text_color})${separator_char}"

  ## Path Segment ##
	##? Current Working Directory (CWD) Path Format: /first_dir/.../last_two_dirs (last 2 dirs truncated if too long) 
  local full_path=$(pwd)  # Get the full path
  local first_dir=$(echo "${full_path}" | awk -F/ '{print $2}') # Extract the first directory
  # Extract the last two directories and truncate if necessary 
  local truncate_len=20 # (truncate if longer than 20 characters)
  local last_two_dirs=$(echo "${full_path}" | awk -F/ -v truncate_len="$truncate_len" '{
    if (NF > 2) {
      dir1 = $(NF-1)
      dir2 = $NF
      if (length(dir1) > truncate_len) dir1 = substr(dir1, 1, truncate_len)"..."
      if (length(dir2) > truncate_len) dir2 = substr(dir2, 1, truncate_len)"..."
      print dir1 "/" dir2
    } else print $0
  }')
  local formatted_cwd="/${first_dir}/.../${last_two_dirs}" # Combine into the desired format

  ## Python Virtual Environment Segment ##
  local venv_segment=""

  # Use CONDA_DEFAULT_ENV for conda environments
  if [[ -n "$CONDA_DEFAULT_ENV" ]]; then
    venv_segment=" (conda:${CONDA_DEFAULT_ENV})" 
  # If using virtualenv, use VIRTUAL_ENV instead
  elif [[ -n "$VIRTUAL_ENV" ]]; then
    # Get the last directory name of the venv path (usually the env name)
    local venv_name
    venv_name=$(basename "$VIRTUAL_ENV") 
    venv_segment=" (venv:${venv_name})"
  fi


  ## Git Status Segment ##
  local git_status=""
  if git rev-parse --is-inside-work-tree &> /dev/null; then # Check if we are in a Git repo
    # Get the branch name or symbolic reference
    local branch=$(git symbolic-ref --short HEAD 2>/dev/null || git describe --tags --exact-match 2>/dev/null || echo "detached")

    # Check for a clean or dirty state
    local status=$(git status --porcelain 2>/dev/null)
    if [[ -z "$status" ]]; then
      local git_symbol="✔"
      local git_bg_color="${git_clean_bg_color}"
    else
      local git_symbol="✘"
      local git_bg_color="${git_dirty_bg_color}"
    fi

    git_status="$(__color ${git_bg_color}) ${SCM_GIT_CHAR}${branch} ${git_symbol} $(__reset)"

    # Update path divider bg color based on Git status
    path_divider_bg_color="${git_bg_color}"
  fi

  # Format path segment
  local cwd_colored="$(__color ${path_bg_color} ${path_text_color}) ${formatted_cwd}${venv_segment} $(__color ${path_divider_bg_color} ${path_divider_text_color})${separator_char}"

  ## Combine segments ##
  LEFT_PROMPT="${current_time}${cwd_colored}${git_status}"

  ## Set PS1 with a newline for the command ##
  # PS1="${LEFT_PROMPT}\n$(__color)${newline_prompt_char} " #? Old version
  #? New version: Use __reset to clear all ANSI formatting before the prompt character.
  PS1="${LEFT_PROMPT}\n$(__reset)${newline_prompt_char} "


  ## cleanup ##
  unset LAST_SEGMENT_COLOR \
        LEFT_PROMPT \
        SEGMENTS_AT_LEFT
}


function safe_append_prompt_command {
    local prompt_re

    # Set OS dependent exact match regular expression
    if [[ ${OSTYPE} == darwin* ]]; then
      # macOS
      prompt_re="[[:<:]]${1}[[:>:]]"
    else
      # Linux, FreeBSD, etc.
      prompt_re="\<${1}\>"
    fi

    if [[ ${PROMPT_COMMAND} =~ ${prompt_re} ]]; then
      return
    elif [[ -z ${PROMPT_COMMAND} ]]; then
      PROMPT_COMMAND="${1}"
    else
      PROMPT_COMMAND="${1};${PROMPT_COMMAND}"
    fi
}

safe_append_prompt_command __powerline_prompt_command

__color_matrix() {
  local buffer

  declare -A colors=([0]=black [1]=red [2]=green [3]=yellow [4]=blue [5]=purple [6]=cyan [7]=white)
  declare -A mods=([0]='' [1]=B [4]=U [5]=k [7]=N)

  # Print foreground color names
  echo -ne "       "
  for fgi in "${!colors[@]}"; do
    local fg=`printf "%10s" "${colors[$fgi]}"`
    #print color names
    echo -ne "\e[m$fg "
  done
  echo

  # Print modificators
  echo -ne "       "
  for fgi in "${!colors[@]}"; do
    for modi in "${!mods[@]}"; do
      local mod=`printf "%1s" "${mods[$modi]}"`
      buffer="${buffer}$mod "
    done
    # echo -ne "\e[m "
    buffer="${buffer} "
  done
  echo -e "$buffer\e[m"
  buffer=""

  # Print color matrix
  for bgi in "${!colors[@]}"; do
    local bgn=$((bgi + 40))
    local bg=`printf "%6s" "${colors[$bgi]}"`

    #print color names
    echo -ne "\e[m$bg "

    for fgi in "${!colors[@]}"; do
      local fgn=$((fgi + 30))
      local fg=`printf "%7s" "${colors[$fgi]}"`

      for modi in "${!mods[@]}"; do
        buffer="${buffer}\e[${modi};${bgn};${fgn}m "
      done
      # echo -ne "\e[m "
      buffer="${buffer}\e[m "
    done
    echo -e "$buffer\e[m"
    buffer=""
  done
}

__character_map () {
  echo "powerline: ±●➦★⚡★ ✗✘✓✓✔✕✖✗← ↑ → ↓"
  echo "other: ☺☻👨⚙⚒⚠⌛"
}

# bind 'set show-all-if-ambiguous on'
# bind 'TAB:menu-complete'