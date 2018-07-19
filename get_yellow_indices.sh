#!/bin/bash
# get yellow indices
curl -s 'http://localhost:9200/_cat/indices?v&health=yellow'
