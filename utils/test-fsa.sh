#!/bin/sh
#
# wrapper utility used for testing FSA
# - generates molecule configs from molecule-vars.yaml
# - using a template from molecule
# - auto-defaults to VirtualBox if one is detected
# - lints and auto-fixes some issues
# - executes molecule scenarios
#
# requires pipenv shell
# expects ./utils/ansible-lint
#

function usage {
    cat << EOF
Usage: test-fsa.sh ACTION [scenario|role] [--correct] [--boxname boxname] [--virthost myhost]

    ACTION may be:
    - lint      : run ansible-lint against one or more roles
    - test      : run molecule against one or more scenarios
    - template  : template out molecule scenario configs

    If no role/scenario is specified, all will be linted/tested/templated.

    --correct causes lint to try to autocorrect issues
    --boxname specifies the vagrant box to use
    --virthost specifies the name of the remote libvirt host

    See molecule/templates/molecule-vars.example for templating options
EOF
    exit 0
}

if ! which bc >/dev/null 2>&1; then
    echo "Please install bc."
    exit 1
fi

# pipenv check
if [ -z $VIRTUAL_ENV ]; then
    pipenv="pipenv run"
else
    pipenv=""
#    echo "Please run pipenv shell before executing tests"
#    exit 1
fi

if ! [ -d ./roles ]; then
    echo "Please run from the main folder"
    exit 1
fi

# molecule produces a lot of output, we're using this to cut through the noise
function prettyprint {
    padding="$1"
    shift
    string="$@"
    length="$(echo -n $string | wc -c)"
    boxlength="$(echo $length + $padding + 2| bc)"

    box=$(for i in $(seq 1 $boxlength); do echo -n '#'; done)
    pad=$(for i in $(seq 1 $padding); do echo -n '#'; done)

    # bottom box only for molecule which produces a f* ton of output
    if [ "$action" == "test" ]; then echo "$box"; fi
    echo "$pad $string"
}

# not much there to parse, this is mostly sanity checking
function parse_args {
    action="$1"
    # we might have no args so redir stderr
    shift 2>/dev/null
    if [ "$action" == "lint" ]; then
        if [ "$1" == "" ]; then
            # no role specified, do all
            lintroles=$(find ./roles/ -maxdepth 1 -type d | cut -d '/' -f3 | tr '\n' ' ')
        elif [ -d ./roles/"$1" ]; then
            lintroles="$1"
        else
            echo "Error: Invalid role specified for lint."
            exit 1
        fi
        # execute the linting functions
        if [ "$2" == "--correct" ]; then
            biglint
        else
            smalllint
        fi
    elif echo "$action" | grep -qE 'template|test'; then
        if [ "$1" == "" ]; then
            # no scenario specified, do all
            testscenario=$(find ./molecule/ -maxdepth 1 -type d | cut -d '/' -f3 | tr '\n' ' ')
        elif [ -d ./molecule/"$1" ]; then
            testscenario="$1"
            shift
        else
            echo "Error: Invalid scenario specified for template/test."
            exit 1
        fi
        # check the rest of the cli options, relevant for template
        while [ $# -gt 0 ]; do
            case "$1" in
                --virthost)
                    export virthost="$2"
                    shift 2
                    ;;
                --boxname)
                    export boxname="$2"
                    shift 2
                    ;;
                *)
                    echo "Argument $1 not recognized"
                    usage
                    ;;
            esac
        done
        if [ "$action" == "test" ]; then
            # execute testing function
            do_test
        elif [ "$action" == "template" ]; then
            # template out the things
            for scenario in $testscenario; do
                template
            done
        fi
    else
        usage
    fi
}

function smalllint {
    prettyprint 2 "Linting role $role"
    ansible-lint ./roles/"$role" -c ./utils/ansible-lint --exclude=./roles/"$role"/molecule/*/molecule-vars.yaml
}

function biglint {
    prettyprint 2 "Autocorrecting role $role"
    # write while excluding line-length (which doesn't work right)
    ansible-lint ./roles/"$role" -c ./utils/ansible-lint --skip-list=experimental,name[casing],meta-no-info,yaml --write 2>&1 | grep Modified
    # and run the actual check
    smalllint
}

function template {
    [ ! -f ./molecule/"$scenario"/converge.yml ] \
        || grep -q "AUTO-GENERATED by test-fsa.sh" ./molecule/"$scenario"/converge.yml \
        && converge=true

    [ ! -f ./molecule/"$scenario"/molecule.yml ] \
        || grep -q "AUTO-GENERATED by test-fsa.sh" ./molecule/"$scenario"/molecule.yml \
        && build=true

    if [ "$converge" == "true" ]; then
        # playbook not always included, so we just template it out
        cat << EOF > ./molecule/"$scenario"/converge.yml
---
# AUTO-GENERATED by test-fsa.sh - remove this comment to exempt
- name: Converge
  hosts: all
  roles:
EOF
        # we include everything just like fsa.sh does
        for role in $(find ./roles/ -maxdepth 1 -type d | cut -d '/' -f3 | grep -v ^fsa_ | tr '\n' ' '); do
            echo "    - $role" >> ./molecule/"$scenario"/converge.yml
            #echo "        - $role" >> ./molecule/"$scenario"/converge.yml
        done
        converge="" # unset for next iteration
    fi

    if [ "$build" == "true" ]; then
        # check for libvirt
    	[ ! $(which virsh) ] && [ "$virthost" == "" ] \
    	    && echo "Error: libvirt not installed locally and remote host not specified." \
    	    && exit 1
        # make sure we have something that at least resembles a commitID
        export commitid="$(git log -n 1 | head -n 1 | sed -e 's/^commit //' | head -c 8)"
        if [ "$commitid" == "" ]; then
            export commitid="$(cat /dev/urandom | tr -dc 'a-zA-Z0-9' | fold -w 8 | head -n 1)"
        fi
        # also explicitly export the vars for j2 when it's unset
        [ "$virthost" == "" ] && export virthost=""
        [ "$boxname" == "" ] && export boxname=""

        # we template out the molecule.yml
        $pipenv j2 --filters=./molecule/templates/custom_filters.py ./molecule/templates/molecule.yml.j2 ./molecule/"$scenario"/molecule-vars.yaml -o ./molecule/"$scenario"/molecule.yml
        build=""    # unset for next iteration
    fi
}

# executes molecule
function do_test {
    for scenario in $testscenario; do
        prettyprint 4 "Testing scenario $scenario"
        template
        # have to reset as we're retemplating the configs
        #molecule reset -s "$scenario" >/dev/null
        $pipenv molecule test -s "$scenario"
    done
}
parse_args "$@"

