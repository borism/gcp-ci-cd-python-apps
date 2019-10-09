#!/usr/bin/env bash

if [ -z "$1" ]
  then
    echo "Please specify the GCP project."
    exit 1
fi

PROJ_ID=$1
GCP_REG="europe-north1-a"
VM_TYPE="n1-standard-2"
GKE_VER="1.13.7-gke.24"

gcloud config set compute/zone $GCP_REG
gcloud config set project $PROJ_ID

gcloud container clusters create $PROJ_ID \
    --machine-type=$VM_TYPE \
    --cluster-version $GKE_VER

gcloud iam service-accounts create spinnaker-storage-account

SA_EMAIL=$(gcloud iam service-accounts list \
    --filter="name:spinnaker-storage-account" \
    --format='value(email)')
PROJECT=$(gcloud info --format='value(config.project)')

gcloud projects add-iam-policy-binding \
    $PROJECT --role roles/storage.admin --member serviceAccount:$SA_EMAIL

gcloud iam service-accounts keys create spinnaker-sa.json --iam-account $SA_EMAIL

kubectl create clusterrolebinding user-admin-binding --clusterrole=cluster-admin --user=$(gcloud config get-value account)
kubectl create serviceaccount tiller --namespace kube-system
kubectl create clusterrolebinding tiller-admin-binding --clusterrole=cluster-admin --serviceaccount=kube-system:tiller

kubectl create clusterrolebinding --clusterrole=cluster-admin --serviceaccount=default:default spinnaker-admin

helm init --service-account=tiller
helm update
