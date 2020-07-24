#!/bin/bash

function prepare_for_rebase_exploration {
    cd /usr/local/src/demos/5.branches
    rm -rf server
    rm -rf clients

    svnadmin create server
    svn mkdir file:///usr/local/src/demos/5.branches/server/trunk -m "trunk created"
    
    mkdir -p clients/bob
    cd clients/bob
    svn checkout file:///usr/local/src/demos/5.branches/server/trunk .    

    echo "hello trunk" > trunk.txt
    svn add trunk.txt
    svn commit -m "file added in trunk"

    svn copy --parents ^/trunk ^/branches/one -m "branched from trunk"

    echo "modified" >> trunk.txt
    svn commit -m "file modified in trunk"

    svn switch ^/branches/one
    echo "hello branch" > branch.txt
    svn add branch.txt
    svn commit -m "file added in branch"    
    echo "modified" >> branch.txt
    svn commit -m "file modified in branch"
    svn update
}
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

function test_patch_1_is_for_expected_revision {
    prepare_for_rebase_exploration
    save_patches
    local correct=`cat .patches/patch-1 | grep "+++ branch.txt	(revision 5)" | wc -l`

    assertequals $correct 1
}

function test_patch_2_is_for_expected_revision {
    prepare_for_rebase_exploration
    save_patches
    local correct=`cat .patches/patch-2 | grep "+++ branch.txt	(revision 6)" | wc -l`

    assertequals $correct 1
}

function test_save_commit_message {
    prepare_for_rebase_exploration
    save_patches
    local message=`cat .patches/patch-1-commit-message`

    assertequals "$message" "file added in branch"
}

function test_dont_keep_patch_for_original_branching_out_operation {
    prepare_for_rebase_exploration
    save_patches
    local count=`ls -la .patches/patch*-commit-message | wc -l`

    assertequals $count 2
}