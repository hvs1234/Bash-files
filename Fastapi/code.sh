cat > .vscode/settings.json <<'EOF'
{
  "material-icon-theme.folders.associations": {
    "global_component": "global",
    "global_components": "global",
    "globalComponent": "global",
    "globalComponents": "global",
    "globalService": "robot",
    "globalServices": "robot",
    "shared_component": "components",
    "shared_components": "components",
    "sharedComponents": "components",
    "sharedComponent": "components",
    "ui_elements": "components",
    "ui_element": "components",
    "uiElements": "components",
    "uiElement": "components",
    "widgets": "components",
    "btns": "ui",
    "Bash":"robot",
    "chat":"messages",
    "Chat":"messages",
    "ChatBot":"messages",
    "chatBot":"messages",
    "uploaded_imgs":"images",
    "uploadedImgs":"images",
  }
}
EOF

cat > features/blog/db/blogdbSetup.py <<'EOF'
from sqlalchemy import create_engine
from sqlalchemy.ext.declarative import declarative_base
from sqlalchemy.orm import sessionmaker
from dotenv import load_dotenv
import os

load_dotenv()

engine = create_engine(os.getenv("DATABASE_URL"))
SessionLocal = sessionmaker(autocommit=False, autoflush=False, bind=engine)
Base = declarative_base()
EOF

cat > features/blog/models/blogModels.py <<'EOF'
from sqlalchemy import Column, String, Integer, DateTime, ForeignKey
from features.blog.db.blogdbSetup import Base


class MyBlogs(Base):
    __tablename__ = "my_blog"
    id = Column(Integer, primary_key=True, index=True)
    name = Column(String, nullable=False, unique=True)
    desc = Column(String, nullable=False)
    img = Column(String, nullable=False)
EOF

cat > features/blog/routes/blogRoutes.py <<'EOF'
from fastapi import APIRouter, HTTPException, Depends, status, UploadFile, File, Form
from sqlalchemy.orm import Session
from features.blog.db.blogdbSetup import SessionLocal
from features.blog.models.blogModels import MyBlogs
from features.blog.schemas.blogSchemas import BlogCreate, BlogResponse, BlogSuccessResponse
import os, uuid
from typing import List

router = APIRouter()


def get_db():
    db = SessionLocal()
    try:
        yield db
    finally:
        db.close()


UPLOAD_DIR = "features/blog/uploaded_imgs"
os.makedirs(UPLOAD_DIR, exist_ok=True)


@router.post(
    "/blogs/create-blog",
    response_model=BlogSuccessResponse,
    status_code=status.HTTP_201_CREATED,
)
async def createBlogs(
    blog: BlogCreate = Depends(BlogCreate.as_form),
    img: UploadFile = File(...),
    db: Session = Depends(get_db),
):
    if not img.content_type.startswith("image/"):
        raise HTTPException(status_code=400, detail="Only image files allowed")

    existing_blog = db.query(MyBlogs).filter(MyBlogs.name == blog.name).first()
    if existing_blog:
        raise HTTPException(
            status_code=400, detail="Blog already exists. Name should be unique"
        )

    ext = img.filename.split(".")[-1]
    filename = f"{uuid.uuid4()}.{ext}"
    filepath = os.path.join(UPLOAD_DIR, filename)

    with open(filepath, "wb") as f:
        f.write(await img.read())

    db_blog = MyBlogs(name=blog.name, desc=blog.desc, img=filename)
    db.add(db_blog)
    db.commit()
    db.refresh(db_blog)
    return {"message": "Blog created successfully", "data": db_blog}


@router.get(
    "/blogs/get-all-blogs",
    response_model=List[BlogResponse],
    status_code=status.HTTP_200_OK,
)
async def getAllBlogs(db: Session = Depends(get_db)):
    return db.query(MyBlogs).all()


@router.put(
    "/blogs/update-blog/{blog_id}",
    response_model=BlogSuccessResponse,
    status_code=status.HTTP_200_OK,
)
async def update_blog(
    blog_id: int,
    blog: BlogCreate = Depends(BlogCreate.as_form),
    img: UploadFile = File(None),
    db: Session = Depends(get_db),
):
    db_blog = db.query(MyBlogs).filter(MyBlogs.id == blog_id).first()
    if not db_blog:
        raise HTTPException(status_code=404, detail="Blog does not exist.")

    changed = False

    if blog.name != db_blog.name:
        db_blog.name = blog.name
        changed = True

    if blog.desc != db_blog.desc:
        db_blog.desc = blog.desc
        changed = True

    if img:
        if not img.content_type.startswith("image/"):
            raise HTTPException(status_code=400, detail="Only image files allowed")

        ext = img.filename.split(".")[-1]
        filename = f"{uuid.uuid4()}.{ext}"
        filepath = os.path.join(UPLOAD_DIR, filename)

        with open(filepath, "wb") as f:
            f.write(await img.read())

        old_path = os.path.join(UPLOAD_DIR, db_blog.img)
        if os.path.exists(old_path):
            os.remove(old_path)

        db_blog.img = filename
        changed = True

    if not changed:
        return {"message": "Nothing is updated", "data": db_blog}

    db.commit()
    db.refresh(db_blog)

    return {"message": "Blog updated successfully", "data": db_blog}


@router.delete(
    "/blogs/delete-blog/{blog_id}",
    status_code=status.HTTP_200_OK,
)
async def delete_blog(blog_id: int, db: Session = Depends(get_db)):
    db_blog = db.query(MyBlogs).filter(MyBlogs.id == blog_id).first()
    if not db_blog:
        raise HTTPException(status_code=404, detail="Blog does not exist.")

    img_path = os.path.join(UPLOAD_DIR, db_blog.img)
    if os.path.exists(img_path):
        os.remove(img_path)

    db.delete(db_blog)
    db.commit()

    return {"message": "Blog deleted successfully"}
EOF

cat > features/blog/schemas/blogSchemas.py <<'EOF'
from pydantic import BaseModel
from fastapi import Form


class BlogCreate(BaseModel):
    name: str
    desc: str

    @classmethod
    def as_form(cls, name: str = Form(...), desc: str = Form(...)):
        return cls(name=name, desc=desc)


class BlogResponse(BaseModel):
    id: int
    name: str
    desc: str
    img: str

    class Config:
        orm_mode = True


class BlogSuccessResponse(BaseModel):
    message: str
    data: BlogResponse
EOF

cat > main.py <<'EOF'
from fastapi import FastAPI
from pydantic import typing
from fastapi.middleware.cors import CORSMiddleware
from fastapi.responses import JSONResponse
from fastapi.staticfiles import StaticFiles
from features.blog.routes.blogRoutes import router as blog_router
from features.blog.db.blogdbSetup import engine
from features.blog.models.blogModels import BlogBase

app = FastAPI(title="Blogger Backend", description="This is for service Blogbased app")

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)
app.include_router(blog_router, prefix="/api", tags=["blogs"])
BlogBase.metadata.create_all(bind=engine)
app.mount(
    "/features/blog/uploaded_imgs",
    StaticFiles(directory="features/blog/uploaded_imgs"),
    name="uploaded_imgs",
)

@app.get("/")
def root():
    return JSONResponse(content={"message": "Welcome to fastapi service"})

    return JSONResponse(content={"message": "Welcome to fastapi service"})
EOF

cat > .env <<'EOF'
DATABASE_URL = "postgresql://postgres:postgres@localhost/bloggerdb"
EOF

cat > .gitignore <<'EOF'
.venv
venv
.env
env
node_modules
uploaded_imgs
static
EOF

cat > .dockerignore <<'EOF'
.venv
venv
.env
env
node_modules
uploaded_imgs
static
EOF

