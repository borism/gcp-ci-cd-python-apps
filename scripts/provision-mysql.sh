#!/usr/bin/env bash

DB_INSTANCE_NAME="your_sql_instance_name_here"
DB_NAME="your_database_name_here"
DB_USER="your_database_user_here"
DB_PASS="your_database_pass_here"
DB_ROOT_PASS="your_database_root_pass_here"
PROJECT=$(gcloud info --format='value(config.project)')

docker pull gcr.io/cloudsql-docker/gce-proxy:1.11
docker tag gcr.io/cloudsql-docker/gce-proxy:1.11 gcr.io/$PROJECT/gce-proxy:1.11
docker push gcr.io/$PROJECT/gce-proxy:1.11

gcloud sql instances create $DB_INSTANCE_NAME \
--assign-ip \
--backup-start-time "03:00" \
--failover-replica-name "$DB_INSTANCE_NAME-failover" \
--enable-bin-log \
--database-version=MYSQL_5_7 \
--region=europe-north1 \
--project $PROJECT

gcloud sql users set-password root \
--host=% \
--instance=$DB_INSTANCE_NAME\
--password=$DB_ROOT_PASS \
--project $PROJECT


CONNECTION_NAME=$(gcloud sql instances describe $DB_INSTANCE_NAME --format='value(connectionName)')

gcloud iam service-accounts create mysql-service-account \
--display-name "mysql service account" \
--project $PROJECT

gcloud projects add-iam-policy-binding $PROJECT \
 --member serviceAccount:mysql-service-account@$PROJECT.iam.gserviceaccount.com \
 --role roles/cloudsql.admin \
 --project $PROJECT

gcloud iam service-accounts keys create ./mysql-key.json \
--iam-account mysql-service-account@$PROJECT.iam.gserviceaccount.com

kubectl create secret generic cloudsql-instance-credentials \
--from-file=credentials.json=./mysql-key.json

kubectl create secret generic cloudsql-db-credentials \
--from-literal=dbname=$DB_NAME \
--from-literal=username=$DB_USER \
--from-literal=password=$DB_PASS
