FROM python:3.11-slim AS builder

ENV VIRTUAL_ENV=/opt/venv
RUN python -m venv "${VIRTUAL_ENV}"
ENV PATH="${VIRTUAL_ENV}/bin:${PATH}"

WORKDIR /build
COPY requirements.txt .

RUN pip install \
    --no-cache-dir \
    -r requirements.txt \
    && pip uninstall \
    --yes \
    pip \
    setuptools \
    wheel

FROM python:3.11-slim

ENV VIRTUAL_ENV=/opt/venv
ENV PATH="${VIRTUAL_ENV}/bin:${PATH}"
ENV PYTHONUNBUFFERED=1
ENV PYTHONDONTWRITEBYTECODE=1

WORKDIR /app

RUN python -m pip uninstall \
    --yes \
    pip \
    setuptools \
    wheel \
    && useradd \
    --uid 10001 \
    --create-home \
    --shell /usr/sbin/nologin \
    appuser

COPY --from=builder /opt/venv /opt/venv
COPY --chown=appuser:appuser \
    app.py \
    event_store.py \
    threshold_store.py \
    /app/

USER appuser
EXPOSE 8080

CMD ["sh", "-c", "exec gunicorn --bind :${PORT:-8080} --workers 1 --threads 8 --timeout 30 app:app"]