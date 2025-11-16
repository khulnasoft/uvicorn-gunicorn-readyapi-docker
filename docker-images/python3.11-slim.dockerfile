FROM khulnasoft/uvicorn-gunicorn:python3.11-slim

LABEL maintainer="KhulnaSoft DevOps <info@khulnasoft.com>" \
      org.opencontainers.image.title="uvicorn-gunicorn-readyapi" \
      org.opencontainers.image.description="ReadyAPI on Uvicorn with Gunicorn" \
      org.opencontainers.image.vendor="KhulnaSoft"

COPY requirements.txt /tmp/requirements.txt
RUN pip install --no-cache-dir -r /tmp/requirements.txt

COPY ./app /app

# Create non-root user for security
RUN groupadd -r appuser && useradd -r -g appuser appuser

# Set ownership and permissions
RUN chown -R appuser:appuser /app && \
    chmod -R 755 /app

# Switch to non-root user
USER appuser
