#!/bin/bash
set -e

# activate uv
curr_dir=$(pwd)
cd /opt/base-uv
source .venv/bin/activate

# install bs4 and selenium
uv add beautifulsoup4 selenium

# install crawl4ai
uv add crawl4ai crawl4ai[torch]
# finalize setup
crawl4ai-setup
# check if everything is installed correctly
crawl4ai-doctor

# install playwright (client only - server runs in Docker container)
uv add playwright
# Note: No need for playwright install or install-deps when using Docker container
# The browser binaries will run in the container, not locally

# verify playwright client installation
# echo "Checking Playwright client installation..."
# python -c "from playwright.async_api import async_playwright; print('✅ Playwright Python client working')"
# echo "Playwright will connect to Docker container at runtime"

# go back to the original directory
cd $curr_dir

