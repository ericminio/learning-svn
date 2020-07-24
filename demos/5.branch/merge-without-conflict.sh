#!/bin/bash

function test_merge_does_not_commit {
    cd /usr/local/src/demos/5.branch
    rm -rf server
    rm -rf clients

    svnadmin create server
    svn mkdir file:///usr/local/src/demos/5.branch/server/trunk -m "trunk created"
    
    mkdir -p clients/bob
    cd clients/bob
    svn checkout file:///usr/local/src/demos/5.branch/server/trunk .    

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

    svn switch ^/trunk
    svn merge ^/branches/one
    local isDirty=`svn status | grep "A  +    branch.txt" | wc -l`

    assertequals $isDirty 1
}

function test_log_hides_merged_commits {
    cd /usr/local/src/demos/5.branch
    rm -rf server
    rm -rf clients

    svnadmin create server
    svn mkdir file:///usr/local/src/demos/5.branch/server/trunk -m "trunk created"
    
    mkdir -p clients/bob
    cd clients/bob
    svn checkout file:///usr/local/src/demos/5.branch/server/trunk .    

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

    svn switch ^/trunk
    svn merge ^/branches/one
    svn commit -m "branch merged"

    assertequals "$(svn log ^/trunk | revision_list)" "r6-r4-r2-r1"
}

function test_log_can_show_merged_commits {
    cd /usr/local/src/demos/5.branch
    rm -rf server
    rm -rf clients

    svnadmin create server
    svn mkdir file:///usr/local/src/demos/5.branch/server/trunk -m "trunk created"
    
    mkdir -p clients/bob
    cd clients/bob
    svn checkout file:///usr/local/src/demos/5.branch/server/trunk .    

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

    svn switch ^/trunk
    svn merge ^/branches/one
    svn commit -m "branch merged"

    assertequals "$(svn log --use-merge-history ^/trunk | revision_list)" "r6-r5-r3-r4-r2-r1"
}
