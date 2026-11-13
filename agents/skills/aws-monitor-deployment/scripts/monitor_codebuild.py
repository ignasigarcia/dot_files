#!/usr/bin/env python3
"""Authenticate with AWS SSO and follow one CodeBuild build to completion."""

from __future__ import annotations

import argparse
import datetime as dt
import json
import shutil
import subprocess
import sys
import time
from typing import Any


TERMINAL = {
    "SUCCEEDED",
    "FAILED",
    "FAULT",
    "STOPPED",
    "TIMED_OUT",
}

READ_ONLY_OPERATIONS = {
    ("sts", "get-caller-identity"),
    ("codebuild", "list-builds-for-project"),
    ("codebuild", "batch-get-builds"),
    ("codepipeline", "list-pipeline-executions"),
    ("codepipeline", "get-pipeline-execution"),
    ("codepipeline", "list-action-executions"),
    ("logs", "get-log-events"),
    ("deploy", "get-deployment"),
}


class AwsError(RuntimeError):
    pass


def aws(args: list[str], profile: str, region: str | None = None) -> Any:
    operation = tuple(args[:2])
    if operation not in READ_ONLY_OPERATIONS:
        rendered = " ".join(args[:2]) if len(args) >= 2 else " ".join(args)
        raise AwsError(f"Refusing AWS operation outside read-only allowlist: {rendered}")
    command = ["aws", "--no-cli-pager", "--profile", profile]
    if region:
        command += ["--region", region]
    command += args + ["--output", "json"]
    result = subprocess.run(command, text=True, capture_output=True)
    if result.returncode:
        message = (result.stderr or result.stdout).strip()
        raise AwsError(message or f"AWS CLI exited with {result.returncode}")
    try:
        return json.loads(result.stdout or "null")
    except json.JSONDecodeError as exc:
        raise AwsError(f"AWS CLI returned invalid JSON: {exc}") from exc


def configured_region(profile: str) -> str | None:
    result = subprocess.run(
        ["aws", "configure", "get", "region", "--profile", profile],
        text=True,
        capture_output=True,
    )
    value = result.stdout.strip()
    return value or None


def login(profile: str) -> None:
    print(f"Opening AWS SSO login for profile {profile!r}...", flush=True)
    result = subprocess.run(["aws", "sso", "login", "--profile", profile])
    if result.returncode:
        raise AwsError(f"AWS SSO login exited with {result.returncode}")


def authenticate(profile: str, region: str, force_login: bool) -> dict[str, Any]:
    if force_login:
        login(profile)
    try:
        return aws(["sts", "get-caller-identity"], profile, region)
    except AwsError as first_error:
        if force_login:
            raise
        print(f"AWS session is unavailable: {first_error}", file=sys.stderr, flush=True)
        login(profile)
        return aws(["sts", "get-caller-identity"], profile, region)


def latest_build_id(project: str, profile: str, region: str) -> str | None:
    data = aws(
        [
            "codebuild",
            "list-builds-for-project",
            "--project-name",
            project,
            "--sort-order",
            "DESCENDING",
            "--max-items",
            "1",
        ],
        profile,
        region,
    )
    ids = data.get("ids", [])
    return ids[0] if ids else None


def get_build(build_id: str, profile: str, region: str) -> dict[str, Any]:
    data = aws(
        ["codebuild", "batch-get-builds", "--ids", build_id],
        profile,
        region,
    )
    builds = data.get("builds", [])
    if not builds:
        raise AwsError(f"Build not found: {build_id}")
    return builds[0]


def select_build(
    project: str,
    build_id: str | None,
    wait_seconds: int,
    profile: str,
    region: str,
) -> dict[str, Any]:
    if build_id:
        return get_build(build_id, profile, region)

    initial_id = latest_build_id(project, profile, region)
    initial = get_build(initial_id, profile, region) if initial_id else None
    if initial and initial.get("buildStatus") not in TERMINAL:
        return initial
    if wait_seconds <= 0:
        if initial:
            return initial
        raise AwsError(f"No builds found for project {project!r}")

    deadline = time.monotonic() + wait_seconds
    print(f"Waiting up to {wait_seconds}s for a new build of {project}...", flush=True)
    while time.monotonic() < deadline:
        candidate_id = latest_build_id(project, profile, region)
        if candidate_id and candidate_id != initial_id:
            return get_build(candidate_id, profile, region)
        time.sleep(min(5, max(0.2, deadline - time.monotonic())))
    raise AwsError(f"No new build started within {wait_seconds}s")


def timestamp(milliseconds: int) -> str:
    instant = dt.datetime.fromtimestamp(milliseconds / 1000, tz=dt.timezone.utc)
    return instant.astimezone().strftime("%H:%M:%S")


def print_events(
    group: str,
    stream: str,
    token: str | None,
    start_time: int | None,
    profile: str,
    region: str,
) -> tuple[str | None, int]:
    args = [
        "logs",
        "get-log-events",
        "--log-group-name",
        group,
        "--log-stream-name",
        stream,
        "--start-from-head",
    ]
    if token:
        args += ["--next-token", token]
    elif start_time is not None:
        args += ["--start-time", str(start_time)]
    data = aws(args, profile, region)
    events = data.get("events", [])
    for event in events:
        message = event.get("message", "").rstrip("\n")
        print(f"[{timestamp(event['timestamp'])}] {message}", flush=True)
    return data.get("nextForwardToken"), len(events)


def failure_context(build: dict[str, Any]) -> None:
    for phase in build.get("phases", []):
        if phase.get("phaseStatus") in {"FAILED", "FAULT", "TIMED_OUT", "STOPPED"}:
            print(f"Failed phase: {phase.get('phaseType')}", file=sys.stderr)
            for context in phase.get("contexts", []):
                message = context.get("message")
                if message:
                    print(f"  {message}", file=sys.stderr)


def monitor(
    build: dict[str, Any],
    profile: str,
    region: str,
    poll: float,
    since: int,
    from_start: bool,
) -> int:
    build_id = build["id"]
    logs = build.get("logs", {})
    group = logs.get("groupName")
    stream = logs.get("streamName")
    print(f"Build: {build_id}")
    print(f"Source revision: {build.get('resolvedSourceVersion') or build.get('sourceVersion')}")
    print(f"Console: {logs.get('deepLink', 'unavailable')}")

    token: str | None = None
    start_time = None if from_start else int((time.time() - since) * 1000)
    if from_start:
        print("Log window: complete build log", flush=True)
    else:
        print(f"Log window: last {since}s, then follow", flush=True)
    last_state: tuple[str | None, str | None] | None = None
    terminal_seen = False
    while True:
        build = get_build(build_id, profile, region)
        state = (build.get("buildStatus"), build.get("currentPhase"))
        if state != last_state:
            print(f"Status: {state[0]} | Phase: {state[1]}", flush=True)
            last_state = state

        if group and stream:
            try:
                token, count = print_events(
                    group,
                    stream,
                    token,
                    start_time,
                    profile,
                    region,
                )
            except AwsError as error:
                print(f"CloudWatch logs unavailable: {error}", file=sys.stderr, flush=True)
                count = 0
        else:
            count = 0

        if state[0] in TERMINAL:
            if terminal_seen or count == 0:
                break
            terminal_seen = True
        time.sleep(poll)

    print(f"Final status: {build.get('buildStatus')}", flush=True)
    if build.get("buildStatus") != "SUCCEEDED":
        failure_context(build)
        return 1
    return 0


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--project", required=True, help="CodeBuild project name")
    parser.add_argument("--build-id", help="Specific CodeBuild ID (PROJECT:UUID)")
    parser.add_argument("--profile", default="grm", help="AWS CLI profile (default: grm)")
    parser.add_argument("--region", help="AWS region; defaults to the profile region")
    parser.add_argument("--login", action="store_true", help="Run AWS SSO login first")
    parser.add_argument(
        "--wait-for-start",
        type=int,
        default=0,
        metavar="SECONDS",
        help="Wait for a new build if the latest build is already complete",
    )
    parser.add_argument("--poll", type=float, default=5.0, help="Polling interval in seconds")
    parser.add_argument(
        "--since",
        type=int,
        default=120,
        metavar="SECONDS",
        help="Initially show this many recent log seconds (default: 120)",
    )
    parser.add_argument(
        "--from-start",
        action="store_true",
        help="Replay the complete build log before following",
    )
    return parser.parse_args()


def main() -> int:
    args = parse_args()
    if not shutil.which("aws"):
        print("AWS CLI is not installed or not on PATH", file=sys.stderr)
        return 2
    region = args.region or configured_region(args.profile)
    if not region:
        print("No AWS region configured; pass --region", file=sys.stderr)
        return 2
    if args.wait_for_start < 0 or args.poll <= 0 or args.since < 0:
        print(
            "--wait-for-start and --since must be >= 0; --poll must be > 0",
            file=sys.stderr,
        )
        return 2
    try:
        identity = authenticate(args.profile, region, args.login)
        print(f"Authenticated: account {identity.get('Account')} | region {region}")
        build = select_build(
            args.project,
            args.build_id,
            args.wait_for_start,
            args.profile,
            region,
        )
        return monitor(
            build,
            args.profile,
            region,
            args.poll,
            args.since,
            args.from_start,
        )
    except KeyboardInterrupt:
        print("\nMonitoring stopped by user", file=sys.stderr)
        return 130
    except AwsError as error:
        print(f"AWS error: {error}", file=sys.stderr)
        return 2


if __name__ == "__main__":
    raise SystemExit(main())
