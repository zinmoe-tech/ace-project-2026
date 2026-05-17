#!/usr/bin/env bash

kind delete clusters ace-cluster
kubectl config delete-context ace-cluster
kind delete clusters 124
kubectl config delete-context 124
kind delete clusters 125
kubectl config delete-context 125
kind delete clusters 126
kubectl config delete-context 126
kind delete clusters 127
kubectl config delete-context 127
kind delete clusters 128
kubectl config delete-context 128
kind delete clusters 129
kubectl config delete-context 129
kind delete clusters 130
kubectl config delete-context 130
kind delete clusters 131
kubectl config delete-context 131
kind delete clusters kv-cluster
kubectl config delete-context kv-cluster
kind delete clusters db-cluster
kubectl config delete-context db-cluster
kind delete clusters pki-cluster
kubectl config delete-context pki-cluster

kubectl config delete-context dc1-server
kubectl config delete-context dc2-server

