"""Structured (JSON) logging on stdout — stdlib only, no dependency.

Hosting platforms capture stdout; emitting one JSON object per line makes logs
machine-parseable by any aggregator (Loki/Datadog/CloudWatch) without a shipper.
"""
import json
import logging
import sys
from datetime import datetime, timezone

# Fields a caller may attach via `logger.info(..., extra={...})` that we lift
# into the JSON payload (e.g. request method/path/status).
_EXTRA_FIELDS = ("method", "path", "status", "duration_ms")


class JsonFormatter(logging.Formatter):
    def format(self, record: logging.LogRecord) -> str:
        payload = {
            "ts": datetime.now(timezone.utc).isoformat(),
            "level": record.levelname,
            "logger": record.name,
            "message": record.getMessage(),
        }
        for key in _EXTRA_FIELDS:
            if key in record.__dict__:
                payload[key] = record.__dict__[key]
        if record.exc_info:
            payload["exc"] = self.formatException(record.exc_info)
        return json.dumps(payload)


def configure_logging(level: str = "INFO") -> None:
    handler = logging.StreamHandler(sys.stdout)
    handler.setFormatter(JsonFormatter())
    root = logging.getLogger()
    root.handlers = [handler]
    root.setLevel(level)
    # Route uvicorn/gunicorn's own loggers through our root handler so their
    # lines are JSON too. ponytail: uvicorn's access log text isn't reshaped
    # into our fields — the request middleware is the structured access log;
    # upgrade uvicorn's own log_config only if you need its fields as JSON.
    for name in ("uvicorn", "uvicorn.error", "uvicorn.access", "gunicorn.error"):
        lg = logging.getLogger(name)
        lg.handlers = []
        lg.propagate = True


if __name__ == "__main__":
    # ponytail: self-check the formatter emits valid JSON with the extras.
    rec = logging.LogRecord("t", logging.INFO, __file__, 1, "hi", None, None)
    rec.method, rec.path, rec.status, rec.duration_ms = "GET", "/x", 200, 3.4
    out = json.loads(JsonFormatter().format(rec))
    assert out["message"] == "hi" and out["status"] == 200 and out["path"] == "/x"
    assert out["level"] == "INFO"
    print("logging self-check ok")
