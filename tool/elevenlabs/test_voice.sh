#!/usr/bin/env bash
# Checks whether an ElevenLabs voice can be used for text-to-speech with your
# API key, e.g. a Voice Library voice that isn't in "My Voices".
#
# Usage: ELEVENLABS_API_KEY=... tool/elevenlabs/test_voice.sh <voice_id> [text]
#
# 200 + a playable test_voice.mp3 -> the voice works as-is; add its id to
#   lib/constants/voices.dart.
# 4xx -> the voice must be added to My Voices on elevenlabs.io first; the
#   error body is printed.
set -euo pipefail

voice_id="${1:?usage: $0 <voice_id> [text]}"
text="${2:-Bonjour, comment ça va ?}"
: "${ELEVENLABS_API_KEY:?set ELEVENLABS_API_KEY}"
out="test_voice.mp3"

status=$(curl -sS -X POST \
  "https://api.elevenlabs.io/v1/text-to-speech/${voice_id}?output_format=mp3_44100_128" \
  -H "xi-api-key: ${ELEVENLABS_API_KEY}" \
  -H "Content-Type: application/json" \
  -d "$(python3 -c 'import json,sys; print(json.dumps({"text": sys.argv[1], "model_id": "eleven_multilingual_v2", "language_code": "fr"}))' "$text")" \
  -o "$out" -w "%{http_code}")

echo "HTTP $status"
if [ "$status" = "200" ]; then
  echo "OK: voice $voice_id works. Audio saved to $out"
else
  cat "$out"; echo
  rm -f "$out"
  exit 1
fi
