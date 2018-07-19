#!/bin/bash
# get file descriptors
curl -XGET 'localhost:9200/_nodes/stats/process?pretty'
