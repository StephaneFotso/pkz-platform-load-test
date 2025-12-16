#!/bin/bash

NB_PRODUCTS=$1
REPLICAS=$2

rm -rf products/*
for i in $(seq -f "%03g" 1 $NB_PRODUCTS); do
cat <<EOF > products/product-$i.yaml
product:
  name: product-$i
  namespace: product-$i
  replicas: $REPLICAS

ingress:
  host: product-$i.pkz.example.com
EOF
done
