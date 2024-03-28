#!/bin/bash

mystatus=$(systemctl is-active transcoding.service)

printf "$mystatus"