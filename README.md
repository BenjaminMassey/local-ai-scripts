# local-ai-scripts

Scripts I use for local AI usage.

## Tools

`./vibe.sh`

 - opencode connected to a llama.cpp llama-server

`./start-chat.sh` and `./stop-chat.sh`

 - open-webui connected to llama.cpp llama-server, with searxng for web search

## Usage

`./vibe.sh`

- Run from directory you want to work in
- Quit opencode via standard CTRL+C: will shutdown llama-server afterward

`./start-chat.sh`

- Boots everything up: llama-server, searxng, and open-webui
- Opens your default browser to open-webui front-end

`./stop-chat.sh`

- Shuts down everything that start-chat booted up
- Necessary since the state isn't quite as "isolated" as opencode

## llama-server

I am using a [gmml-org/llama.cpp release](https://github.com/ggml-org/llama.cpp/releases/): ubuntu-vulkan-x86, in my case.

I unpacked it to `~/Development/ai/tools/llama-cpp/`

For both chat and vibe, I am using [Qwen3.6 27B from unsloth's GGUF](https://huggingface.co/unsloth/Qwen3.6-27B-GGUF/tree/main): `Qwen3.6-27B-IQ4_XS.gguf` in my case (plus `mmproj-F16.gguf` for vision).

I unpacked those to `~/Development/ai/models/llm/`

## opencode

I installed [opencode](https://opencode.ai/) via their curl command install.

My config - located at `~/.config/opencode/opencode.json` - has this:

```
{
  "$schema": "https://opencode.ai/config.json",
  "provider": {
    "llama.cpp": {
      "npm": "@ai-sdk/openai-compatible",
      "name": "llama-server",
      "options": {
        "baseURL": "http://127.0.0.1:11434/v1"
      },
      "models": {
        "qwen3.6": {
          "name": "Qwen3.6-27B",
          "limit": {
            "context": 128000,
            "output": 65536
          }
        }
      }
    }
  },
  "permission": {
    "webfetch": "allow",
    "websearch": "allow"
  }
}
```

## Docker

The other pieces involve Docker. I had to run `sudo apt install docker.io docker-compose` to cover my Debian system's needs.

I also had to play around with setup a bit, which I cannot properly claim is going to be the same system-to-system, nor am I going to claim that I fully recognize what was legitimate from what I did. I think the steps that matter were:

 - `sudo usermod -aG docker $USER`
 - `newgrp docker`
 - restart machine

## searxng

I installed searxng via [their Docker installation instructions](https://docs.searxng.org/admin/installation-docker.html#installation-container).

Though there were edits to their base config. Here's what my files ended up looking like:

`.env`:
```
SEARXNG_VERSION=latest
SEARXNG_HOST=
SEARXNG_PORT=8888
```

`docker-compose.yml`:
```
name: searxng

services:
  core:
    container_name: searxng-core
    image: docker.io/searxng/searxng:${SEARXNG_VERSION:-latest}
    restart: always
    ports:
      - "8888:8888"
    env_file: ./.env
    volumes:
      - ./core-config/:/etc/searxng/:Z
      - core-data:/var/cache/searxng/

  valkey:
    container_name: searxng-valkey
    image: docker.io/valkey/valkey:9-alpine
    command: valkey-server --save 30 1 --loglevel warning
    restart: always
    volumes:
      - valkey-data:/data/

volumes:
  core-data:
  valkey-data:
```

`settings.yml`:
```
use_default_settings: true
search:
  formats:
    - html
    - json
server:
  secret_key: "xyz"
  limiter: false
  public_instance: false
```

(for the secret key, I used the result of `openssl rand -hex 32`)

I placed my searxng files at `~/Development/ai/tools/searxng/`, with the following layout:

```
searxng/
  -> .env
  -> docker-compose.yml
  -> core-config/
    -> settings.yml
```

## open-webui

My instance of open-webui is handled through Docker directly, so is contained within the shell scripts, as per [the GitHub repo's Docker instructions](https://github.com/open-webui/open-webui#quick-start-with-docker-).

The lightly more complicated part is the setup that is to be done in the UI: to make sure it's setup to connect properly to both llama-server and searxng. Here is all that I remember, with no guarantee that these are all fully necessary.

`Profile llama-server connection:`

1. Click profile in top-right
2. Click "Settings" from drop-down
3. Click "Connections" in left-list
4. Add a direct connection for "http://127.0.0.1:11434"

`Admin llama-server connection:`

1. Click profile in top-right
2. Click "Admin Panel" from drop-down
3. Click "Settings" in top-menu
4. Click "Connections" in left-list
5. Disable "Ollama API"
6. Enable "Direct Connections"
7. Add an OpenAI API connection for "http://127.0.0.1:11434/v1"
8. "Auth" set to "None" and "qwen3.6" added to "Model IDs"

`Web search searxng connection:`

1. Click profile in top-right
2. Click "Admin Panel" from drop-down
3. Click "Settings" in top-menu
4. Click "Web Search" in left-list
5. Enable "Web Search"
6. Set "Web Search Engine" to "searxng"
7. Set "Searxng Query URL" to "http://host.docker.internal:8888/search?q=<query>"
8. Set "Searxng search language" to "en"
9. Set "Search Result Count" to 3 and "Concurrent Requests" to 1
10. Enable "Bypass Embedding and Retrieval"

# Credit

Benjamin Massey benjamin.w.massey@gmail.com
