import sys

from readyapi import ReadyAPI

version = f"{sys.version_info.major}.{sys.version_info.minor}"

app = ReadyAPI()


@app.get("/")
async def read_root():
    message = f"Hello world! From ReadyAPI running on Uvicorn with Gunicorn. Using Python {version}"
    return {"message": message}
