#!/bin/bash

source /usr/local/src/lib/rebase.sh

function prepare_for_rebase_exploration {
    cd /usr/local/src/demos/4.branches
    rm -rf server
    rm -rf clients

    svnadmin create server
    svn mkdir file:///usr/local/src/demos/4.branches/server/trunk -m "trunk created"
    
    mkdir -p clients/bob
    cd clients/bob
    svn checkout file:///usr/local/src/demos/4.branches/server/trunk .    

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
function test_rebase_applies_patches_on_top_of_base {
    prepare_for_rebase_exploration

    save_patches
    svn switch ^/trunk
    svn remove ^/branches/one -m "removed before rebase"
    svn copy --parents ^/trunk ^/branches/one -m "rebase starts here"
    svn switch ^/branches/one
    apply_patches
    svn update
    local number=`svn info --show-item revision`    
    
    assertequals "$(svn log -r$number | commit_message)" "file modified in branch"
}
function test_my_rebase_updates_working_copy {
    prepare_for_rebase_exploration

    cd /usr/local/src/demos/4.branches/clients/bob
    svn switch ^/branches/one
    rebase ^/trunk

    assertequals "$(svn log --use-merge-history ^/branches/one | revision_list)" "r10-r9-r8-r4-r2-r1"
}
function test_protection_against_trunk_destruction {
    prepare_for_rebase_exploration

    cd /usr/local/src/demos/4.branches/clients/bob
    svn switch ^/trunk
    local message=`rebase ^/trunk`

    assertequals "$message" "no go!"
}
function prepare_for_rebase_exploration_with_conflict {
    cd /usr/local/src/demos/4.branches
    rm -rf server
    rm -rf clients

    svnadmin create server
    svn mkdir file:///usr/local/src/demos/4.branches/server/trunk -m "trunk created"
    
    mkdir -p clients/bob
    cd clients/bob
    svn checkout file:///usr/local/src/demos/4.branches/server/trunk .    

    echo "hello trunk" > trunk.txt
    svn add trunk.txt
    svn commit -m "file added in trunk"

    svn copy --parents ^/trunk ^/branches/one -m "branched from trunk"

    echo "modified in trunk" > trunk.txt
    svn commit -m "trunk file modified in trunk"

    svn switch ^/branches/one
    echo "hello branch" > branch.txt
    svn add branch.txt
    svn commit -m "file added in branch" 

    echo "modified in branch" > trunk.txt
    svn commit -m "trunk file modified in branch"

    echo "modified" >> branch.txt
    svn commit -m "branch file modified in branch"
    svn update
}
function test_rebase_stops_with_first_conflict {
    prepare_for_rebase_exploration_with_conflict

    cd /usr/local/src/demos/4.branches/clients/bob
    svn switch ^/branches/one
    rebase ^/trunk
    
    assertequals "$(svn log --limit 1 | commit_message)" "file added in branch"
}
function test_rebase_offers_one_way_to_continue_after_conflict {
    prepare_for_rebase_exploration_with_conflict

    cd /usr/local/src/demos/4.branches/clients/bob
    svn switch ^/branches/one
    rebase ^/trunk
    
    mv .patches/patch-2-commit-message .patches/patch-2-commit-message-ignored
    rebase ^/trunk --continue

    assertequals "$(svn log --limit 1 | commit_message)" "branch file modified in branch"
}
