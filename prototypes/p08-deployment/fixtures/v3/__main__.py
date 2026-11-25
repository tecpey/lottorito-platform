import json
import os

print(json.dumps({
    "product": "affiliate_agent",
    "version": "3.0.0",
    "runtime_secret_present": bool(os.environ.get("LOTTORITO_SYNTHETIC_RUNTIME_SECRET")),
}, sort_keys=True))
