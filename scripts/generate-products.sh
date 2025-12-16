#!/usr/bin/env bash
set -e

PRODUCTS_COUNT=$1
PODS_PER_PRODUCT=$2

if [[ -z "$PRODUCTS_COUNT" || -z "$PODS_PER_PRODUCT" ]]; then
  echo "Usage: $0 <products_count> <pods_per_product>"
  exit 1
fi

BASE_DIR="workloads-load-tests"
rm -rf ${BASE_DIR}
mkdir -p ${BASE_DIR}

for i in $(seq 0 $((PRODUCTS_COUNT - 1))); do
  PRODUCT_DIR="${BASE_DIR}/product-${i}"
  mkdir -p ${PRODUCT_DIR}

  # Namespace
  cat <<EOF > ${PRODUCT_DIR}/namespace.yaml
apiVersion: v1
kind: Namespace
metadata:
  name: product-${i}
  labels:
    pkz.test: "true"
    pkz.product: product-${i}
EOF

  # Deployment
  cat <<EOF > ${PRODUCT_DIR}/deployment.yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: app
  namespace: product-${i}
spec:
  replicas: ${PODS_PER_PRODUCT}
  selector:
    matchLabels:
      app: app
  template:
    metadata:
      labels:
        app: app
        pkz.test: "true"
    spec:
      containers:
        - name: app
          image: nginx:1.25
          ports:
            - containerPort: 80
EOF

  # Service
  cat <<EOF > ${PRODUCT_DIR}/service.yaml
apiVersion: v1
kind: Service
metadata:
  name: app
  namespace: product-${i}
spec:
  selector:
    app: app
  ports:
    - port: 80
      targetPort: 80
EOF

  # Ingress
  cat <<EOF > ${PRODUCT_DIR}/ingress.yaml
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: app
  namespace: product-${i}
spec:
  ingressClassName: nginx
  rules:
    - host: product-${i}.pkz.test
      http:
        paths:
          - path: /
            pathType: Prefix
            backend:
              service:
                name: app
                port:
                  number: 80
EOF

done

echo "✅ Generated ${PRODUCTS_COUNT} products with ${PODS_PER_PRODUCT} pods each"

