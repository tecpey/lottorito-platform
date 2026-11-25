import json
import os

print(json.dumps({
    "product": "affiliate_agent",
    "version": "3.0.0",
    "runtime_secret_present": bool(os.environ.get("LOTTORITO_SYNTHETIC_RUNTIME_SECRET")),
    "host_canary_present": bool(os.environ.get("P08_HOST_ENV_CANARY")),
}, sort_keys=True))
