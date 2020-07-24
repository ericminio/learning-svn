#!/bin/bash

function test_can_extract_list_of_revisions {
    cd /usr/local/src/demos/4.commit-info
    rm -rf server
    rm -rf client

    svnadmin create server
    svn mkdir file:///usr/local/src/demos/4.commit-info/server/trunk -m "trunk created"
    
    mkdir client
    cd client
    svn checkout file:///usr/local/src/demos/4.commit-info/server/trunk 
    cd trunk

    echo "hello world" > hello.txt
    svn add hello.txt
    svn commit -m "file added"   
    svn update

    local revisions=`svn log | grep "r[0-9]* |" | cut -d'|' -f1 | cut -d' ' -f1 | tr '\n' '-' | head -c -1`
    
    assertequals $revisions "r2-r1"
}
