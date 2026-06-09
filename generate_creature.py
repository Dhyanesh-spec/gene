from huggingface_hub import InferenceClient
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

image.save("generated_creature.png")

print("DONE")