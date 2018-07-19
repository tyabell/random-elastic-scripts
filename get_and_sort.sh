#/bin/bash
# get and sort indices
curl -s 'http://localhost:9200/_cat/indices?h=index,ss'| sort
