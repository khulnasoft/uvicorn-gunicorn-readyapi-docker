import logging
import sys
from typing import Any, Dict

from readyapi import HTTPException, ReadyAPI
from readyapi.middleware.cors import CORSMiddleware
from readyapi.middleware.trustedhost import TrustedHostMiddleware
from readyapi.responses import JSONResponse

# Configure logging
logging.basicConfig(
    level=logging.INFO,
    format="%(asctime)s - %(name)s - %(levelname)s - %(message)s",
)
logger = logging.getLogger(__name__)

version = f"{sys.version_info.major}.{sys.version_info.minor}"

app = ReadyAPI(
    title="uvicorn-gunicorn-readyapi",
    description="ReadyAPI application running on Uvicorn with Gunicorn",
    version="1.0.0",
    docs_url="/docs",
    redoc_url="/redoc",
)

# Security middleware
app.add_middleware(
    TrustedHostMiddleware, allowed_hosts=["*"]  # Configure appropriately for production
)

# CORS middleware (configure as needed)
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],  # Configure appropriately for production
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)


@app.exception_handler(HTTPException)
async def http_exception_handler(request, exc):
    """Global HTTP exception handler with proper logging."""
    logger.warning(f"HTTP {exc.status_code}: {exc.detail} - Path: {request.url.path}")
    return JSONResponse(
        status_code=exc.status_code,
        content={"error": exc.detail, "status_code": exc.status_code},
    )


@app.exception_handler(Exception)
async def general_exception_handler(request, exc):
    """Global exception handler for unexpected errors."""
    logger.error(f"Unexpected error: {str(exc)} - Path: {request.url.path}")
    return JSONResponse(
        status_code=500,
        content={"error": "Internal server error", "status_code": 500},
    )


@app.get("/", response_model=Dict[str, Any])
async def read_root() -> Dict[str, Any]:
    """Root endpoint with basic system information."""
    try:
        message = f"Hello world! From ReadyAPI running on Uvicorn with Gunicorn. Using Python {version}"
        logger.info("Root endpoint accessed successfully")
        return {
            "message": message,
            "python_version": version,
            "status": "healthy",
        }
    except Exception as e:
        logger.error(f"Error in root endpoint: {str(e)}")
        raise HTTPException(status_code=500, detail="Internal server error")


@app.get("/health", response_model=Dict[str, str])
async def health_check() -> Dict[str, str]:
    """Health check endpoint for monitoring."""
    return {"status": "healthy", "service": "uvicorn-gunicorn-readyapi"}


@app.get("/info", response_model=Dict[str, Any])
async def get_info() -> Dict[str, Any]:
    """Get detailed application information."""
    return {
        "python_version": version,
        "framework": "ReadyAPI",
        "server": "Uvicorn with Gunicorn",
        "docs_url": "/docs",
        "redoc_url": "/redoc",
    }
