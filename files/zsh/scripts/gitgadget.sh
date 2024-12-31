#!/bin/bash
/opt/conda/bin/R -e 'gitgadget:::gitgadget(host="0.0.0.0", port=8282, launch.browser=FALSE)' &
sleep 2
xdg-open http://localhost:8282
wait $!
