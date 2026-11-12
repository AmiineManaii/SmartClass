import os
import tempfile
import logging
from typing import Optional
from fastapi import FastAPI, UploadFile, File, Form, HTTPException
from fastapi.middleware.cors import CORSMiddleware
from faster_whisper import WhisperModel

logging.basicConfig(level=logging.INFO, format="%(asctime)s [%(levelname)s] %(message)s")
logger = logging.getLogger("smartclass-asr")

app = FastAPI(title="SmartClass Local ASR Service", version="1.0.0")

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

MODEL_SIZE = os.getenv("ASR_MODEL_SIZE", "tiny")
DEVICE = os.getenv("ASR_DEVICE", "auto")
COMPUTE_TYPE = os.getenv("ASR_COMPUTE_TYPE", "auto")

local_model_dir = f"/app/models/{MODEL_SIZE}"
if not (os.path.exists(local_model_dir) and os.path.exists(os.path.join(local_model_dir, "model.bin"))):
    if os.path.exists("/app/models/tiny/model.bin"):
        local_model_dir = "/app/models/tiny"
    else:
        local_model_dir = MODEL_SIZE

logger.info(f"Initializing WhisperModel from '{local_model_dir}' (requested={MODEL_SIZE}, device={DEVICE}, compute_type={COMPUTE_TYPE})...")
try:
    model = WhisperModel(local_model_dir, device=DEVICE, compute_type=COMPUTE_TYPE)
    logger.info("WhisperModel initialized successfully.")
except Exception as e:
    logger.warning(f"Failed to initialize on requested device ({e}), falling back to CPU int8...")
    model = WhisperModel(local_model_dir, device="cpu", compute_type="int8")
    logger.info("Fallback WhisperModel initialized on CPU.")

@app.get("/health")
def health():
    return {
        "status": "ok",
        "service": "smartclass-asr",
        "model": MODEL_SIZE,
    }

@app.post("/v1/audio/transcriptions")
async def create_transcription(
    file: UploadFile = File(...),
    language: Optional[str] = Form(None),
    prompt: Optional[str] = Form(None),
    response_format: Optional[str] = Form("verbose_json"),
    temperature: Optional[float] = Form(0.0),
):
    """
    OpenAI-compatible speech-to-text endpoint.
    Accepts audio WAV/MP3/M4A/MP4/WebM file and transcribes with word & segment timestamps.
    """
    if not file.filename:
        raise HTTPException(status_code=400, detail="Audio file must have a filename")

    suffix = os.path.splitext(file.filename)[1] or ".wav"
    with tempfile.NamedTemporaryFile(suffix=suffix, delete=False) as tmp:
        content = await file.read()
        if len(content) == 0:
            raise HTTPException(status_code=400, detail="Audio file is empty")
        tmp.write(content)
        tmp_path = tmp.name

    try:
        req_lang = None
        if language and language.lower() not in ("auto", "", "null"):
            # Map dialect code ar-TN to standard ar for Whisper
            clean_lang = language.lower()
            if clean_lang.startswith("ar"):
                req_lang = "ar"
            elif clean_lang.startswith("fr"):
                req_lang = "fr"
            elif clean_lang.startswith("en"):
                req_lang = "en"
            else:
                req_lang = clean_lang[:2]

        initial_prompt = prompt or "Transcription de cours universitaire en français, arabe tunisien derja et anglais."

        logger.info(f"Transcribing audio file (size={len(content)} bytes, lang={req_lang})...")
        segments_gen, info = model.transcribe(
            tmp_path,
            language=req_lang,
            initial_prompt=initial_prompt,
            vad_filter=True,
            vad_parameters=dict(min_silence_duration_ms=400, speech_pad_ms=200),
            condition_on_previous_text=False,
            compression_ratio_threshold=2.2,
            no_speech_threshold=0.6,
            beam_size=5,
            temperature=temperature or 0.0,
        )

        segments = []
        full_text_parts = []
        for s in segments_gen:
            clean_text = s.text.strip()
            if clean_text:
                full_text_parts.append(clean_text)
                segments.append({
                    "id": s.id,
                    "seek": s.seek,
                    "start": round(s.start, 3),
                    "end": round(s.end, 3),
                    "text": clean_text,
                    "avg_logprob": round(s.avg_logprob, 3),
                    "no_speech_prob": round(s.no_speech_prob, 3),
                })

        full_text = " ".join(full_text_parts)
        detected_lang = info.language if info else (req_lang or "fr")
        duration = info.duration if info else 0.0

        logger.info(f"Transcription complete: {len(segments)} segments detected, lang={detected_lang}, duration={duration:.1f}s")

        return {
            "text": full_text,
            "language": detected_lang,
            "duration": round(duration, 3),
            "segments": segments,
        }

    except Exception as e:
        logger.error(f"Error during transcription: {e}", exc_info=True)
        raise HTTPException(status_code=500, detail=str(e))
    finally:
        if os.path.exists(tmp_path):
            try:
                os.remove(tmp_path)
            except Exception:
                pass

if __name__ == "__main__":
    import uvicorn
    uvicorn.run("main:app", host="0.0.0.0", port=8000, reload=False)
