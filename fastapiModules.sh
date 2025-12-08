#!/bin/bash

pip install "fastapi[standard]" uvicorn sqlalchemy psycopg2-binary python-dotenv pydantic

pip freeze > requirements.txt

mkdir -p features/blog/routes
mkdir -p features/blog/schemas
mkdir -p features/blog/db
mkdir -p features/blog/models

touch features/blog/models/__init__.py
touch features/blog/models/models.py
touch features/blog/db/__init__.py
touch features/blog/db/dbSetup.py
touch features/blog/routes/__init__.py
touch features/blog/routes/routes.py
touch features/blog/schemas/__init__.py
touch features/blog/schemas/schemas.py

touch ProcFile
touch README.md
touch dockerfile
touch .dockerignore
touch .gitignore

cat > features/blog/main.py << 'EOF'
from fastapi import FastAPI
from pydantic import typing
from fastapi.middleware.cors import CORSMiddleware
from fastapi.responses import JSONResponse

app = FastAPI(title="Blogger Backend", description="This is for service based app")

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_crendentails=True,
    allow_methods=["*"],
    allow_headers=["*"],
)


@app.get("/")
def root():
    return JSONResponse(content={"message": "Welcome to fastapi service"})
EOF

