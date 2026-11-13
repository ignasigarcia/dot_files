#!/usr/bin/env python3
"""Run read-only CloudWatch Logs Insights searches across app environments."""

from __future__ import annotations

import argparse
import json
import subprocess
import sys
import time
from datetime import datetime, timedelta, timezone
from typing import Any


DEFAULT_GROUPS = ["gai-dev", "gai-stg", "gai-prd"]


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--profile", default="grm")
    parser.add_argument("--region", help="Defaults to the AWS profile region")
    parser.add_argument("--groups", nargs="+", default=DEFAULT_GROUPS)
    parser.add_argument("--hours", type=float, default=24.0)
    parser.add_argument("--search", help="Case-sensitive literal message substring")
    parser.add_argument("--query-string", help="Complete CloudWatch Logs Insights query")
    parser.add_argument("--mode", choices=["summary", "events"], default="summary")
    parser.add_argument("--limit", type=int, default=200)
    parser.add_argument("--poll-seconds", type=float, default=1.0)
    parser.add_argument("--timeout-seconds", type=float, default=60.0)
    args = parser.parse_args()

    if bool(args.search) == bool(args.query_string):
        parser.error("provide exactly one of --search or --query-string")
    if args.hours <= 0:
        parser.error("--hours must be positive")
    if not 1 <= args.limit <= 10_000:
        parser.error("--limit must be between 1 and 10000")
    return args


def aws_json(args: list[str]) -> dict[str, Any]:
    completed = subprocess.run(args, check=False, capture_output=True, text=True)
    if completed.returncode != 0:
        message = completed.stderr.strip() or completed.stdout.strip()
        raise RuntimeError(message or f"AWS CLI exited {completed.returncode}")
    return json.loads(completed.stdout)


def resolve_region(profile: str, explicit_region: str | None) -> str:
    if explicit_region:
        return explicit_region
    completed = subprocess.run(
        ["aws", "configure", "get", "region", "--profile", profile],
        check=False,
        capture_output=True,
        text=True,
    )
    region = completed.stdout.strip()
    if completed.returncode != 0 or not region:
        raise RuntimeError(f"No region configured for AWS profile {profile!r}")
    return region


def build_query(search: str, mode: str, limit: int) -> str:
    literal = json.dumps(search)
    predicate = f"@message like {literal}"
    if mode == "summary":
        return (
            "fields @timestamp, @log, @message "
            f"| filter {predicate} "
            "| stats min(@timestamp) as firstSeen, max(@timestamp) as lastSeen, "
            "count(*) as matchingLines by @log | sort @log asc"
        )
    return (
        "fields @timestamp, @log, @logStream, @message "
        f"| filter {predicate} | sort @timestamp desc | limit {limit}"
    )


def row_to_dict(row: list[dict[str, str]]) -> dict[str, str]:
    return {cell["field"]: cell.get("value", "") for cell in row}


def main() -> int:
    args = parse_args()
    try:
        region = resolve_region(args.profile, args.region)
        query = args.query_string or build_query(args.search, args.mode, args.limit)
        end = datetime.now(timezone.utc)
        start = end - timedelta(hours=args.hours)

        command = [
            "aws",
            "logs",
            "start-query",
            "--profile",
            args.profile,
            "--region",
            region,
            "--log-group-names",
            *args.groups,
            "--start-time",
            str(int(start.timestamp())),
            "--end-time",
            str(int(end.timestamp())),
            "--query-string",
            query,
            "--output",
            "json",
        ]
        query_id = aws_json(command)["queryId"]

        deadline = time.monotonic() + args.timeout_seconds
        while True:
            response = aws_json(
                [
                    "aws",
                    "logs",
                    "get-query-results",
                    "--profile",
                    args.profile,
                    "--region",
                    region,
                    "--query-id",
                    query_id,
                    "--output",
                    "json",
                ]
            )
            status = response.get("status")
            if status in {"Complete", "Failed", "Cancelled", "Timeout"}:
                break
            if time.monotonic() >= deadline:
                raise RuntimeError(f"query {query_id} did not finish within the timeout")
            time.sleep(args.poll_seconds)

        if status != "Complete":
            raise RuntimeError(f"CloudWatch query {query_id} ended with status {status}")

        output = {
            "queryId": query_id,
            "status": status,
            "profile": args.profile,
            "region": region,
            "groups": args.groups,
            "startUtc": start.isoformat(),
            "endUtc": end.isoformat(),
            "results": [row_to_dict(row) for row in response.get("results", [])],
            "statistics": response.get("statistics", {}),
        }
        print(json.dumps(output, indent=2, ensure_ascii=False))
        return 0
    except (FileNotFoundError, KeyError, RuntimeError, json.JSONDecodeError) as error:
        print(f"error: {error}", file=sys.stderr)
        return 1


if __name__ == "__main__":
    raise SystemExit(main())
