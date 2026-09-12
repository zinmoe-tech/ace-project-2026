import os
import json
import base64
import time
import urllib.request
import urllib.error
import urllib.parse

import boto3
from botocore.auth import SigV4Auth
from botocore.awsrequest import AWSRequest


def vault_aws_login(vault_addr, vault_namespace, vault_aws_role):
    credentials = (
        boto3.Session()
        .get_credentials()
        .get_frozen_credentials()
    )

    sts_url = "https://sts.amazonaws.com/"
    sts_body = "Action=GetCallerIdentity&Version=2011-06-15"

    aws_request = AWSRequest(
        method="POST",
        url=sts_url,
        data=sts_body,
        headers={
            "Content-Type":
                "application/x-www-form-urlencoded; charset=utf-8",
            "Host": "sts.amazonaws.com",
        },
    )

    SigV4Auth(
        credentials,
        "sts",
        "us-east-1",
    ).add_auth(aws_request)

    signed_headers = dict(aws_request.headers.items())

    vault_login_payload = {
        "role": vault_aws_role,
        "iam_http_request_method": "POST",
        "iam_request_url": base64.b64encode(
            sts_url.encode()
        ).decode(),
        "iam_request_body": base64.b64encode(
            sts_body.encode()
        ).decode(),
        "iam_request_headers": base64.b64encode(
            json.dumps(signed_headers).encode()
        ).decode(),
    }

    vault_login_request = urllib.request.Request(
        f"{vault_addr}/v1/auth/aws/login",
        data=json.dumps(vault_login_payload).encode(),
        method="POST",
        headers={
            "Content-Type": "application/json",
            "X-Vault-Namespace": vault_namespace,
        },
    )

    with urllib.request.urlopen(
        vault_login_request,
        timeout=10,
    ) as response:
        vault_login_result = json.loads(
            response.read().decode()
        )

    vault_token = vault_login_result["auth"]["client_token"]
    print("Vault AWS authentication successful")
    return vault_token


def vault_read_kv2(vault_addr, namespace, token, api_path):
    request = urllib.request.Request(
        f"{vault_addr}/v1/{api_path}",
        method="GET",
        headers={
            "X-Vault-Token": token,
            "X-Vault-Namespace": namespace,
        },
    )

    with urllib.request.urlopen(request, timeout=10) as response:
        result = json.loads(response.read().decode())

    return result["data"]["data"]


def boundary_login(boundary_addr, auth_method_id, login_name, password):
    payload = {
        "attributes": {
            "login_name": login_name,
            "password": password,
        },
        "command": "login",
    }

    request = urllib.request.Request(
        f"{boundary_addr}/v1/auth-methods/"
        f"{auth_method_id}:authenticate",
        data=json.dumps(payload).encode(),
        method="POST",
        headers={"Content-Type": "application/json"},
    )

    with urllib.request.urlopen(request, timeout=10) as response:
        result = json.loads(response.read().decode())

    print("Boundary authentication successful")
    return result["attributes"]["token"]


def get_active_sessions(boundary_addr, boundary_token, scope_id):
    query = urllib.parse.urlencode({
        "scope_id": scope_id,
        "recursive": "true",
    })

    request = urllib.request.Request(
        f"{boundary_addr}/v1/sessions?{query}",
        method="GET",
        headers={"Authorization": f"Bearer {boundary_token}"},
    )

    with urllib.request.urlopen(request, timeout=10) as response:
        result = json.loads(response.read().decode())

    sessions = result.get("items", [])
    active_count = sum(
        1
        for session in sessions
        if session.get("status") == "active"
    )

    return active_count, len(sessions)


def send_datadog_metric(dd_site, dd_api_key, active_count):
    payload = {
        "series": [
            {
                "metric": "boundary.active_sessions",
                "type": 3,
                "points": [
                    {
                        "timestamp": int(time.time()),
                        "value": active_count,
                    }
                ],
                "resources": [
                    {
                        "name": "hcp-boundary",
                        "type": "service",
                    }
                ],
            }
        ]
    }

    request = urllib.request.Request(
        f"https://api.{dd_site}/api/v2/series",
        data=json.dumps(payload).encode(),
        method="POST",
        headers={
            "Content-Type": "application/json",
            "DD-API-KEY": dd_api_key,
        },
    )

    with urllib.request.urlopen(request, timeout=10) as response:
        return response.status


def lambda_handler(event, context):
    vault_addr = os.environ["VAULT_ADDR"].rstrip("/")
    vault_namespace = os.environ["VAULT_NAMESPACE"]
    vault_aws_role = os.environ["VAULT_AWS_ROLE"]

    boundary_addr = os.environ["BOUNDARY_ADDR"].rstrip("/")
    boundary_auth_method_id = os.environ["BOUNDARY_AUTH_METHOD_ID"]
    boundary_scope_id = os.environ.get(
        "BOUNDARY_SCOPE_ID",
        "global",
    )

    dd_site = os.environ.get("DD_SITE", "datadoghq.com")

    vault_token = vault_aws_login(
        vault_addr,
        vault_namespace,
        vault_aws_role,
    )

    boundary_secret = vault_read_kv2(
        vault_addr,
        vault_namespace,
        vault_token,
        "boundary-registration/data/session-monitor",
    )
    print("Boundary monitoring credentials retrieved from Vault")

    datadog_secret = vault_read_kv2(
        vault_addr,
        vault_namespace,
        vault_token,
        "boundary-registration/data/datadog-metrics",
    )
    print("Datadog API key retrieved from Vault")

    boundary_token = boundary_login(
        boundary_addr,
        boundary_auth_method_id,
        boundary_secret["login_name"],
        boundary_secret["password"],
    )

    active_count, total_sessions = get_active_sessions(
        boundary_addr,
        boundary_token,
        boundary_scope_id,
    )
    print(f"Active Boundary sessions: {active_count}")

    datadog_status = send_datadog_metric(
        dd_site,
        datadog_secret["api_key"],
        active_count,
    )

    print(
        "Published Datadog metric: "
        f"boundary.active_sessions={active_count}"
    )

    return {
        "statusCode": 200,
        "body": {
            "success": True,
            "active_sessions": active_count,
            "total_sessions_returned": total_sessions,
            "datadog_metric_published": True,
            "datadog_http_status": datadog_status,
        },
    }
