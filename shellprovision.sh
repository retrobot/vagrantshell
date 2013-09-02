#!/bin/bash
# Entry point bash script
d="./shellscripts/"

# Core base for foundation setup 
# options: -gui  -lamp
bash ${d}base -gui -lamp
# Magento CE 1.7.0.2 installation 
bash ${d}magento
# Wordpress
# TODO
# bash ${d}start 
# bash ${d}start 
# bash ${d}start 
