#!/bin/bash

function test_branching {
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
    svn switch ^/branches/one
    echo "hello branch" > branch.txt
    svn add branch.txt
    svn commit -m "file added in branch"    

    assertequals "$(svn log ^/branches/one | revision_list)" "r4-r3-r2-r1"
    assertequals "$(svn log ^/trunk | revision_list)" "r2-r1"
}
