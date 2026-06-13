
from huggingface_hub import InferenceClient
import sys

traits = sys.argv[1]

client = InferenceClient(
    api_key="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"
)

prompt = f"""
Base animal: Horse

Traits:
{traits}

Return ONLY valid JSON:

{{
  "species_name":"",
  "scientific_name":"",
  "habitat": "",
  "description":""
}}
"""

completion = client.chat.completions.create(
    model="microsoft/Phi-4-mini-instruct:featherless-ai",
    messages=[
        {
            "role": "user",
            "content": prompt
        }
    ],
)

result = completion.choices[0].message.content
result = completion.choices[0].message.content

result = result.replace("```json", "")
result = result.replace("```", "")
result = result.strip()

with open("metadata.json", "w", encoding="utf-8") as f:
    f.write(result)

print(result)

with open("metadata.json", "w", encoding="utf-8") as f:
    f.write(result)