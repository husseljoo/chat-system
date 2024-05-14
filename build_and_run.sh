#!/bin/bash

set -e

echo "Building Docker images..."

echo "Building Rails app..."
docker build -t rails-app:latest ./chat-system-app

echo "Building go webserver..."
docker build -t creation-webserver:latest ./creation-webserver

echo "Building go workers..."
docker build -t creation-workers:latest ./creation-workers

echo "Building go sequence-generator app..."
docker build -t sequence-generator:latest ./sequence-generator

echo "Docker images built successfully."
echo "Starting services with docker compose..."
docker-compose -f docker-compose-alternative.yml up
