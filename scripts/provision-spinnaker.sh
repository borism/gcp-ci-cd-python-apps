#!/usr/bin/env bash

GCP_REG="europe-north1"
PROJECT=$(gcloud info --format='value(config.project)')
BUCKET=$PROJECT-spinnaker-config
gsutil mb -c regional -l $GCP_REG gs://$BUCKET

SA_EMAIL=$(gcloud iam service-accounts list \
    --filter="name:spinnaker-storage-account" \
    --format='value(email)')
SA_JSON=$(cat spinnaker-sa.json)
BUCKET=$PROJECT-spinnaker-config

cat > spinnaker-config.yaml <<EOF
storageBucket: $BUCKET
gcs:
  enabled: true
  project: $PROJECT
  jsonKey: '$SA_JSON'

# Disable minio as the default
minio:
  enabled: false


# Configure your Docker registries here
accounts:
- name: gcr
  address: https://gcr.io
  username: _json_key
  password: '$SA_JSON'
  email: '$SA_EMAIL'
EOF

helm install -n cd stable/spinnaker -f spinnaker-config.yaml --timeout 600 --version 0.3.1
