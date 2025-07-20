#!/bin/bash
R -e 'radiant.data:::launch(package="radiant", host="127.0.0.1", port=8181, run=FALSE)' &
sleep 2
open http://127.0.0.1:8181
wait $!
