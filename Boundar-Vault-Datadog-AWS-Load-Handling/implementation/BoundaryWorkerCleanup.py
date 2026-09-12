import os
import json
import base64
import urllib.request
import urllib.error
import urllib.parse

import boto3
from botocore.auth import SigV4Auth
from botocore.awsrequest import AWSRequest


# ============================================================
# AWS clients
# ============================================================

AWS_REGION = os.environ.get("AWS_REGION", "us-east-1")

autoscaling = boto3.client(
    "autoscaling",
    region_name=AWS_REGION
)


# ============================================================
# Vault AWS IAM Authentication
# ============================================================

def vault_aws_login(vault_addr, vault_namespace, vault_aws_role):

    print("Authenticating to Vault using AWS IAM...")

    boto_session = boto3.Session()

    credentials = (
        boto_session
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
            "Host": "sts.amazonaws.com"
        }
    )

    SigV4Auth(
        credentials,
        "sts",
        "us-east-1"
    ).add_auth(aws_request)

    signed_headers = dict(
        aws_request.headers.items()
    )

    payload = {
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
        ).decode()
    }

    request = urllib.request.Request(
        f"{vault_addr}/v1/auth/aws/login",
        data=json.dumps(payload).encode(),
        method="POST",
        headers={
            "Content-Type": "application/json",
            "X-Vault-Namespace": vault_namespace
        }
    )

    with urllib.request.urlopen(
        request,
        timeout=15
    ) as response:

        result = json.loads(
            response.read().decode()
        )

    vault_token = result["auth"]["client_token"]

    print("Vault AWS authentication successful")

    return vault_token


# ============================================================
# Read Boundary cleanup credentials from Vault
# ============================================================

def read_boundary_credentials(
    vault_addr,
    vault_namespace,
    vault_token
):

    print("Reading Boundary cleanup credentials from Vault...")

    request = urllib.request.Request(
        f"{vault_addr}/v1/"
        f"boundary-registration/data/worker-cleanup",
        method="GET",
        headers={
            "X-Vault-Token": vault_token,
            "X-Vault-Namespace": vault_namespace
        }
    )

    with urllib.request.urlopen(
        request,
        timeout=15
    ) as response:

        result = json.loads(
            response.read().decode()
        )

    secret = result["data"]["data"]

    login_name = secret["login_name"]
    password = secret["password"]

    print("Boundary cleanup credentials retrieved")

    return login_name, password


# ============================================================
# Authenticate to HCP Boundary
# ============================================================

def boundary_login(
    boundary_addr,
    auth_method_id,
    login_name,
    password
):

    print("Authenticating to HCP Boundary...")

    payload = {
        "attributes": {
            "login_name": login_name,
            "password": password
        },
        "command": "login"
    }

    request = urllib.request.Request(
        f"{boundary_addr}/v1/auth-methods/"
        f"{auth_method_id}:authenticate",
        data=json.dumps(payload).encode(),
        method="POST",
        headers={
            "Content-Type": "application/json"
        }
    )

    with urllib.request.urlopen(
        request,
        timeout=15
    ) as response:

        result = json.loads(
            response.read().decode()
        )

    boundary_token = result["attributes"]["token"]

    print("Boundary authentication successful")

    return boundary_token


# ============================================================
# Find Boundary worker by EC2 instance ID
# ============================================================

def find_boundary_worker(
    boundary_addr,
    boundary_token,
    instance_id
):

    expected_worker_name = f"aws-asg-{instance_id}"

    print(
        f"Looking for Boundary worker: "
        f"{expected_worker_name}"
    )

    query = urllib.parse.urlencode({
        "scope_id": "global"
    })

    request = urllib.request.Request(
        f"{boundary_addr}/v1/workers?{query}",
        method="GET",
        headers={
            "Authorization":
                f"Bearer {boundary_token}"
        }
    )

    with urllib.request.urlopen(
        request,
        timeout=15
    ) as response:

        result = json.loads(
            response.read().decode()
        )

    workers = result.get("items", [])

    print(
        f"Boundary workers returned: "
        f"{len(workers)}"
    )

    for worker in workers:

        worker_name = worker.get("name")
        worker_id = worker.get("id")

        print(
            f"Checking worker: "
            f"{worker_name} ({worker_id})"
        )

        if worker_name == expected_worker_name:

            print(
                f"Matching Boundary worker found: "
                f"{worker_name}"
            )

            return worker_id

    print(
        f"No Boundary worker found with name: "
        f"{expected_worker_name}"
    )

    return None


# ============================================================
# Delete Boundary worker
# ============================================================

def delete_boundary_worker(
    boundary_addr,
    boundary_token,
    worker_id
):

    print(
        f"Deleting Boundary worker: "
        f"{worker_id}"
    )

    request = urllib.request.Request(
        f"{boundary_addr}/v1/workers/{worker_id}",
        method="DELETE",
        headers={
            "Authorization":
                f"Bearer {boundary_token}"
        }
    )

    try:

        with urllib.request.urlopen(
            request,
            timeout=15
        ) as response:

            status = response.status

        print(
            f"Boundary worker deleted. "
            f"HTTP status: {status}"
        )

        return True

    except urllib.error.HTTPError as e:

        # If it was already deleted,
        # cleanup can safely continue.
        if e.code == 404:

            print(
                "Boundary worker already absent."
            )

            return True

        raise


# ============================================================
# Complete AWS lifecycle action
# ============================================================

def complete_lifecycle_action(
    asg_name,
    lifecycle_hook_name,
    lifecycle_action_token
):

    print("Completing Auto Scaling lifecycle action...")

    autoscaling.complete_lifecycle_action(
        LifecycleHookName=lifecycle_hook_name,
        AutoScalingGroupName=asg_name,
        LifecycleActionResult="CONTINUE",
        LifecycleActionToken=lifecycle_action_token
    )

    print("Lifecycle action completed with CONTINUE")


# ============================================================
# Lambda Handler
# ============================================================

def lambda_handler(event, context):

    print("================================================")
    print("Boundary ASG Worker Cleanup")
    print("================================================")

    print(
        f"Received event: "
        f"{json.dumps(event)}"
    )

    detail = event.get("detail", {})

    instance_id = detail.get(
        "EC2InstanceId"
    )

    asg_name = detail.get(
        "AutoScalingGroupName"
    )

    lifecycle_hook_name = detail.get(
        "LifecycleHookName"
    )

    lifecycle_action_token = detail.get(
        "LifecycleActionToken"
    )

    # ========================================================
    # Validate EventBridge event
    # ========================================================

    required = {
        "EC2InstanceId": instance_id,
        "AutoScalingGroupName": asg_name,
        "LifecycleHookName": lifecycle_hook_name,
        "LifecycleActionToken":
            lifecycle_action_token
    }

    missing = [
        key
        for key, value in required.items()
        if not value
    ]

    if missing:

        print(
            f"Missing event fields: {missing}"
        )

        return {
            "statusCode": 400,
            "body": {
                "success": False,
                "error":
                    "Missing lifecycle event fields",
                "missing": missing
            }
        }

    print(
        f"EC2 Instance ID: {instance_id}"
    )

    print(
        f"Auto Scaling Group: {asg_name}"
    )

    print(
        f"Lifecycle Hook: {lifecycle_hook_name}"
    )

    expected_worker_name = (
        f"aws-asg-{instance_id}"
    )

    print(
        f"Expected Boundary worker: "
        f"{expected_worker_name}"
    )

    try:

        # ====================================================
        # Environment variables
        # ====================================================

        vault_addr = os.environ[
            "VAULT_ADDR"
        ].rstrip("/")

        vault_namespace = os.environ[
            "VAULT_NAMESPACE"
        ]

        vault_aws_role = os.environ[
            "VAULT_AWS_ROLE"
        ]

        boundary_addr = os.environ[
            "BOUNDARY_ADDR"
        ].rstrip("/")

        boundary_auth_method_id = os.environ[
            "BOUNDARY_AUTH_METHOD_ID"
        ]

        # ====================================================
        # STEP 1 - Login to Vault
        # ====================================================

        vault_token = vault_aws_login(
            vault_addr,
            vault_namespace,
            vault_aws_role
        )

        # ====================================================
        # STEP 2 - Get Boundary credentials
        # ====================================================

        (
            boundary_login_name,
            boundary_password
        ) = read_boundary_credentials(
            vault_addr,
            vault_namespace,
            vault_token
        )

        # ====================================================
        # STEP 3 - Login to Boundary
        # ====================================================

        boundary_token = boundary_login(
            boundary_addr,
            boundary_auth_method_id,
            boundary_login_name,
            boundary_password
        )

        # ====================================================
        # STEP 4 - Find matching worker
        # ====================================================

        worker_id = find_boundary_worker(
            boundary_addr,
            boundary_token,
            instance_id
        )

        # ====================================================
        # STEP 5 - Delete worker if found
        # ====================================================

        worker_deleted = False

        if worker_id:

            worker_deleted = (
                delete_boundary_worker(
                    boundary_addr,
                    boundary_token,
                    worker_id
                )
            )

        else:

            print(
                "No matching Boundary worker. "
                "Nothing to delete."
            )

        # ====================================================
        # STEP 6 - Allow EC2 termination to continue
        # ====================================================

        complete_lifecycle_action(
            asg_name,
            lifecycle_hook_name,
            lifecycle_action_token
        )

        return {
            "statusCode": 200,
            "body": {
                "success": True,
                "instance_id": instance_id,
                "boundary_worker_name":
                    expected_worker_name,
                "boundary_worker_id":
                    worker_id,
                "boundary_worker_deleted":
                    worker_deleted,
                "lifecycle_action":
                    "CONTINUE"
            }
        }

    except Exception as e:

        print(
            f"Cleanup ERROR: {str(e)}"
        )

        # Important:
        # We still try to release the EC2 instance
        # so it is not stuck in Terminating:Wait.
        try:

            complete_lifecycle_action(
                asg_name,
                lifecycle_hook_name,
                lifecycle_action_token
            )

        except Exception as lifecycle_error:

            print(
                "Could not complete lifecycle action: "
                f"{str(lifecycle_error)}"
            )

        raise