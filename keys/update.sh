#!/bin/sh

update() {
    curl -o "./keys/$1" "https://github.com/$1.keys"
}

update dezgeg
update grahamc
update vcunat
