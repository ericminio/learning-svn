#!/bin/bash

function test_can_create_trunk {
    cd /usr/local/src/demos/2.create-trunk
    rm -rf server
    rm -rf client

    svnadmin create server
    svn mkdir file:///usr/local/src/demos/2.create-trunk/server/trunk -m "trunk created"
    
    mkdir client
    cd client
    svn checkout file:///usr/local/src/demos/2.create-trunk/server/trunk 
    cd trunk
    local created=`svn log | grep "trunk created" | wc -l`

    assertequals $created 1
}
