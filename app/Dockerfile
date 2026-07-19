FROM python:3.11-slim AS builder
ENV VIRTUAL_ENV=/opt/venv
RUN python -m venv "${VIRTUAL_ENV}"
ENV PATH="${VIRTUAL_ENV}/bin:${PATH}"
WORKDIR /build
COPY requirements.txt .
RUN pip install \
    --no-cache-dir \
    -r requirements.txt

FROM python:3.11-slim
ENV VIRTUAL_ENV=/opt/venv
ENV PATH="${VIRTUAL_ENV}/bin:${PATH}"
ENV PYTHONUNBUFFERED=1
ENV PYTHONDONTWRITEBYTECODE=1
WORKDIR /app

RUN useradd \
    --uid 10001 \
    --create-home \
    --shell /usr/sbin/nologin \
    appuser

COPY --from=builder /opt/venv /opt/venv
COPY --chown=appuser:appuser app.py /app/app.py
USER appuser
EXPOSE 8080

CMD ["sh", "-c", "exec gunicorn --bind :${PORT:-8080} --workers 1 --threads 8 --timeout 0 app:app"]
