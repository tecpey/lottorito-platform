"""Synthetic shared-platform ports for P-07A; not production identity or audit code."""

SYNTHETIC_TENANT_ID = "tenant-p07a-synthetic"
SYNTHETIC_ACTOR_ID = "actor-p07a-synthetic"


def build_context(product_id: str) -> dict[str, str]:
    if product_id not in {"affiliate_agent", "lottery"}:
        raise ValueError("unknown product composition")
    return {"product_id": product_id, "tenant_id": SYNTHETIC_TENANT_ID, "actor_id": SYNTHETIC_ACTOR_ID}


def append_audit(context: dict[str, str], event_type: str) -> dict[str, str]:
    if context.get("product_id") not in {"affiliate_agent", "lottery"}:
        raise ValueError("invalid product context")
    if not event_type.endswith(".composition_smoke"):
        raise ValueError("P-07A only permits composition smoke events")
    return {"product_id": context["product_id"], "tenant_id": context["tenant_id"], "event_type": event_type, "outcome": "accepted"}
