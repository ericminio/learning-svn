#!/bin/bash

function test_commit_dont_update_local_log {
    cd /usr/local/src/demos/3.commits
    rm -rf server
    rm -rf client

    svnadmin create server
    svn mkdir file:///usr/local/src/demos/3.commits/server/trunk -m "trunk created"
    
    mkdir client
    cd client
    svn checkout file:///usr/local/src/demos/3.commits/server/trunk 
    cd trunk

    echo "hello world" > hello.txt
    svn add hello.txt
    svn commit -m "file added"    
    local visible=`svn log | grep "file added" | wc -l`

    assertequals $visible 0
}

function test_update_after_commit_is_needed {
    cd /usr/local/src/demos/3.commits
    rm -rf server
    rm -rf client

    svnadmin create server
    svn mkdir file:///usr/local/src/demos/3.commits/server/trunk -m "trunk created"
    
    mkdir client
    cd client
    svn checkout file:///usr/local/src/demos/3.commits/server/trunk 
    cd trunk

    echo "hello world" > hello.txt
    svn add hello.txt
    svn commit -m "file added"   
    svn update 
    local visible=`svn log | grep "file added" | wc -l`
    
    assertequals $visible 1
}
