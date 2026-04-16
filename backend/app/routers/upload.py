import uuid
from pathlib import Path
from fastapi import APIRouter, File, UploadFile, HTTPException

router = APIRouter(prefix="/upload", tags=["upload"])
_UPLOAD_DIR = Path("uploads")


@router.post("/photo")
async def upload_photo(file: UploadFile = File(...)):
    if not (file.content_type or "").startswith("image/"):
        raise HTTPException(status_code=400, detail="Only image files are allowed")

    _UPLOAD_DIR.mkdir(exist_ok=True)

    ext = Path(file.filename or "photo.jpg").suffix or ".jpg"
    filename = f"{uuid.uuid4().hex}{ext}"
    dest = _UPLOAD_DIR / filename

    content = await file.read()
    dest.write_bytes(content)

    return {"url": f"/uploads/{filename}"}
