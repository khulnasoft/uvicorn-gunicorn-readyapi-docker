FROM khulnasoft/uvicorn-gunicorn:python3.10-slim

LABEL maintainer="KhulnaSoft DevOps <devops@khulnasoft.com>" \
      org.opencontainers.image.title="uvicorn-gunicorn-readyapi" \
      org.opencontainers.image.description="ReadyAPI on Uvicorn with Gunicorn" \
      org.opencontainers.image.vendor="KhulnaSoft"

# Create non-root user for security
RUN groupadd -r appuser && useradd -r -g appuser appuser

COPY requirements.txt /tmp/requirements.txt
RUN pip install --no-cache-dir -r /tmp/requirements.txt && \
    rm /tmp/requirements.txt

COPY ./app /app

# Set ownership and permissions
RUN chown -R appuser:appuser /app && \
    chmod -R 755 /app

# Switch to non-root user
USER appuser

# Add health check
HEALTHCHECK --interval=30s --timeout=30s --start-period=5s --retries=3 \
    CMD python -c "import requests; requests.get('http://localhost:8000')" || exit 1
