## COLORS ##
RED="\033[0;31m"
GREEN="\033[0;32m"
YELLOW="\033[0;33m"
BLUE="\033[0;34m"
PURPLE="\033[0;35m"
CYAN="\033[0;36m"
RESET="\033[0m"
function graceful_exit() {
    echo -e "${RED}*Closing*${RESET}"
    exit 1
}
function start_step_message() {
    if [[ $# -eq 2 && "$2" == "substep" ]]; then
        echo -e "\n\t${CYAN}* $1 *${RESET}"
    else
        echo -e "\n${CYAN}[*] $1 [*]${RESET}"
    fi
}
function successful() {
    echo -e "\t - ${GREEN}*Successful*${RESET}"
}
function error_message() {
    echo -e "${RED}ERROR${RESET}: $1"
    graceful_exit
}
function warning_message() {
    echo -e "${YELLOW}WARNING${RESET}: $1"
}
function message() {
    echo -e "${PURPLE}$1${RESET}: $2"
}
