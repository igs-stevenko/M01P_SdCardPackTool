#!/bin/bash
docker run --rm -it -v `pwd`:/work -u 1001:1001  -e USER=appuser android14:v3.0 /bin/bash
