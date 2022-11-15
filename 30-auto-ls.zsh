#
# Specific Z shell configuration for auto-ls plugin
#

function auto-ls-reset() { [[ ${WIDGET} == accept-line ]] && clear; }
function auto-ls-echo() { echo; }
function auto-ls-lsd() { lsd --group-dirs=first; }

function auto-ls-readme() {
    for f in $(find . -maxdepth 1 -iname "README*")
    do
        bat --style numbers,header --paging=never $f
        echo
    done
}

function auto-ls-onefetch() {
    if git status &>/dev/null
    then
        onefetch --image-backend kitty -i $c_gitfetch_image --no-palette
        git status -s
        echo
    fi
}

function auto-ls-nix-flake() {
    export SKIP_NIX_SHELL_SCAN=0
    [[ ${WIDGET} == accept-line ]]  && return 0 # newline widget broken

    if ! ( find --version     | grep GNU \
        && df --version       | grep GNU \
        && readlink --version | grep GNU) &>/dev/null
    then
        echo "The Nix flake file scanner requires the GNU coreutils and findutils."
        return 0
    fi          # wrong df, wrong find, or wrong readlink.

    scanpath=$PWD
    while [[ "$(df $scanpath --output=target | tail -n 1)" == "$(df $PWD --output=target | tail -n 1)" ]] && [[ $scanpath != / ]]
    do
        timeout .2s \
        find "$scanpath" -maxdepth 1 -mindepth 1 \
                    -type f         \
                    -readable       \
                    -name flake.nix 2>/dev/null \
        | grep . &>/dev/null && \
        {
            echo -ne "A Nix flake was found. ($scanpath/flake.nix)\nLoad develop shell? [y/N] "
            read -q && nix develop $scanpath -c zsh
            export SKIP_NIX_SHELL_SCAN=1
            return 0
        }
        scanpath="$(readlink -f "$scanpath/..")"
    done
}

function auto-ls-nix-shell() {
    [[ $SKIP_NIX_SHELL_SCAN == 1 ]] && return 0 # Don't scan both flakes and shells
    [[ ${WIDGET} == accept-line ]]  && return 0 # newline widget broken

    if ! ( find --version     | grep GNU \
        && df --version       | grep GNU \
        && readlink --version | grep GNU) &>/dev/null
    then
        echo "The Nix shell file scanner requires the GNU coreutils and findutils."
        return 0
    fi          # Wrong df, wrong find, or wrong readlink.

    scanpath=$PWD
    while [[ "$(df $scanpath --output=target | tail -n 1)" == "$(df $PWD --output=target | tail -n 1)" ]] && [[ $scanpath != / ]]
    do
        timeout .2s \
        find "$scanpath" -maxdepth 1 -mindepth 1 \
                     -type f         \
                     -readable       \
                     -name shell.nix 2>/dev/null \
        | grep . &>/dev/null && \
        {
            echo -ne "A Nix shell workspace was found. ($scanpath/shell.nix)\nLoad? [y/N] "
            read -q && nix-shell $scanpath/shell.nix
            return 0
        }
        scanpath="$(readlink -f "$scanpath/..")"
    done
}

if [[ -v IN_NIX_SHELL ]] || [[ ! -d /nix ]]
then
    export AUTO_LS_COMMANDS=(reset readme onefetch lsd echo)
else
    export AUTO_LS_COMMANDS=(reset readme onefetch lsd nix-flake nix-shell echo)
fi
