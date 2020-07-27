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

function test_commit_appears_in_local_log_after_update {
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

function test_status_will_tell_you_what_to_expect_from_commit {
    cd /usr/local/src/demos/3.commits
    rm -rf server
    rm -rf client

    svnadmin create server
    svn mkdir file:///usr/local/src/demos/3.commits/server/trunk -m "trunk created"
    
    mkdir client
    cd client
    svn checkout file:///usr/local/src/demos/3.commits/server/trunk 
    cd trunk

    echo "one" > one.txt
    echo "two" > two.txt
    svn add one.txt
    svn add two.txt
    svn commit -m "files added"

    echo "modified" >> one.txt
    echo "modified" >> two.txt

    local status=`svn status`
    local expected=$(
        echo "M       one.txt" && 
        echo "M       two.txt"
    )

    assertequals "$status" "$expected"
}

function test_commit_all_modifications_by_default {
    cd /usr/local/src/demos/3.commits
    rm -rf server
    rm -rf client

    svnadmin create server
    svn mkdir file:///usr/local/src/demos/3.commits/server/trunk -m "trunk created"
    
    mkdir client
    cd client
    svn checkout file:///usr/local/src/demos/3.commits/server/trunk 
    cd trunk

    echo "one" > one.txt
    echo "two" > two.txt
    svn add one.txt
    svn add two.txt
    svn commit -m "files added"

    echo "modified" >> one.txt
    echo "modified" >> two.txt

    svn commit -m "files modified"

    local status=`svn status`

    assertequals "$status" ""
}

function test_can_commit_single_file {
    cd /usr/local/src/demos/3.commits
    rm -rf server
    rm -rf client

    svnadmin create server
    svn mkdir file:///usr/local/src/demos/3.commits/server/trunk -m "trunk created"
    
    mkdir client
    cd client
    svn checkout file:///usr/local/src/demos/3.commits/server/trunk 
    cd trunk

    echo "one" > one.txt
    echo "two" > two.txt
    svn add one.txt
    svn add two.txt
    svn commit -m "files added"

    echo "modified" >> one.txt
    echo "modified" >> two.txt

    svn commit one.txt -m "file one modified"

    local status=`svn status`

    assertequals "$status" "M       two.txt"
}
