#!/bin/bash

graph=$1
output=$2
rows=$(wc -l ${graph})

scala ./Convert2Comb.scala ${graph} ${output} ${rows}