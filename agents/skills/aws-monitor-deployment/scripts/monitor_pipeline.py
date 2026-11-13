#!/usr/bin/env python3
"""Follow an AWS CodePipeline release, its CodeBuild logs, and deployment action."""

from __future__ import annotations

import argparse
import re
import shutil
import sys
import time
from typing import Any

import monitor_codebuild as cb


PIPELINE_TERMINAL = {"Succeeded", "Failed", "Stopped", "Superseded"}
ANSI_RE = re.compile(r"\x1b\[[0-?]*[ -/]*[@-~]")
ERROR_RE = re.compile(
    r"(?:\b(?:error|fatal|failed|failure|exception)\b|npm ERR!|ELIFECYCLE|"
    r"command did not exit successfully|exit code [1-9]|Phase complete: .*FAILED)",
    re.IGNORECASE,
)
MIGRATION_RE = re.compile(
    r"(?:\bmigrat(?:e|es|ed|ing|ion|ions)\b|db:migrate|payload migrate|"
    r"prisma migrate|alembic|flyway|liquibase|knex migrate|sequelize db:migrate)",
    re.IGNORECASE,
)
MIGRATION_SUCCESS_RE = re.compile(
    r"(?:migration.*(?:succeed|complete|done|up[- ]to[- ]date|no pending)|"
    r"(?:succeed|complete|finish)(?:ed|fully)?.*migration)",
    re.IGNORECASE,
)
NEXT_BUILD_STEP_RE = re.compile(
    r"(?:\$\s+(?:vite|next)\s+build|creating an optimized production build)",
    re.IGNORECASE,
)


def latest_execution(pipeline: str, profile: str, region: str) -> dict[str, Any] | None:
    data = cb.aws(
        [
            "codepipeline",
            "list-pipeline-executions",
            "--pipeline-name",
            pipeline,
            "--max-results",
            "1",
        ],
        profile,
        region,
    )
    executions = data.get("pipelineExecutionSummaries", [])
    return executions[0] if executions else None


def select_execution(
    pipeline: str,
    execution_id: str | None,
    wait_seconds: int,
    profile: str,
    region: str,
) -> dict[str, Any]:
    if execution_id:
        return {"pipelineExecutionId": execution_id}

    initial = latest_execution(pipeline, profile, region)
    if initial and initial.get("status") not in PIPELINE_TERMINAL:
        return initial
    if wait_seconds <= 0:
        if initial:
            return initial
        raise cb.AwsError(f"No executions found for pipeline {pipeline!r}")

    initial_id = initial.get("pipelineExecutionId") if initial else None
    deadline = time.monotonic() + wait_seconds
    print(f"Waiting up to {wait_seconds}s for a new {pipeline} execution...", flush=True)
    while time.monotonic() < deadline:
        candidate = latest_execution(pipeline, profile, region)
        if candidate and candidate.get("pipelineExecutionId") != initial_id:
            return candidate
        time.sleep(min(5, max(0.2, deadline - time.monotonic())))
    raise cb.AwsError(f"No new pipeline execution started within {wait_seconds}s")


def get_execution(
    pipeline: str,
    execution_id: str,
    profile: str,
    region: str,
) -> dict[str, Any]:
    data = cb.aws(
        [
            "codepipeline",
            "get-pipeline-execution",
            "--pipeline-name",
            pipeline,
            "--pipeline-execution-id",
            execution_id,
        ],
        profile,
        region,
    )
    return data["pipelineExecution"]


def get_actions(
    pipeline: str,
    execution_id: str,
    profile: str,
    region: str,
) -> list[dict[str, Any]]:
    data = cb.aws(
        [
            "codepipeline",
            "list-action-executions",
            "--pipeline-name",
            pipeline,
            "--filter",
            f"pipelineExecutionId={execution_id}",
            "--max-results",
            "100",
        ],
        profile,
        region,
    )
    return sorted(
        data.get("actionExecutionDetails", []),
        key=lambda action: str(action.get("startTime", "")),
    )


def category(action: dict[str, Any]) -> str | None:
    return action.get("input", {}).get("actionTypeId", {}).get("category")


def provider(action: dict[str, Any]) -> str | None:
    return action.get("input", {}).get("actionTypeId", {}).get("provider")


def external_id(action: dict[str, Any]) -> str | None:
    return action.get("output", {}).get("executionResult", {}).get("externalExecutionId")


def clean_line(line: str) -> str:
    return ANSI_RE.sub("", line).strip()


def useful_error(line: str) -> bool:
    if not ERROR_RE.search(line):
        return False
    lowered = line.lower()
    without_buildkit_prefix = re.sub(r"^#\d+\s+\S+\s+", "", line).strip()
    if re.match(r"^(?:adding|updating):\s+\S", without_buildkit_prefix, re.IGNORECASE):
        return False
    if re.match(r"^\+\s+\S", without_buildkit_prefix):
        return False
    if re.match(r"^echo\s+", without_buildkit_prefix, re.IGNORECASE):
        return False
    return not any(
        phrase in lowered
        for phrase in ("0 errors", "no errors", "error boundary", "errorhandler")
    )


def analyze_build_logs(
    build: dict[str, Any],
    profile: str,
    region: str,
) -> dict[str, Any]:
    logs = build.get("logs", {})
    group = logs.get("groupName")
    stream = logs.get("streamName")
    analysis: dict[str, Any] = {
        "errors": [],
        "migration_status": "NOT OBSERVED",
        "migration_evidence": [],
    }
    if not group or not stream:
        analysis["migration_status"] = "UNKNOWN - CloudWatch log stream unavailable"
        return analysis

    token: str | None = None
    migration_seen = False
    migration_active = False
    migration_success = False
    migration_failed = False
    chained_migration = False
    later_build_started = False
    while True:
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
        data = cb.aws(args, profile, region)
        for event in data.get("events", []):
            for raw_line in event.get("message", "").splitlines():
                line = clean_line(raw_line)
                if not line:
                    continue
                is_error = useful_error(line)
                if is_error and line not in analysis["errors"] and len(analysis["errors"]) < 12:
                    analysis["errors"].append(line[:500])

                if MIGRATION_RE.search(line):
                    migration_seen = True
                    migration_active = True
                    chained_migration = chained_migration or "&&" in line
                    if (
                        line not in analysis["migration_evidence"]
                        and len(analysis["migration_evidence"]) < 8
                    ):
                        analysis["migration_evidence"].append(line[:500])
                    if MIGRATION_SUCCESS_RE.search(line):
                        migration_success = True

                if migration_active:
                    if MIGRATION_SUCCESS_RE.search(line) or re.search(
                        r"\bINFO\b.*\bDone\.?(?:\s|$)", line, re.IGNORECASE
                    ):
                        migration_success = True
                        if (
                            line not in analysis["migration_evidence"]
                            and len(analysis["migration_evidence"]) < 8
                        ):
                            analysis["migration_evidence"].append(line[:500])
                    if is_error:
                        migration_failed = True
                    if NEXT_BUILD_STEP_RE.search(line) and not MIGRATION_RE.search(line):
                        later_build_started = True
                        migration_active = False

        next_token = data.get("nextForwardToken")
        if not next_token or next_token == token:
            break
        token = next_token

    build_succeeded = build.get("buildStatus") == "SUCCEEDED"
    if migration_failed:
        analysis["migration_status"] = "FAILED OR ERROR DETECTED"
    elif migration_success:
        analysis["migration_status"] = "SUCCEEDED - explicit completion evidence"
    elif migration_seen and build_succeeded and chained_migration and later_build_started:
        analysis["migration_status"] = (
            "SUCCEEDED - inferred from chained command continuing to the build"
        )
    elif migration_seen:
        analysis["migration_status"] = "OBSERVED - completion not proven"
    return analysis


def get_deployment(
    deployment_id: str,
    profile: str,
    region: str,
) -> dict[str, Any]:
    data = cb.aws(
        ["deploy", "get-deployment", "--deployment-id", deployment_id],
        profile,
        region,
    )
    return data["deploymentInfo"]


def print_summary(
    pipeline: str,
    execution: dict[str, Any],
    actions: list[dict[str, Any]],
    build: dict[str, Any] | None,
    analysis: dict[str, Any] | None,
    deployment: dict[str, Any] | None,
) -> bool:
    source = next((action for action in actions if category(action) == "Source"), None)
    build_action = next((action for action in actions if category(action) == "Build"), None)
    deploy_actions = [action for action in actions if category(action) == "Deploy"]
    pipeline_status = execution.get("status")
    deployed = bool(
        pipeline_status == "Succeeded"
        and deploy_actions
        and all(action.get("status") == "Succeeded" for action in deploy_actions)
    )

    print("\n=== Deployment summary ===")
    print(f"Pipeline: {pipeline}")
    print(f"Execution: {execution.get('pipelineExecutionId')}")
    print(f"Pipeline status: {pipeline_status}")
    if source:
        print(f"Source revision: {external_id(source) or 'unknown'}")
    if build_action:
        print(
            f"CodeBuild: {build_action.get('status')} | "
            f"{external_id(build_action) or 'build ID unavailable'}"
        )
    if analysis:
        print(f"Migrations: {analysis['migration_status']}")
        for evidence in analysis["migration_evidence"][-3:]:
            print(f"  evidence: {evidence}")
        if analysis["errors"]:
            qualifier = " (non-fatal; CodeBuild succeeded)" if build and build.get("buildStatus") == "SUCCEEDED" else ""
            print(f"Potential build errors{qualifier}:")
            for error in analysis["errors"]:
                print(f"  - {error}")
        else:
            print("Potential build errors: none detected")
    elif build:
        print("Migrations: UNKNOWN - log analysis did not run")

    for action in deploy_actions:
        print(
            f"Deploy action {action.get('stageName')}/{action.get('actionName')}: "
            f"{action.get('status')} | {external_id(action) or 'deployment ID unavailable'}"
        )
    if deployment:
        overview = deployment.get("deploymentOverview", {})
        print(
            "CodeDeploy targets: "
            f"{deployment.get('status')} | succeeded={overview.get('Succeeded', 0)} "
            f"failed={overview.get('Failed', 0)} "
            f"in_progress={overview.get('InProgress', 0)}"
        )

    if deployed:
        print("Final verdict: DEPLOYED")
    elif pipeline_status == "Succeeded" and not deploy_actions:
        print("Final verdict: PIPELINE SUCCEEDED, BUT NO DEPLOY ACTION WAS VERIFIED")
    else:
        print("Final verdict: NOT DEPLOYED SUCCESSFULLY")
    return deployed


def monitor(args: argparse.Namespace, profile: str, region: str) -> int:
    selected = select_execution(
        args.pipeline,
        args.execution_id,
        args.wait_for_start,
        profile,
        region,
    )
    execution_id = selected["pipelineExecutionId"]
    print(f"Pipeline: {args.pipeline}")
    print(f"Execution: {execution_id}")

    last_pipeline_status: str | None = None
    action_states: dict[str, str] = {}
    monitored_build_id: str | None = None
    build: dict[str, Any] | None = None
    analysis: dict[str, Any] | None = None
    deployment: dict[str, Any] | None = None
    deployment_state: str | None = None

    while True:
        execution = get_execution(args.pipeline, execution_id, profile, region)
        actions = get_actions(args.pipeline, execution_id, profile, region)
        pipeline_status = execution.get("status")
        if pipeline_status != last_pipeline_status:
            print(f"Pipeline status: {pipeline_status}", flush=True)
            last_pipeline_status = pipeline_status

        for action in actions:
            key = f"{action.get('stageName')}/{action.get('actionName')}"
            state = action.get("status", "Unknown")
            if action_states.get(key) != state:
                print(
                    f"Action: {key} | {category(action)}/{provider(action)} | {state}",
                    flush=True,
                )
                action_states[key] = state

        build_action = next(
            (
                action
                for action in actions
                if category(action) == "Build" and provider(action) == "CodeBuild"
            ),
            None,
        )
        build_id = external_id(build_action) if build_action else None
        if build_id and build_id != monitored_build_id:
            build = cb.get_build(build_id, profile, region)
            cb.monitor(
                build,
                profile,
                region,
                args.poll,
                args.since,
                args.from_start,
            )
            build = cb.get_build(build_id, profile, region)
            analysis = analyze_build_logs(build, profile, region)
            monitored_build_id = build_id

        deploy_action = next(
            (
                action
                for action in actions
                if category(action) == "Deploy" and provider(action) == "CodeDeploy"
            ),
            None,
        )
        deployment_id = external_id(deploy_action) if deploy_action else None
        if deployment_id:
            deployment = get_deployment(deployment_id, profile, region)
            overview = deployment.get("deploymentOverview", {})
            state = (
                f"{deployment.get('status')} "
                f"(succeeded={overview.get('Succeeded', 0)}, "
                f"failed={overview.get('Failed', 0)}, "
                f"in_progress={overview.get('InProgress', 0)})"
            )
            if state != deployment_state:
                print(f"CodeDeploy: {deployment_id} | {state}", flush=True)
                deployment_state = state

        if pipeline_status in PIPELINE_TERMINAL:
            deployed = print_summary(
                args.pipeline,
                execution,
                actions,
                build,
                analysis,
                deployment,
            )
            return 0 if deployed else 1
        time.sleep(args.poll)


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--pipeline", required=True, help="CodePipeline name")
    parser.add_argument("--execution-id", help="Specific pipeline execution ID")
    parser.add_argument("--profile", default="grm", help="AWS CLI profile (default: grm)")
    parser.add_argument("--region", help="AWS region; defaults to the profile region")
    parser.add_argument("--login", action="store_true", help="Run AWS SSO login first")
    parser.add_argument(
        "--wait-for-start",
        type=int,
        default=0,
        metavar="SECONDS",
        help="Wait for a new execution if the latest is already complete",
    )
    parser.add_argument("--poll", type=float, default=5.0, help="Polling interval in seconds")
    parser.add_argument(
        "--since",
        type=int,
        default=120,
        metavar="SECONDS",
        help="Initially show this many recent CodeBuild log seconds",
    )
    parser.add_argument(
        "--from-start",
        action="store_true",
        help="Replay the complete CodeBuild log while tailing",
    )
    return parser.parse_args()


def main() -> int:
    args = parse_args()
    if not shutil.which("aws"):
        print("AWS CLI is not installed or not on PATH", file=sys.stderr)
        return 2
    region = args.region or cb.configured_region(args.profile)
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
        identity = cb.authenticate(args.profile, region, args.login)
        print(f"Authenticated: account {identity.get('Account')} | region {region}")
        return monitor(args, args.profile, region)
    except KeyboardInterrupt:
        print("\nMonitoring stopped by user", file=sys.stderr)
        return 130
    except cb.AwsError as error:
        print(f"AWS error: {error}", file=sys.stderr)
        return 2


if __name__ == "__main__":
    raise SystemExit(main())
