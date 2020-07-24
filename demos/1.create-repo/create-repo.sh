#!/bin/bash

function test_can_create_repo {
    cd /usr/local/src/demos/1.create-repo
    
    rm -rf server
    svnadmin create server
    local found=`cat server/README.txt | grep "This is a Subversion repository" | wc -l`

    assertequals $found 1
}