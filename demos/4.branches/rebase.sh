#!/bin/bash

source /usr/local/src/lib/rebase.sh

function prepare_for_rebase_exploration {
    cd /usr/local/src/demos/4.branches
    rm -rf server
    rm -rf clients

    svnadmin create server
    svn mkdir file:///usr/local/src/demos/4.branches/server/trunk -m "message:trunk created"
    
    mkdir -p clients/bob
    cd clients/bob
    svn checkout file:///usr/local/src/demos/4.branches/server/trunk .    

    echo "hello trunk" > trunk.txt
    svn add trunk.txt
    svn commit -m "message:file added in trunk"

    svn copy --parents ^/trunk ^/branches/one -m "message:branched from trunk"

    echo "modified" >> trunk.txt
    svn commit -m "message:file modified in trunk"

    svn switch ^/branches/one
    echo "hello branch" > branch.txt
    svn add branch.txt
    svn commit -m "message:file added in branch"    
    echo "modified" >> branch.txt
    svn commit -m "message:file modified in branch"
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

    assertequals "$message" "message:file added in branch"
}
function test_dont_keep_patch_for_original_branching_out_operation {
    prepare_for_rebase_exploration
    save_patches
    local count=`ls -la .patches/patch*-commit-message | wc -l`

    assertequals $count 2
}
function test_applied_patches_are_on_top_of_base {
    prepare_for_rebase_exploration

    save_patches
    svn switch ^/trunk
    svn remove ^/branches/one -m "removed before rebase"
    svn copy --parents ^/trunk ^/branches/one -m "rebase starts here"
    svn switch ^/branches/one
    apply_patches
    svn update
    local number=`svn info --show-item revision`    
    
    assertequals "$(svn log -r$number | commit_message)" "message:file modified in branch"
}
function test_rebase_ends_up_in_rebased_branch {
    prepare_for_rebase_exploration

    cd /usr/local/src/demos/4.branches/clients/bob
    svn switch ^/branches/one
    rebase ^/trunk

    assertequals "$(svn info --show-item relative-url)" "^/branches/one"
}
function test_rebase_updates_working_copy {
    prepare_for_rebase_exploration

    cd /usr/local/src/demos/4.branches/clients/bob
    svn switch ^/branches/one
    rebase ^/trunk

    assertequals "$(svn log |grep "message")" "$(
        echo "message:file modified in branch" &&
        echo "message:file added in branch" &&
        echo "message:branched from trunk" &&
        echo "message:file modified in trunk" &&
        echo "message:file added in trunk" &&
        echo "message:trunk created"
    )"
}
function test_rebase_is_protected_against_trunk_destruction {
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
    svn mkdir file:///usr/local/src/demos/4.branches/server/trunk -m "message:trunk created"
    
    mkdir -p clients/bob
    cd clients/bob
    svn checkout file:///usr/local/src/demos/4.branches/server/trunk .    

    echo "hello trunk" > trunk.txt
    svn add trunk.txt
    svn commit -m "message:file added in trunk"

    svn copy --parents ^/trunk ^/branches/one -m "message:branched from trunk"

    echo "modified in trunk" > trunk.txt
    svn commit -m "message:trunk file modified in trunk"

    svn switch ^/branches/one
    echo "hello branch" > branch.txt
    svn add branch.txt
    svn commit -m "message:file added in branch" 

    echo "modified in branch" > trunk.txt
    svn commit -m "message:trunk file modified in branch"

    echo "modified" >> branch.txt
    svn commit -m "message:branch file modified in branch"
    svn update
}
function test_rebase_stops_before_first_conflict {
    prepare_for_rebase_exploration_with_conflict

    cd /usr/local/src/demos/4.branches/clients/bob
    svn switch ^/branches/one
    rebase ^/trunk
    
    assertequals "$(svn log --limit 1 ^/branches/one | commit_message)" "message:file added in branch"
}
function test_rebase_offers_one_way_to_continue_after_conflict {
    prepare_for_rebase_exploration_with_conflict

    cd /usr/local/src/demos/4.branches/clients/bob
    svn switch ^/branches/one
    rebase ^/trunk
    
    mv .patches/patch-2-commit-message .patches/patch-2-commit-message-ignored
    rebase ^/trunk --continue

    assertequals "$(svn log --limit 1 ^/branches/one | commit_message)" "message:branch file modified in branch"
}

function test_rebase_complete_story {
    prepare_for_rebase_exploration_with_conflict
    cd /usr/local/src/demos/4.branches/clients/bob
    
    svn copy ^/branches/one ^/branches/one-snapshot -m "ready for the unexpected"    
    svn switch ^/branches/one
    rebase ^/trunk
    
    mv .patches/patch-2-commit-message .patches/patch-2-commit-message-skip-me
    rebase ^/trunk --continue

    assertequals "$(svn log |grep "message")" "$(
        echo "message:branch file modified in branch" &&
        echo "message:file added in branch" &&
        echo "message:branched from trunk" &&
        echo "message:trunk file modified in trunk" &&
        echo "message:file added in trunk" &&
        echo "message:trunk created"
    )"
}
function test_rebase_complete_story_ends_up_ready_for_next_rebase {
    prepare_for_rebase_exploration_with_conflict
    cd /usr/local/src/demos/4.branches/clients/bob
    
    svn copy ^/branches/one ^/branches/one-snapshot -m "ready for the unexpected"    
    svn switch ^/branches/one
    rebase ^/trunk
    
    mv .patches/patch-2-commit-message .patches/patch-2-commit-message-skip-me
    rebase ^/trunk --continue

    assertequals "$(svn log --stop-on-copy |grep "message")" "$(
        echo "message:branch file modified in branch" &&
        echo "message:file added in branch" &&
        echo "message:branched from trunk"
    )"
}