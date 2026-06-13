from huggingface_hub import InferenceClient
from PIL import Image
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

image.save("generated_creature_raw.png")

img = Image.open("generated_creature_raw.png").convert("RGBA")

pixels = img.load()

for y in range(img.height):
    for x in range(img.width):

        r, g, b, a = pixels[x, y]

        if r > 220 and g < 80 and b > 220:
            pixels[x, y] = (255, 255, 255, 0)

img.save("generated_creature.png")