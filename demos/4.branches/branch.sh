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
function test_list_branches {
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
    svn copy --parents ^/trunk ^/branches/two -m "branched from trunk"

    assertequals "$(svn list ^/branches)" "$(
        echo "one/" &&
        echo "two/"  
    )"
}

function test_remove_branch {
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
    svn copy --parents ^/trunk ^/branches/two -m "branched from trunk"
    svn remove ^/branches/one -m "branch removed"

    assertequals "$(svn list ^/branches)" "two/"
}
function test_remove_branch_does_not_switch {
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
    svn copy --parents ^/trunk ^/branches/two -m "branched from trunk"
    svn switch ^/branches/one
    svn remove ^/branches/one -m "branch removed"

    assertequals "$(svn info --show-item relative-url)" "^/branches/one"   
}

function test_rename_branch {
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
    svn rename ^/branches/one ^/branches/renamed -m "branch renamed"

    assertequals "$(svn list ^/branches)" "renamed/"
}
function test_rename_branch_does_not_switch {
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
    svn switch ^/branches/one
    svn rename ^/branches/one ^/branches/renamed -m "branch renamed"

    assertequals "$(svn info --show-item relative-url)" "^/branches/one"
}
function test_rename_into_old_branch_does_not_leak_old_content {

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
    svn switch ^/branches/one
    echo "one" > one.txt
    svn add one.txt
    svn commit -m "one added"
    svn update

    svn copy --parents ^/trunk ^/branches/two -m "branched from trunk"
    svn switch ^/branches/two
    
    svn remove ^/branches/one -m "branch removed"
    
    svn rename ^/branches/two ^/branches/one -m "renamed"
    svn switch ^/branches/one

    assertequals "$(ls)" "trunk.txt"
}