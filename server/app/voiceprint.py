# ─────────────────────────────────────────────────────────────
# voiceprint.py — does this voice belong to the user?
#
# What it does:
#   GET    /voiceprint          -> {"enrolled": true/false}
#   POST   /voiceprint/enroll   3 clips of the user (wav) -> saves their voice fingerprint
#   POST   /voiceprint/check    1 clip (wav) -> {"score": 0.71, "is_you": true, ...}
#   DELETE /voiceprint          -> forget the fingerprint (privacy!)
#
# How: SpeechBrain's ECAPA model turns a clip into 192 numbers (the "fingerprint").
# Same person -> similar numbers. We compare with cosine similarity:
#   1.0 = identical, ~0 = unrelated. Above THRESHOLD = "that's you".
#
# Runs on OUR machine, no audio goes to OpenAI. We keep only the numbers, never the recording.
# Only one fingerprint for now (no user accounts yet).
#
# torch + speechbrain are big and only installed on the Mac so far
# (requirements-voiceprint-mac.txt / -server.txt). They're loaded on first use, so the server
# still starts without them; then these endpoints answer 503.
# ─────────────────────────────────────────────────────────────

import io
import json
import os

from fastapi import APIRouter, File, HTTPException, UploadFile

router = APIRouter()

SERVER_DIR = os.path.join(os.path.dirname(__file__), "..")
DATA_FILE = os.path.join(SERVER_DIR, "data", "voiceprint.json")  # git-ignored
MODEL_DIR = os.path.join(SERVER_DIR, "voiceprint_model")         # git-ignored, downloaded once

# above this = same person. Set from the 23 Nov tests (see DIARY): others scored <= 0.25,
# me >= 0.42 even when disguised -> 0.33 sits in the middle of the gap. (SpeechBrain's default was 0.25.)
THRESHOLD = float(os.getenv("VOICEPRINT_THRESHOLD", "0.33"))
MIN_SECONDS = 1.0   # shorter clips are too unreliable

_model = None  # loaded on first use (takes a few seconds)


def _get_model():
    global _model
    if _model is None:
        try:
            from speechbrain.inference.speaker import SpeakerRecognition
        except ImportError:
            raise HTTPException(503, "Voiceprint isn't installed on this server.")
        _model = SpeakerRecognition.from_hparams(
            source="speechbrain/spkrec-ecapa-voxceleb", savedir=MODEL_DIR
        )
    return _model


def _fingerprint(wav_bytes: bytes):
    """wav file -> 192 numbers (a torch tensor), length 1"""
    import soundfile as sf
    import torch
    import torchaudio

    try:
        audio, rate = sf.read(io.BytesIO(wav_bytes), dtype="float32", always_2d=True)
    except Exception:
        raise HTTPException(400, "Couldn't read the recording (expected a .wav file).")

    wav = torch.from_numpy(audio.mean(axis=1))      # stereo -> mono
    if rate != 16000:                               # the model wants 16 kHz
        wav = torchaudio.functional.resample(wav, rate, 16000)
    if len(wav) < MIN_SECONDS * 16000:
        raise HTTPException(400, "Recording too short, please say a full sentence.")

    with torch.no_grad():
        emb = _get_model().encode_batch(wav.unsqueeze(0)).squeeze()
    return emb / emb.norm()                         # length 1 -> cosine = simple dot product


def _load():
    if not os.path.exists(DATA_FILE):
        return None
    import torch
    with open(DATA_FILE) as f:
        return torch.tensor(json.load(f)["fingerprint"])


@router.get("/voiceprint")
def status():
    return {"enrolled": os.path.exists(DATA_FILE)}


@router.post("/voiceprint/enroll")
async def enroll(clips: list[UploadFile] = File(...)):
    if len(clips) < 2:
        raise HTTPException(400, "Please send at least 2 recordings.")

    # average of all clips = a steadier fingerprint than any single one
    prints = [_fingerprint(await c.read()) for c in clips]
    mean = sum(prints) / len(prints)
    mean = mean / mean.norm()

    os.makedirs(os.path.dirname(DATA_FILE), exist_ok=True)
    with open(DATA_FILE, "w") as f:
        json.dump({"fingerprint": mean.tolist()}, f)
    print(f"voiceprint: enrolled from {len(prints)} clips")
    return {"enrolled": True}


@router.post("/voiceprint/check")
async def check(clip: UploadFile = File(...)):
    saved = _load()
    if saved is None:
        raise HTTPException(404, "No voice fingerprint yet. Record one first.")

    score = float(_fingerprint(await clip.read()) @ saved)
    print(f"voiceprint: check score {score:.3f}")      # handy for tuning THRESHOLD
    return {"score": round(score, 3), "is_you": score >= THRESHOLD, "threshold": THRESHOLD}


@router.delete("/voiceprint")
def forget():
    if os.path.exists(DATA_FILE):
        os.remove(DATA_FILE)
    return {"enrolled": False}
