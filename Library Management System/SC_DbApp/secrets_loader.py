import json
import boto3
import os


def get_db_credentials():
    """
    Load DB credentials securely from AWS Secrets Manager
    Works with:
    - Local development (aws configure)
    - EKS with IRSA
    """

    secret_name = os.getenv(
        "DB_SECRET_NAME",
        "rds/app-db-credentials"
    )

    region_name = os.getenv(
        "AWS_REGION",
        "eu-north-1"
    )

    client = boto3.client("secretsmanager", region_name=region_name)

    try:
        response = client.get_secret_value(SecretId=secret_name)
    except Exception as e:
        raise RuntimeError(f"Failed to load DB secret: {e}")

    secret = json.loads(response["SecretString"])

    return {
        "username": secret["username"],
        "password": secret["password"]
    }
