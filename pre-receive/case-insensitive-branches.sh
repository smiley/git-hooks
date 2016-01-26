#!/bin/bash

# sed -r 's/ *//;s/\* *//;s/^/refs\/heads\//;'      =   1. Trim leading spaces ("  master")
#                                                       2. Trim leading space & selected mark ("* master")
#                                                       3. Prepend "refs/heads/" to each name (to comply with ref names)
SED_NORMALIZE_GIT_REF_NAMES="s/ *//;s/\* *//;s/^/refs\/heads\//;";

# sed ':a;N;$!ba;s/\n/ /g'                          =   1. Define a new label                       -- ":a"
#                                                       2. Append the next line to the current line -- "N"
#                                                       3. On every line but the last...            -- "$!"
#                                                          ...jump to the label "a".                -- "ba"
#                                                       4. Substitute every newline with a space    -- "s/\n/ /g"
SED_JOIN_ALL_LINES=":a;N;$!ba;s/\n/ /g";

# Strip either "refs/heads/" or "refs/tags/", but not both, and only at the beginning.
SED_STRIP_REFS="s/^refs\/heads\///;t;s/^refs\/tags\///";

RE_GIT_EXTRACT_BRANCH_FOLDERS="(?<=refs/heads/).*(?=/)";

GREP_CONTAINS_UPPERCASE="[A-Z]";

declare -i TRUE=0;
declare -i FALSE=1;

CONTACT="";

function get_branches {
    git branch --no-column --no-color | sed -r "$SED_NORMALIZE_GIT_REF_NAMES";
}

function get_matching_caseinsensitive_branches {
    get_branches | grep -i $1;
}

function get_branch_folder_tree {
    echo -n $1 | grep -o -P "$RE_GIT_EXTRACT_BRANCH_FOLDERS";
}

function contains_lowercase {
    echo -n $1 | grep -v -E -q -e "$GREP_CONTAINS_UPPERCASE";
}

function contains_uppercase {
    echo -n $1 | grep -E -q -e "$GREP_CONTAINS_UPPERCASE";
}

function get_uppercase_letters {
    echo -n $1 | grep -b -o -E -e "$GREP_CONTAINS_UPPERCASE" | cut -d : -f 1;
}

function get_uppercase_marker_string {
    local offsets=`get_uppercase_letters $1`;
    local markers_string="";
    for (( i = 0; i < ${#1}; i++)); do
        local found=$FALSE;
        for offset in $offsets; do
            if [ $offset -eq $i ]; then
                found=$TRUE;
                break;
            fi
        done
        if [ $found -eq $FALSE ]; then
            markers_string+=" ";
        else
            markers_string+="^";
        fi
    done
    
    # Return via stdout.
    echo "$markers_string";
}

declare -a uppercase_branch_folders;
declare -a name_conflict_branches;

declare -i RET=0;
while read from_ref to_ref ref_name; do
    normalized_ref=`echo -n $ref_name | sed -r "$SED_STRIP_REFS"`;
    branch_folders=`get_branch_folder_tree $ref_name`;
    
    if contains_uppercase "$branch_folders"; then
        uppercase_branch_folders+=("$ref_name");
    RET=1;
    fi
    
    for branch in `get_matching_caseinsensitive_branches $ref_name`; do
        if [ $branch != $ref_name ]; then
            normalized_branch=`echo -n $branch | sed -r "$SED_STRIP_REFS"`;
            name_conflict_branches+=("$normalized_ref $normalized_branch");
            RET=1;
        fi
    done
done

if [ ${#name_conflict_branches[@]} -gt 0 ]; then
    echo
    echo "ERROR: Branch naming conflict detected!"
    echo "  Some of your branches are named with a different case than the one"
    echo "  everyone's using. You probably meant to push to the existing branch."
    echo "  In addition, Differently-cased branches are discouraged and not"
    echo "  supported on all operating systems."
    echo
    echo "  You have ${#name_conflict_branches[@]} name-conflicting branches:"
    for (( i = 0; i < ${#name_conflict_branches[@]}; i++)); do
        pair=(${name_conflict_branches[$i]});
        declare -i index=i+1
    echo "    $index. Your \"${pair[0]}\" conflicts with everyone's \"${pair[1]}\"."
    done
    echo
    echo "  Please transfer any changes you made into the correctly-named branch,"
    echo "  or avoid pushing these branches if you didn't mean to."
    echo
    echo "  $CONTACT"
    echo
fi

if [ ${#uppercase_branch_folders[@]} -gt 0 ]; then
    echo
    echo "ERROR: Mixed-case branch folders detected!"
    echo "  Some of your branches have different-case \"branch folders\"."
    echo "  For example, \"Feature/branch-name\" instead of \"feature/branch-name\"."
    echo
    echo "  You have ${#uppercase_branch_folders[@]} branches with non-lowercase \"branch folders\":"
    for (( i = 0; i < ${#uppercase_branch_folders[@]}; i++)); do
        declare -i index=i+1
        branch=`echo -n ${uppercase_branch_folders[i]} | sed -r "$SED_STRIP_REFS"`;
        specifier="`get_uppercase_marker_string $branch`";
    echo "    $index. \"$branch\""
    echo "        $specifier"
    done
    echo
    echo "  Please rename your branches into lowercase branch folders, or avoid"
    echo "  pushing these branches if you didn't mean to."
    echo
    echo "  $CONTACT"
    echo
fi

exit $RET