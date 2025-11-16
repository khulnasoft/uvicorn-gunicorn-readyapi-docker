# Development Guide

## Setup

### Prerequisites
- Docker
- Python 3.10+
- Git

### Local Development

1. **Clone the repository**
   ```bash
   git clone https://github.com/khulnasoft/uvicorn-gunicorn-readyapi-docker.git
   cd uvicorn-gunicorn-readyapi-docker
   ```

2. **Install development dependencies**
   ```bash
   pip install -e .[dev]
   pre-commit install
   ```

3. **Run tests locally**
   ```bash
   pytest tests/ -v
   ```

4. **Build and test Docker image**
   ```bash
   docker build -f docker-images/python3.11.dockerfile -t test-image ./docker-images/
   docker run -p 8000:80 test-image
   ```

## Code Quality

This project uses several tools to maintain code quality:

- **Black**: Code formatting
- **isort**: Import sorting
- **flake8**: Linting
- **mypy**: Type checking
- **pre-commit**: Git hooks

Run all quality checks:
```bash
pre-commit run --all-files
```

## Testing

### Test Structure
- `tests/test_01_main/`: Basic functionality tests
- `tests/test_02_security/`: Security and compliance tests
- `tests/utils.py`: Shared test utilities

### Running Tests
```bash
# Run all tests
pytest

# Run with coverage
pytest --cov=tests --cov-report=html

# Run specific test file
pytest tests/test_01_main/test_defaults.py

# Run with markers
pytest -m integration
```

### Test Markers
- `slow`: Tests that take longer to run
- `integration`: Integration tests requiring external services

## Security

### Security Features
- Non-root user execution
- Container health checks
- Security middleware in ReadyAPI
- Regular dependency updates via Dependabot

### Security Scanning
The project includes automated security scanning:
- Trivy vulnerability scanning in CI
- GitHub Dependabot for dependency updates
- Security-focused test suite

## Docker Image Variants

### Standard vs Slim
- **Standard**: Full Python image with all tools
- **Slim**: Smaller image size, fewer pre-installed packages

### Supported Python Versions
- Python 3.11 (recommended)
- Python 3.10
- Python 3.10

### Deprecated Versions
- Python 3.8 (EOL October 2024)
- Python 3.7 (EOL June 2023)

## Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Run tests and quality checks
5. Submit a pull request

### Pull Request Requirements
- All tests must pass
- Code quality checks must pass
- Security tests must pass
- Documentation updated if needed

## Release Process

1. Update version numbers
2. Update CHANGELOG.md
3. Create release tag
4. Automated build and publish to Docker Hub

## Troubleshooting

### Common Issues

**Permission denied errors**
- Ensure container runs as non-root user
- Check file permissions in Dockerfile

**Health check failures**
- Verify application starts correctly
- Check health check endpoint accessibility

**Test failures**
- Ensure Docker daemon is running
- Check port conflicts (default: 8000)
- Verify image builds successfully

### Getting Help

- Check GitHub Issues
- Review documentation
- Check logs for detailed error messages
