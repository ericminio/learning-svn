#!/bin/bash

function revision_list {
    grep "r[0-9]* |" | cut -d'|' -f1 | cut -d' ' -f1 | tr '\n' '-' | head -c -1
}


function test_can_extract_list_of_revisions {
    cd /usr/local/src/demos/4.revisions
    rm -rf server
    rm -rf client

    svnadmin create server
    svn mkdir file:///usr/local/src/demos/4.revisions/server/trunk -m "trunk created"
    
    mkdir client
    cd client
    svn checkout file:///usr/local/src/demos/4.revisions/server/trunk 
    cd trunk

    echo "hello world" > hello.txt
    svn add hello.txt
    svn commit -m "file added"   
    svn update

    local revisions=`svn log | grep "r[0-9]* |" | cut -d'|' -f1 | cut -d' ' -f1 | tr '\n' '-' | head -c -1`
    
    assertequals $revisions "r2-r1"
}

function test_extract_commit_message {
    cd /usr/local/src/demos/4.revisions
    rm -rf server
    rm -rf client

    svnadmin create server
    svn mkdir file:///usr/local/src/demos/4.revisions/server/trunk -m "trunk created"
    
    mkdir client
    cd client
    svn checkout file:///usr/local/src/demos/4.revisions/server/trunk 
    cd trunk

    echo "hello world" > hello.txt
    svn add hello.txt
    svn commit -m "file added"   
    svn update

    local revision="r2"
    local message=`svn log -$revision | tail -n +4 | head -n -1`
    
    assertequals "$message" "file added"
}
