#!/bin/bash
@MAIN_DIR@/main.sh 2>&1 |tee -a @MAIN_DIR@/logs/.run_log.txt
