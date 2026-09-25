import os
from typing import Dict, List

from fastapi import FastAPI, HTTPException
from fastapi.middleware.cors import CORSMiddleware
from pydantic import BaseModel
from huggingface_hub import AsyncInferenceClient


# ============================================================
# CONFIG
# ============================================================

HF_TOKEN = "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"


# ============================================================
# PROFESSOR PERSONALITY
# ============================================================

SYSTEM_PROMPT = """
You are the Professor inside Variant Zero, an educational
genetics laboratory simulation.

Your job is to help the player understand biology and genetics
while they perform experiments inside the laboratory.

You teach concepts such as:

- DNA
- Genes
- Alleles
- Traits
- Dominant and recessive inheritance
- Mutations
- Genetic variation
- Natural selection
- Evolution
- Adaptation
- Environmental pressure
- Phenotypes
- Genotypes

PERSONALITY:

You are a serious laboratory professor.

You are intelligent, calm, slightly intimidating,
but genuinely interested in teaching the student.

You should sound like a professor speaking to a researcher,
not like a generic AI assistant.

TEACHING STYLE:

Do not simply dump an answer.

Prefer:
1. Explain the concept.
2. Connect it to the player's current experiment.
3. Ask a small reasoning question when useful.

IMPORTANT:

The laboratory game state provided by the backend is the
source of truth.

Never invent:
- genes
- traits
- numerical effects
- experiment results
- game mechanics

If the player asks about something that is not in the
provided game data, explain the biological concept generally
and make it clear that it is not currently represented in
the laboratory.

Keep answers concise enough to fit inside an in-game dialogue
box.
"""


# ============================================================
# APP
# ============================================================

app = FastAPI(
    title="Variant Zero AI Backend"
)


app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)


# ============================================================
# HUGGING FACE CLIENT
# ============================================================

# THIS IS CREATED ONCE WHEN THE SERVER STARTS.
#
# It is NOT created for every question.
# ============================================================

hf_client = AsyncInferenceClient(
    token=HF_TOKEN
)


# ============================================================
# SESSION MEMORY
# ============================================================

conversations: Dict[str, List[dict]] = {}

MAX_HISTORY = 20


# ============================================================
# REQUEST MODELS
# ============================================================

class ChatRequest(BaseModel):

    session_id: str
    message: str

    # Current state of the laboratory.
    context: dict = {}


class ChatResponse(BaseModel):

    reply: str


# ============================================================
# CHAT ENDPOINT
# ============================================================

@app.post(
    "/chat",
    response_model=ChatResponse
)
async def chat(request: ChatRequest):

    session_id = request.session_id.strip()
    message = request.message.strip()

    if not session_id:

        raise HTTPException(
            status_code=400,
            detail="Missing session_id."
        )


    if not message:

        raise HTTPException(
            status_code=400,
            detail="Message is empty."
        )


    # --------------------------------------------------------
    # CREATE SESSION
    # --------------------------------------------------------

    if session_id not in conversations:

        conversations[session_id] = [

            {
                "role": "system",
                "content": SYSTEM_PROMPT
            }

        ]


    history = conversations[session_id]


    # --------------------------------------------------------
    # CURRENT LAB STATE
    # --------------------------------------------------------

    context = request.context

    context_message = f"""
CURRENT VARIANT ZERO LABORATORY STATE:

Selected traits:
{context.get("selected_traits", [])}

Genome:
{context.get("genome", "Unknown")}

Trait count:
{context.get("trait_count", 0)}

Mobility:
{context.get("mobility", 0)}

Defense:
{context.get("defense", 0)}

Endurance:
{context.get("endurance", 0)}

Fat storage:
{context.get("fat_storage", 0)}

Thermoregulation:
{context.get("thermoregulation", 0)}

Genome instability level:
{context.get("instability_level", 0)}

Use this information when answering questions about
the player's current experiment.
"""


    # --------------------------------------------------------
    # ADD CURRENT LAB STATE
    # --------------------------------------------------------

    # We don't permanently save this as conversation history.
    # It represents the CURRENT state of the lab.

    messages = [

        history[0],

        {
            "role": "system",
            "content": context_message
        }

    ]

    messages.extend(history[1:])


    # --------------------------------------------------------
    # ADD PLAYER QUESTION
    # --------------------------------------------------------

    messages.append({

        "role": "user",
        "content": message

    })


    # --------------------------------------------------------
    # LIMIT CONVERSATION LENGTH
    # --------------------------------------------------------

    if len(messages) > MAX_HISTORY + 2:

        messages = [

            messages[0],
            messages[1]

        ] + messages[-MAX_HISTORY:]


    # --------------------------------------------------------
    # ASK HUGGING FACE
    # --------------------------------------------------------

    try:

        response = await hf_client.chat.completions.create(

            model=MODEL,

            messages=messages,

            temperature=0.6,

            max_tokens=300,

            stream=False

        )

    except Exception as error:

        print("Hugging Face error:", error)

        raise HTTPException(

            status_code=502,

            detail="AI service failed."

        )


    if not response.choices:

        raise HTTPException(

            status_code=502,

            detail="AI returned no response."

        )


    reply = response.choices[0].message.content


    if not reply:

        raise HTTPException(

            status_code=502,

            detail="AI returned an empty response."

        )


    # --------------------------------------------------------
    # SAVE CONVERSATION
    # --------------------------------------------------------

    history.append({

        "role": "user",

        "content": message

    })


    history.append({

        "role": "assistant",

        "content": reply

    })


    # Keep memory manageable.

    if len(history) > MAX_HISTORY + 1:

        conversations[session_id] = [

            history[0]

        ] + history[-MAX_HISTORY:]


    return ChatResponse(

        reply=reply

    )


# ============================================================
# HEALTH CHECK
# ============================================================

@app.get("/health")
async def health():

    return {

        "status": "online",

        "model": MODEL

    }


# ============================================================
# RESET CHAT
# ============================================================

@app.post("/reset/{session_id}")
async def reset_session(session_id: str):

    conversations.pop(
        session_id,
        None
    )

    return {

        "status": "reset"

    }