#!/bin/bash
R -e 'radiant.data:::launch(package="radiant", host="0.0.0.0", port=8181, run=FALSE)' &
sleep 2
open http://localhost:8181
wait $!
