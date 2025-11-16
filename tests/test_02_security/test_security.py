"""Security tests for uvicorn-gunicorn-readyapi image."""
import os
import time
from typing import Dict, Any

import docker
import requests
from docker.client import DockerClient

from ..utils import (
    CONTAINER_NAME,
    get_config,
    get_logs,
    remove_previous_container,
)

client = docker.from_env()


def test_non_root_user() -> None:
    """Test that container runs as non-root user."""
    name = os.getenv("NAME", "python3.11")
    image = f"khulnasoft/uvicorn-gunicorn-readyapi:{name}"
    remove_previous_container(client)
    
    container = client.containers.run(
        image, name=CONTAINER_NAME, ports={"80": "8000"}, detach=True
    )
    time.sleep(3)
    
    try:
        # Check user ID
        result = container.exec_run("id -u")
        user_id = result.output.decode().strip()
        assert user_id != "0", f"Container should not run as root, got user ID: {user_id}"
        
        # Check user name
        result = container.exec_run("whoami")
        username = result.output.decode().strip()
        assert username == "appuser", f"Expected 'appuser', got: {username}"
        
    finally:
        container.stop()
        container.remove()


def test_health_check() -> None:
    """Test container health check functionality."""
    name = os.getenv("NAME", "python3.11")
    image = f"khulnasoft/uvicorn-gunicorn-readyapi:{name}"
    remove_previous_container(client)
    
    container = client.containers.run(
        image, name=CONTAINER_NAME, ports={"80": "8000"}, detach=True
    )
    time.sleep(5)  # Allow health check to run
    
    try:
        # Check health status
        container.reload()
        health = container.attrs.get('State', {}).get('Health', {})
        
        if health:
            status = health.get('Status', 'unknown')
            assert status in ['healthy', 'starting'], f"Unhealthy container status: {status}"
        
        # Verify app is responding
        response = requests.get("http://127.0.0.1:8000", timeout=10)
        assert response.status_code == 200
        
    finally:
        container.stop()
        container.remove()


def test_file_permissions() -> None:
    """Test that application files have correct permissions."""
    name = os.getenv("NAME", "python3.11")
    image = f"khulnasoft/uvicorn-gunicorn-readyapi:{name}"
    remove_previous_container(client)
    
    container = client.containers.run(
        image, name=CONTAINER_NAME, ports={"80": "8000"}, detach=True
    )
    time.sleep(3)
    
    try:
        # Check app directory permissions
        result = container.exec_run("ls -la /app")
        output = result.output.decode()
        
        # Should not be world-writable
        assert "777" not in output, "App directory should not be world-writable"
        
        # Check main.py is readable
        result = container.exec_run("test -r /app/main.py || test -r /app/app/main.py")
        assert result.exit_code == 0, "Main application file should be readable"
        
    finally:
        container.stop()
        container.remove()


def test_container_labels() -> None:
    """Test that container has proper OCI labels."""
    name = os.getenv("NAME", "python3.11")
    image = f"khulnasoft/uvicorn-gunicorn-readyapi:{name}"
    remove_previous_container(client)
    
    container = client.containers.run(
        image, name=CONTAINER_NAME, ports={"80": "8000"}, detach=True
    )
    time.sleep(3)
    
    try:
        labels = container.labels
        
        # Check required labels
        assert "org.opencontainers.image.title" in labels
        assert "org.opencontainers.image.description" in labels
        assert "org.opencontainers.image.vendor" in labels
        
        # Verify label values
        assert labels["org.opencontainers.image.vendor"] == "KhulnaSoft"
        
    finally:
        container.stop()
        container.remove()
