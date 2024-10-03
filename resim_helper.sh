# ---------------------------------------------- #
#                    Commands                    #
# ---------------------------------------------- #
#? Array of all commands that should be registered. 'exit' is included automatically
#? Registered commands need to follow the convention cmd_<name>, where <name> is an element in the array
COMMANDS=("redeploy" "instantise")

cmd_redeploy() {
    resim reset

    heading "Initialising main account"
    temp_account=$(resim new-account)
    # echo "$temp_account"

    export account=$(echo "$temp_account" | grep Account | grep -o "account_.*")
    export privatekey=$(echo "$temp_account" | grep Private | sed "s/Private key: //")
    export account_badge=$(echo "$temp_account" | grep Owner | grep -o "resource_.*")
    export xrd=$(resim show $account | grep XRD | grep -o "resource_.\S*" | sed -e "s/://")

    heading "Publishing package"
    export package=$(resim publish . | sed "s/Success! New Package: //")

    heading "Assigned env variables"
    tbl_out "account:      " "$account"
    tbl_out "privatekey:   " "$privatekey"
    tbl_out "account_badge:" "$account_badge"
    tbl_out "xrd:          " "$xrd"
}

cmd_instantise() {
    # Validation
    is_pkg_deployed

    if [ $PKG_DEPLOYED = "FALSE" ]; then
        return 0
    elif [ $INSTANTISE_RTM = "DEFAULT" ]; then
        echo "INSTANTISE_RTM unset, please specify the name of the instantisation .rtm file."
        return 0
    fi

    heading "Running transaction manifest"
    instantise_rtm=$(resim run $(echo "$MANIFESTS_PATH/$INSTANTISE_RTM"))
    # echo "$instantise_rtm"

    heading "Fetching component address"
    export component=$(echo "$instantise_rtm" | grep "Component" | grep -o "component_.*")
    echo "$component"

    heading "Fetching resources"
    resources=$(echo "$instantise_rtm" | grep "Resource: ") # Gets all the outputted resource addresses
    echo "$resources" | grep -o "Resource:.*"
    # sed -n '[line],[line]p' specifies the line number of the resource address; both of the [line] parameters should be the same
    export owner_badge=$(echo "$resources" | sed -n '1,1p' | grep -o "resource_.*")

    heading "Assigned env variables"
    tbl_out "component:  " "$component"
    tbl_out "owner_badge:" "$owner_badge"
}

# ---------------------------------------------- #
#                  Resim Helper                  #
# ---------------------------------------------- #
# ------------------ Variables ----------------- #
# SCRIPT_SHELL="$(readlink /proc/$$/exe | sed "s/.*\///")"

# Validation function return values
PKG_DEPLOYED="TRUE"
COMPONENT_INST="TRUE"
# Manifests
MANIFESTS_PATH="/home/tymur/programs/radish/radish-backend/manifests"
INSTANTISE_RTM="instantise_radish.rtm"


# ------------------ Functions ----------------- #
# Text formatting
cmd_heading() { echo "$(tput bold)$(tput smul)$(tput setaf 2)$1$(tput sgr0)"; }
heading() { echo "\n$(tput bold)$(tput setaf 4)] $1$(tput sgr0)"; }
tbl_out() { echo "$(tput bold)$1$(tput sgr0) $2"; }

# Validation functions
is_pkg_deployed() {
    tput bold
    tput setaf 1

    if [ "$(resim show)" = "" ]; then
        echo "Error: Resim not initialised or default account unset"
        PKG_DEPLOYED="FALSE"
    elif [ -z ${account+x} ]; then
        echo "Error: Resim not initialised or issue with account env. variable"
        PKG_DEPLOYED="FALSE"
    elif [ -z ${xrd+x} ]; then
        echo "Error: Resim not initialised or issue with xrd env. variable"
        PKG_DEPLOYED="FALSE"
    elif [ -z ${package+x} ]; then
        echo "Error: Package not deployed or issue with package env. variable"
        PKG_DEPLOYED="FALSE"
    fi

    tput sgr0
}
is_component_inst() {
    tput bold
    tput setaf 1

    if [ -z ${component+x} ]; then
        echo "Error: Component not instantised or issue with component env. variable"
        COMPONENT_INST="FALSE"
    fi

    tput sgr0
}


# --------------- Pre-run Checks --------------- #
# Check that the manifest path is set
if [ $MANIFESTS_PATH = "[DEFAULT]" ]; then
    echo "Path to manifest directory not set. Run |echo \"\$PWD\"| to get the current path."
    echo "Current path is:\n$PWD"
    return 0
fi


# ------------------- Runtime ------------------ #
# TITLE='
#     ____            _              __  __     __
#    / __ \___  _____(_)___ ___     / / / /__  / /___  ___  _____
#   / /_/ / _ \/ ___/ / __ `__ \   / /_/ / _ \/ / __ \/ _ \/ ___/
#  / _, _/  __(__  ) / / / / / /  / __  /  __/ / /_/ /  __/ /
# /_/ |_|\___/____/_/_/ /_/ /_/  /_/ /_/\___/_/ .___/\___/_/
#                                            /_/'

declare -a TITLE_ARRAY=(
    '    ____            _              __  __     __               '
    '   / __ \___  _____(_)___ ___     / / / /__  / /___  ___  _____'
    '  / /_/ / _ \/ ___/ / __ `__ \   / /_/ / _ \/ / __ \/ _ \/ ___/'
    ' / _, _/  __(__  ) / / / / / /  / __  /  __/ / /_/ /  __/ /    '
    '/_/ |_|\___/____/_/_/ /_/ /_/  /_/ /_/\___/_/ .___/\___/_/     '
    '                                           /_/                 '
)
# Print and center the title
tput bold
tput setaf 2
for line in "${TITLE_ARRAY[@]}"; do
    printf "%*s\n" $(((${#line} + $COLUMNS) / 2)) "$line"
done
tput sgr0

# If no parameters passed
if [ $# -eq 0 ]; then
    PS3="Choose number of command to run: $(tput sgr0)"

    while true; do
        # Show command list as bold, yellow
        echo "\n"
        tput bold
        tput setaf 3

        select command in "${COMMANDS[@]}" exit; do
            tput sgr0
            echo

            case $command in
            "exit")
                return 0
                ;;
            *)
                if [ "$(echo "${COMMANDS[@]}" | grep -Fw "$command")" != "" ]; then # Check if input command is in the COMMANDS array
                    cmd_heading "Running command [$command]"
                    # Format the input command to match the function name and execute
                    func="cmd_$command"
                    ${func}

                    break # Since in a while loop, prompt re-displayed
                else
                    echo "$(tput bold)$(tput setaf 1)Invalid option $REPLY $(tput sgr0)"
                fi
                ;;
            esac
        done
    done
# If parameter(s) passed; 1st treated as the function name
else
    if [ "$(echo "${COMMANDS[@]}" | grep -Fw "$1")" != "" ]; then # Check if input command is in the COMMANDS array
        cmd_heading "Running command [$command]"
        # Format the input command to match the function name and execute
        func="cmd_$1"
        ${func}
    else
        echo "$(tput bold)$(tput setaf 1)Invalid command '$1' passed. Input one of:$(tput sgr0)\n$COMMANDS"
    fi
fi
