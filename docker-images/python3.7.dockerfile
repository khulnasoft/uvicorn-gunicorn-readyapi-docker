FROM khulnasoft/uvicorn-gunicorn:python3.7

LABEL maintainer="KhulnaSoft DevOps <info@khulnasoft.com>"

COPY requirements.txt /tmp/requirements.txt
RUN pip install --no-cache-dir -r /tmp/requirements.txt

COPY ./app /app
