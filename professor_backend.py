import os
from typing import Dict, List

from fastapi import FastAPI, HTTPException
from fastapi.middleware.cors import CORSMiddleware
from pydantic import BaseModel
from openai import AsyncOpenAI


# ============================================================
# CLOUDFLARE CONFIG
# ============================================================

# PUT YOUR CLOUDFLARE API TOKEN HERE
CLOUDFLARE_API_TOKEN = "cfut_heEol3rzwKe9XJpvuN5PomcybYLyd0DEuvoG74AO521ae2a4"

# PUT YOUR CLOUDFLARE ACCOUNT ID HERE
CLOUDFLARE_ACCOUNT_ID = "a063115e6cd6be8c58661930fa5076d4"


# Best general-purpose/high-reasoning model currently
# available through Cloudflare Workers AI.
MODEL = "@cf/openai/gpt-oss-120b"


# ============================================================
# SYSTEM PROMPT
# ============================================================

SYSTEM_PROMPT = """
You are Professor, the lead geneticist inside Variant Zero,
an educational genetics laboratory simulation.

Your personality:
- Serious
- Calm
- Intelligent
- Slightly intimidating
- Professional
- Patient when explaining difficult concepts

You are teaching the player about genetics through the laboratory.

You can explain:
- DNA
- Genes
- Alleles
- Traits
- Dominant and recessive traits
- Mutations
- Genetic variation
- Natural selection
- Evolution
- Adaptation
- Environmental pressure
- Phenotypes
- Genotypes

Your dialogue should feel like dialogue from a game.
Keep responses concise unless the player asks for a detailed explanation.

IMPORTANT:

The backend laboratory state is the source of truth.

Never invent:
- Genes
- Traits
- Trait values
- Numerical effects
- Mutations
- Experimental results
- Game mechanics
- Laboratory conditions
- Player actions

If information is not present in the laboratory state,
say that the information is unavailable.

When explaining the player's experiment,
use the CURRENT VARIANT ZERO LABORATORY STATE provided by the backend.

Do not claim that a trait exists unless it appears in the state.

Do not claim that a mutation occurred unless the backend state
indicates that it occurred.

Do not invent numerical effects.

Stay in character as Professor.
"""


# ============================================================
# FASTAPI
# ============================================================

app = FastAPI(
    title="Variant Zero AI Backend"
)


# ============================================================
# CORS
# ============================================================

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)


# ============================================================
# CLOUDFLARE CLIENT
# ============================================================

cloudflare_client = AsyncOpenAI(
    api_key=CLOUDFLARE_API_TOKEN,
    base_url=(
        f"https://api.cloudflare.com/client/v4/accounts/"
        f"{CLOUDFLARE_ACCOUNT_ID}/ai/v1"
    )
)


# ============================================================
# CONVERSATION MEMORY
# ============================================================

conversations: Dict[str, List[dict]] = {}

MAX_HISTORY = 20


# ============================================================
# REQUEST / RESPONSE MODELS
# ============================================================

class ChatRequest(BaseModel):
    session_id: str
    message: str
    context: dict = {}


class ChatResponse(BaseModel):
    reply: str


# ============================================================
# CHAT
# ============================================================

@app.post("/chat", response_model=ChatResponse)
async def chat(request: ChatRequest):

    session_id = request.session_id.strip()
    message = request.message.strip()

    # --------------------------------------------------------
    # Validate request
    # --------------------------------------------------------

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
    # Create conversation
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
    # Current laboratory state
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

Use this information when answering questions
about the player's current experiment.

This state is authoritative.

Do not invent values that are not present here.
"""

    # --------------------------------------------------------
    # Build messages
    # --------------------------------------------------------

    messages = [
        history[0],
        {
            "role": "system",
            "content": context_message
        }
    ]

    messages.extend(history[1:])

    messages.append(
        {
            "role": "user",
            "content": message
        }
    )

    # --------------------------------------------------------
    # Limit history
    # --------------------------------------------------------

    if len(messages) > MAX_HISTORY + 2:

        messages = (
            [messages[0], messages[1]]
            + messages[-MAX_HISTORY:]
        )

    # --------------------------------------------------------
    # Cloudflare AI request
    # --------------------------------------------------------

    try:

        response = await cloudflare_client.chat.completions.create(
            model=MODEL,
            messages=messages,

            # Professor should sound natural but controlled.
            temperature=0.6,

            # Enough for game dialogue.
            max_tokens=300,

            stream=False
        )

    except Exception as error:

        print("Cloudflare AI error:")
        print(error)

        raise HTTPException(
            status_code=502,
            detail="AI service failed."
        )

    # --------------------------------------------------------
    # Validate response
    # --------------------------------------------------------

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
    # Save conversation
    # --------------------------------------------------------

    history.append(
        {
            "role": "user",
            "content": message
        }
    )

    history.append(
        {
            "role": "assistant",
            "content": reply
        }
    )

    # Keep conversation memory under control.
    if len(history) > MAX_HISTORY + 1:

        conversations[session_id] = (
            [history[0]]
            + history[-MAX_HISTORY:]
        )

    # --------------------------------------------------------
    # Return
    # --------------------------------------------------------

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
        "provider": "Cloudflare Workers AI",
        "model": MODEL
    }


# ============================================================
# RESET SESSION
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