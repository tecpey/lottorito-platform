const UUID_PATTERN = /^[0-9a-f]{8}-[0-9a-f]{4}-[1-8][0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$/i;
const AMOUNT_PATTERN = /^[1-9][0-9]{0,37}$/;

function requireUuid(value, field) {
  if (typeof value !== "string" || !UUID_PATTERN.test(value)) {
    throw new TypeError(field + " must be a valid UUID");
  }
  return value.toLowerCase();
}

export function normalizeJournalRequest(input) {
  if (!input || typeof input !== "object" || Array.isArray(input)) {
    throw new TypeError("journal request must be an object");
  }
  const allowed = new Set(["idempotency_key", "effect_id", "source_event_id", "lines"]);
  if (Object.keys(input).some((key) => !allowed.has(key))) {
    throw new TypeError("journal request contains unsupported fields");
  }

  const { idempotency_key, effect_id, source_event_id, lines } = input;
  if (
    typeof idempotency_key !== "string" ||
    !/^[A-Za-z0-9._:-]{1,128}$/.test(idempotency_key)
  ) {
    throw new TypeError("idempotency_key must contain 1 to 128 safe characters");
  }

  const normalizedEffectId = requireUuid(effect_id, "effect_id");
  const normalizedSourceEventId = requireUuid(source_event_id, "source_event_id");
  if (!Array.isArray(lines) || lines.length < 2 || lines.length > 100) {
    throw new TypeError("journal must contain between 2 and 100 lines");
  }

  const normalizedLines = lines.map((line) => {
    if (!line || typeof line !== "object" || Array.isArray(line)) {
      throw new TypeError("each journal line must be an object");
    }
    const expected = ["line_no", "account_id", "currency_code", "direction", "amount_minor"];
    if (Object.keys(line).length !== expected.length || expected.some((key) => !(key in line))) {
      throw new TypeError("journal line fields are invalid");
    }
    if (!Number.isInteger(line.line_no) || line.line_no < 1 || line.line_no > 100) {
      throw new TypeError("line_no must be an integer between 1 and 100");
    }
    const accountId = requireUuid(line.account_id, "account_id");
    if (typeof line.currency_code !== "string" || !/^[A-Z]{3}$/.test(line.currency_code)) {
      throw new TypeError("currency_code must be a three-letter uppercase code");
    }
    if (line.direction !== "debit" && line.direction !== "credit") {
      throw new TypeError("direction must be debit or credit");
    }
    if (typeof line.amount_minor !== "string" || !AMOUNT_PATTERN.test(line.amount_minor)) {
      throw new TypeError("amount_minor must be an exact positive integer string of at most 38 digits");
    }
    return {
      line_no: line.line_no,
      account_id: accountId,
      currency_code: line.currency_code,
      direction: line.direction,
      amount_minor: line.amount_minor
    };
  }).sort((a, b) => a.line_no - b.line_no);

  if (new Set(normalizedLines.map((line) => line.line_no)).size !== normalizedLines.length) {
    throw new TypeError("line_no values must be unique");
  }

  return {
    idempotency_key,
    effect_id: normalizedEffectId,
    source_event_id: normalizedSourceEventId,
    lines: normalizedLines
  };
}

export async function postJournal(pool, input) {
  if (!pool || typeof pool.query !== "function") {
    throw new TypeError("a tenant-bound PostgreSQL pool is required");
  }
  const request = normalizeJournalRequest(input);
  const result = await pool.query(
    "SELECT journal_id, duplicate FROM public.post_journal($1, $2, $3, $4::jsonb)",
    [request.idempotency_key, request.effect_id, request.source_event_id, JSON.stringify(request.lines)]
  );
  if (result.rowCount !== 1 || !result.rows[0]?.journal_id) {
    throw new Error("ledger posting returned an invalid result");
  }
  return {
    journal_id: result.rows[0].journal_id,
    duplicate: result.rows[0].duplicate
  };
}
