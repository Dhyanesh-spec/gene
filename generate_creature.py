
from huggingface_hub import InferenceClient
from rembg import remove
import sys

HF_TOKEN = "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"

prompt = sys.argv[1]

client = InferenceClient(
    provider="nscale",
    api_key=HF_TOKEN
)

image = client.text_to_image(
    prompt,
    model="black-forest-labs/FLUX.1-schnell"
)
print("generated")
image.save("generated_creature_raw.png")

with open("generated_creature_raw.png", "rb") as inp:
    result = remove(inp.read())

with open("generated_creature.png", "wb") as out:
    out.write(result)

print("DONE")