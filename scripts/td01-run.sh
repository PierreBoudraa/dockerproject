#!/usr/bin/env bash
set -euo pipefail

# Se placer à la racine du projet, quel que soit le dossier d'appel
cd "$(dirname "${BASH_SOURCE[0]}")/.."

# Charger les variables du cours (indépendant du terminal de départ)
. scripts/course-env.sh

docker run --detach \
  --name td01-web \
  --platform "$COURSE_IMAGE_PLATFORM" \
  --label course.lab=TD01 \
  --label course.environment=course-lab \
  --restart no \
  --publish "${COURSE_PROXY_BIND}:${COURSE_PROXY_PORT}:8080" \
  "$NGINX_IMAGE"
