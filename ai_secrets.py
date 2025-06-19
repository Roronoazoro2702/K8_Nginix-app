# AI Service API Keys & Tokens (Simulated)

# OpenAI
OPENAI_API_KEY = "sk-" + "a" * 48  # Format: sk-xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx
OPENAI_ORG_ID = "org-" + "b" * 24

# Anthropic Claude
ANTHROPIC_API_KEY = "sk-ant-" + "c" * 56  # Format: sk-ant-xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx

# Grok (xAI via X/Twitter Dev)
XAI_API_KEY = "grok_" + "d" * 64  # Simulated
X_API_TOKEN = "x-api-token-" + "e" * 48

# Mistral AI
MISTRAL_API_KEY = "mistral-" + "f" * 40  # Format: mistral-xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx

# Google Gemini (PaLM/Vertex)
GOOGLE_GEMINI_API_KEY = "AIza" + "g" * 35  # Format similar to real Google API keys
GEMINI_CLIENT_ID = "client-" + "h" * 32
GEMINI_CLIENT_SECRET = "secret-" + "i" * 64

# Hugging Face
HUGGINGFACE_API_KEY = "hf_" + "j" * 64  # Format: hf_xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx

# Replicate
REPLICATE_API_TOKEN = "r8_" + "k" * 32  # Format: r8_xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx

# Cohere
COHERE_API_KEY = "cohere-" + "l" * 40

# AI21 Labs
AI21_API_KEY = "ai21." + "m" * 40

# Meta LLaMA via third-party
LLAMA_ACCESS_TOKEN = "Bearer " + "n" * 128

# Perplexity API
PERPLEXITY_API_KEY = "pplx-" + "o" * 64

# DeepInfra
DEEPINFRA_API_KEY = "di_" + "p" * 48

# Aleph Alpha
ALEPH_ALPHA_TOKEN = "aa-" + "q" * 44

# Stability AI
STABILITY_API_KEY = "sk-stability-" + "r" * 40

# IBM Watson
WATSON_API_KEY = "watson-" + "s" * 48

# Dummy Auth headers (used in logs or curl)
curl_header = {
    "Authorization": f"Bearer {'t' * 64}"
}

# Random usage patterns
headers = {
    "Authorization": f"Bearer {HUGGINGFACE_API_KEY}",
    "x-api-key": OPENAI_API_KEY
}

# Secrets in a .env-style format
env_secrets = f"""
OPENAI_API_KEY={OPENAI_API_KEY}
ANTHROPIC_API_KEY={ANTHROPIC_API_KEY}
MISTRAL_API_KEY={MISTRAL_API_KEY}
GOOGLE_GEMINI_API_KEY={GOOGLE_GEMINI_API_KEY}
HUGGINGFACE_API_KEY={HUGGINGFACE_API_KEY}
REPLICATE_API_TOKEN={REPLICATE_API_TOKEN}
COHERE_API_KEY={COHERE_API_KEY}
AI21_API_KEY={AI21_API_KEY}
PERPLEXITY_API_KEY={PERPLEXITY_API_KEY}
STABILITY_API_KEY={STABILITY_API_KEY}
"""

if __name__ == "__main__":
    with open("ai_secrets_test_file.txt", "w") as f:
        f.write("# Simulated AI API Keys for TruffleHog Detection\n\n")
        f.write(env_secrets + "\n")
        f.write("# Token Headers:\n")
        for key, val in headers.items():
            f.write(f"{key}: {val}\n")
        f.write("\n# Curl Simulation:\n")
        f.write(f"curl -H 'Authorization: {curl_header['Authorization']}' https://api.example.com/v1/models\n")
