#!/bin/bash
set -e

pip install --no-cache-dir --root-user-action=ignore crawl4ai crawl4ai[torch] crawl4ai[transformers]
# finalize setup
crawl4ai-setup
# check if everything is installed correctly
crawl4ai-doctor

