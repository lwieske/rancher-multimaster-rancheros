#!/usr/bin/env bash

for i in 1.5.{3,2,1,0} 1.4.{2,1,0} 1.3.0
do
    mkdir $i
    pushd $i
        wget https://releases.rancher.com/os/v$i/rancheros.iso
    popd
done