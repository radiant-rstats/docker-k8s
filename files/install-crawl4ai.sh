#!/bin/bash
set -e

# activate uv
curr_dir=$(pwd)
cd /opt/base-uv
source .venv/bin/activate
# install crawl4ai
uv add crawl4ai crawl4ai[torch] crawl4ai[transformers]
# finalize setup
crawl4ai-setup
# check if everything is installed correctly
crawl4ai-doctor
# go back to the original directory
cd $curr_dir

