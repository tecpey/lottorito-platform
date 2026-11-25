import json
import os

print(json.dumps({
    "product": "__P08_PRODUCT_ID__",
    "version": "1.0.0",
    "runtime_secret_present": bool(os.environ.get("LOTTORITO_SYNTHETIC_RUNTIME_SECRET")),
    "host_canary_present": bool(os.environ.get("P08_HOST_ENV_CANARY")),
}, sort_keys=True))
