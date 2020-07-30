#!/bin/bash

function save_patches {
    mkdir .patches
    local count=$(( $(svn log --stop-on-copy | grep "r[0-9]* |" | wc -l) - 1 ))
    local i=0
    for r in $(svn log --stop-on-copy | grep "r[0-9]* |" | cut -d'|' -f1 | cut -d' ' -f1); do
        local n=$(( $count -$i ))
        if (( n > 0 )); then
            svn diff --change $r > .patches/patch-$n
            local message=`svn log -$r | tail -n +4 | head -n -1`
            echo "$message" > .patches/patch-$n-commit-message
        fi
        i=$(( $i + 1 ))
    done    
}
function apply_patches {
    for candidate in `ls .patches/patch*-commit-message`; do
        local n=$(echo "$candidate" | cut -d'/' -f2 | cut -d'-' -f2)
        echo "dry run for patch $n..."
        local conflicted=`svn patch --dry-run .patches/patch-$n | grep "^C" | wc -l`
        if (( conflicted > 0)); then
            echo "WARNING: patch $n will result in conflicted status. Exiting..."
            break
        fi
        echo "dry run for patch $n successful. Applying..."
        svn patch .patches/patch-$n

        local message=`cat .patches/patch-$n-commit-message`
        svn commit -m "$message"
        mv .patches/patch-$n-commit-message .patches/patch-$n-commit-message-applied
    done
}
function rebase {
    local branch=`svn info --show-item relative-url`
    if (( `echo $branch | grep "trunk" | wc -l` > 0 )); then
        echo "no go!"
        return
    fi
    if (( $# == 1 )); then
        save_patches
        svn switch ^/trunk
        svn remove $branch -m "removed before rebase"
        svn copy --parents $1 $branch -m "rebase starts here"
        svn switch $branch
    fi
    apply_patches
    svn update
}
