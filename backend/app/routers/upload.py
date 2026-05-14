import io
import uuid
from pathlib import Path

from fastapi import APIRouter, File, HTTPException, UploadFile, status
from PIL import Image, UnidentifiedImageError

router = APIRouter(prefix="/upload", tags=["upload"])
_UPLOAD_DIR = Path("uploads")

_MAX_BYTES = 8 * 1024 * 1024                                # 8 МБ
_ALLOWED_EXT = {".jpg", ".jpeg", ".png", ".webp", ".gif"}
_ALLOWED_PIL_FORMATS = {"JPEG", "PNG", "WEBP", "GIF"}
_FORMAT_TO_EXT = {"JPEG": ".jpg", "PNG": ".png", "WEBP": ".webp", "GIF": ".gif"}


@router.post("/photo")
async def upload_photo(file: UploadFile = File(...)):
    if not (file.content_type or "").startswith("image/"):
        raise HTTPException(status_code=400, detail="Only image files are allowed")

    ext = Path(file.filename or "photo.jpg").suffix.lower()
    if ext not in _ALLOWED_EXT:
        raise HTTPException(
            status_code=400,
            detail=f"Расширение {ext or '(нет)'} не поддерживается. Разрешены: {', '.join(sorted(_ALLOWED_EXT))}",
        )

    content = await file.read()
    if not content:
        raise HTTPException(status_code=400, detail="Empty file")
    if len(content) > _MAX_BYTES:
        raise HTTPException(
            status_code=status.HTTP_413_REQUEST_ENTITY_TOO_LARGE,
            detail=f"Файл слишком большой. Максимум {_MAX_BYTES // (1024 * 1024)} МБ.",
        )

    # Перепроверяем тип реальным декодированием — content-type/расширение могут лгать.
    try:
        with Image.open(io.BytesIO(content)) as im:
            im.verify()
            real_format = im.format
    except (UnidentifiedImageError, Exception):
        raise HTTPException(status_code=400, detail="Файл не является корректным изображением")

    if real_format not in _ALLOWED_PIL_FORMATS:
        raise HTTPException(
            status_code=400,
            detail=f"Формат {real_format} не поддерживается",
        )

    safe_ext = _FORMAT_TO_EXT[real_format]
    _UPLOAD_DIR.mkdir(exist_ok=True)
    filename = f"{uuid.uuid4().hex}{safe_ext}"
    dest = _UPLOAD_DIR / filename
    dest.write_bytes(content)

    return {"url": f"/uploads/{filename}"}
