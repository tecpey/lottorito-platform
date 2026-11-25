"""Affiliate & Agent composition-only smoke; no business workflow is implemented."""
from platform_core import append_audit, build_context


def run() -> dict[str, object]:
    product_id = "affiliate_agent"
    context = build_context(product_id)
    return {"product_id": product_id, "status": "ok", "operation": "module_bootstrap_only", "audit": append_audit(context, "affiliate_agent.composition_smoke")}
