#!/bin/bash

pip install "fastapi[standard]" uvicorn sqlalchemy psycopg2-binary python-dotenv pydantic

pip freeze > requirements.txt

mkdir -p features/blog/routes
mkdir -p features/blog/schemas
mkdir -p features/blog/db
mkdir -p features/blog/models
mkdir -p .vscode

touch features/blog/models/__init__.py
touch features/blog/models/blogModels.py
touch features/blog/db/__init__.py
touch features/blog/db/blogdbSetup.py
touch features/blog/routes/__init__.py
touch features/blog/routes/blogRoutes.py
touch features/blog/schemas/__init__.py
touch features/blog/schemas/blogSchemas.py
touch features/blog/main.py

touch ProcFile
touch README.md
touch dockerfile
touch .dockerignore
touch .gitignore
touch .env
touch .vscode/settings.json
