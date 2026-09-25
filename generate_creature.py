import sys
import base64
import io
import os
import requests
from PIL import Image
from rembg import remove

# ============================================================
# Cloudflare Workers AI configuration
# ============================================================
CLOUDFLARE_ACCOUNT_ID = "b8710c114f7cade07356297ace090d71"
CLOUDFLARE_API_TOKEN = "cfut_TJ8yhntP3sgcZqsIvy6jG1SA9wOryRpOsNUCtX6J8e3a3b46"

MODEL = "@cf/black-forest-labs/flux-2-klein-4b"

RAW_OUTPUT = "generated_creature_raw.png"
FINAL_OUTPUT = "generated_creature.png"


def fail(message: str, exit_code: int = 1) -> None:
    print(f"[generate_creature] ERROR: {message}", flush=True)
    sys.exit(exit_code)


def decode_cloudflare_image(data: dict) -> bytes:
    """
    Cloudflare returns the generated image as a Base64 string.
    Accept either:
      - plain base64
      - data:image/...;base64,... form
    Then normalize it to a real PNG with Pillow so Godot gets
    a guaranteed-valid PNG file.
    """
    result = data.get("result", {})
    if not isinstance(result, dict):
        fail(f"Unexpected Cloudflare result format: {data}")

    image_b64 = result.get("image")
    if not isinstance(image_b64, str) or not image_b64.strip():
        fail(f"Cloudflare response did not contain result.image: {data}")

    image_b64 = image_b64.strip()

    # Handle data URI just in case.
    if image_b64.startswith("data:"):
        try:
            image_b64 = image_b64.split(",", 1)[1]
        except IndexError:
            fail("Cloudflare returned an invalid data URI.")

    try:
        decoded = base64.b64decode(image_b64, validate=False)
    except Exception as exc:
        fail(f"Could not decode Cloudflare image base64: {exc}")

    # Normalize whatever Cloudflare returned into an actual PNG.
    try:
        with Image.open(io.BytesIO(decoded)) as img:
            img.load()
            print(
                f"[generate_creature] Cloudflare image detected as "
                f"{img.format} {img.size} {img.mode}",
                flush=True,
            )

            # RGBA is useful for the rembg pipeline and PNG preserves it.
            normalized = img.convert("RGBA")

            output = io.BytesIO()
            normalized.save(output, format="PNG", optimize=True)
            png_bytes = output.getvalue()

    except Exception as exc:
        # Save a small diagnostic dump so we can inspect what Cloudflare sent.
        with open("cloudflare_response_debug.bin", "wb") as debug:
            debug.write(decoded)
        fail(
            "Cloudflare returned data that Pillow could not decode as an image. "
            f"Diagnostic bytes saved to cloudflare_response_debug.bin. Details: {exc}"
        )

    # Final sanity check: a valid PNG begins with the PNG signature.
    if not png_bytes.startswith(b"\x89PNG\r\n\x1a\n"):
        fail("Internal error: normalized output is not a valid PNG.")

    return png_bytes


def generate_image(prompt: str) -> bytes:
    if not CLOUDFLARE_ACCOUNT_ID or "PASTE_YOUR_" in CLOUDFLARE_ACCOUNT_ID:
        fail("Set CLOUDFLARE_ACCOUNT_ID at the top of this file.")

    if not CLOUDFLARE_API_TOKEN or "PASTE_YOUR_" in CLOUDFLARE_API_TOKEN:
        fail("Set CLOUDFLARE_API_TOKEN at the top of this file.")

    url = (
        f"https://api.cloudflare.com/client/v4/accounts/"
        f"{CLOUDFLARE_ACCOUNT_ID}/ai/run/{MODEL}"
    )

    print("[generate_creature] Sending prompt to Cloudflare...", flush=True)
    print(f"[generate_creature] Model: {MODEL}", flush=True)
    print(f"[generate_creature] Prompt: {prompt}", flush=True)

    # FLUX.2 Klein 4B uses multipart/form-data.
    response = requests.post(
        url,
        headers={
            "Authorization": f"Bearer {CLOUDFLARE_API_TOKEN}",
        },
        files={
            "prompt": (None, prompt),
            "width": (None, "1024"),
            "height": (None, "1024"),
        },
        timeout=180,
    )

    print(
        f"[generate_creature] Cloudflare HTTP status: {response.status_code}",
        flush=True,
    )

    if not response.ok:
        try:
            print(
                f"[generate_creature] Cloudflare response: {response.json()}",
                flush=True,
            )
        except ValueError:
            print(
                f"[generate_creature] Cloudflare response: {response.text[:2000]}",
                flush=True,
            )
        fail("Cloudflare image generation failed.")

    # Cloudflare's image model API returns JSON containing result.image.
    try:
        data = response.json()
    except ValueError:
        fail(
            "Cloudflare returned a non-JSON response unexpectedly. "
            f"Content-Type: {response.headers.get('content-type', '')}"
        )

    return decode_cloudflare_image(data)


def atomic_write(path: str, data: bytes) -> None:
    """
    Write to a temporary file and replace the target atomically.
    This helps prevent Godot from importing a half-written PNG.
    """
    temp_path = f"{path}.tmp"
    with open(temp_path, "wb") as out:
        out.write(data)
        out.flush()
        os.fsync(out.fileno())

    os.replace(temp_path, path)


def main() -> None:
    if len(sys.argv) < 2:
        fail(
            'Missing prompt. Usage: python generate_creature_cloudflare_hardcoded_fixed.py '
            '"your prompt"'
        )

    prompt = sys.argv[1].strip()
    if not prompt:
        fail("Prompt is empty.")

    # 1. Generate and normalize image
    image_bytes = generate_image(prompt)

    # 2. Save a guaranteed-valid PNG
    atomic_write(RAW_OUTPUT, image_bytes)

    # 3. Remove background
    print("[generate_creature] Removing background...", flush=True)
    try:
        result = remove(image_bytes)
    except Exception as exc:
        fail(f"Background removal failed: {exc}")

    # 4. Save final PNG atomically too
    atomic_write(FINAL_OUTPUT, result)

    print(f"[generate_creature] DONE: {FINAL_OUTPUT}", flush=True)
    print("CREATURE GENERATION SUCCESSFUL", flush=True)
    print("Backend finished.", flush=True)


if __name__ == "__main__":
    main()
