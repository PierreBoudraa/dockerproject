# syntax=docker/dockerfile:1.7

# Frozen by the semester version manifest. Students may override this build
# argument only with another instructor-approved digest.
ARG PYTHON_IMAGE=python:3.12-slim@sha256:44ff437bba879d4941b710a369a8f19266aea34b29002807f0c487fabc9eec9b

FROM ${PYTHON_IMAGE} AS builder
ENV PIP_DISABLE_PIP_VERSION_CHECK=1 \
    PIP_NO_CACHE_DIR=1 \
    PYTHONDONTWRITEBYTECODE=1
WORKDIR /build
COPY requirements.txt ./

# Install hash-locked dependencies into /opt/venv (no app source yet, for layer caching).
RUN python -m venv /opt/venv \
 && /opt/venv/bin/pip install --require-hashes -r requirements.txt

# Runtime stage: same pinned base, only the venv and application files.
FROM ${PYTHON_IMAGE} AS runtime

ARG APP_VERSION=dev
ARG GIT_SHA=unknown
ARG SOURCE_URL=unknown

LABEL org.opencontainers.image.version="${APP_VERSION}" \
      org.opencontainers.image.source="${SOURCE_URL}" \
      org.opencontainers.image.revision="${GIT_SHA}"

ENV PATH="/opt/venv/bin:${PATH}" \
    PYTHONDONTWRITEBYTECODE=1 \
    PYTHONUNBUFFERED=1

RUN groupadd --gid 10001 app \
 && useradd --uid 10001 --gid 10001 --no-create-home --shell /usr/sbin/nologin app

WORKDIR /srv
COPY --from=builder /opt/venv /opt/venv
COPY wsgi.py gunicorn.conf.py ./
COPY app ./app

USER 10001:10001

# The API listens on 8000 inside the container (EXPOSE documents, it does not publish).
EXPOSE 8000
# Gunicorn is PID 1 (exec form): it receives SIGTERM directly and shuts down gracefully.
STOPSIGNAL SIGTERM

HEALTHCHECK --interval=30s --timeout=3s --start-period=10s --retries=3 \
  CMD ["python", "-c", "import urllib.request; urllib.request.urlopen('http://127.0.0.1:8000/healthz', timeout=2)"]

CMD ["gunicorn", "--config", "gunicorn.conf.py", "wsgi:application"]
