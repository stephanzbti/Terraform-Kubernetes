#! /bin/bash

if [ "$SERVER_TYPE" == "express" ]; then
    echo "[INFO] Starting NodeJS"
    npm start
fi
