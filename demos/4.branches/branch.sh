#!/bin/bash

function test_branching {
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

    local revisions="$(svn log ^/branches/one | revision_list) vs. $(svn log ^/trunk | revision_list)"
    
    assertequals "$revisions" "r5-r3-r2-r1 vs. r4-r2-r1"
}
