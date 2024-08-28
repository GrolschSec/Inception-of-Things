from sys import argv, exit
from os import path
from bcrypt import gensalt, hashpw
from kubernetes import config
from kubernetes.client import CoreV1Api, V1ObjectMeta, V1Secret
from kubernetes.client.rest import ApiException
from base64 import b64encode


def usage() -> str:
    if len(argv) != 2:
        print(f"Usage: python3 ./{argv[0]} <PATH-TO-ENV-FILE>")
        exit(1)
    if not path.isfile(f"{argv[1]}/irc.env"):
        print(f"File not found: {argv[1]}/irc.env")
        exit(1)
    return str(argv[1])


def read_env_file(path: str) -> list:
    env_var = []
    with open(f"{path}/irc.env", "r") as file:
        env_var = file.read().splitlines()
    return env_var


def env_vars_to_dict_list(env: list) -> list:
    dct_lst = []
    for env_var in env:
        res = env_var.split("=")
        dct_lst.append({"var": str(res[0]).lower(), "password": res[1]})
    return dct_lst


def hash_password(password: str) -> str:
    password = password.encode("utf-8")
    salt = gensalt()
    return hashpw(password, salt).decode("utf-8")


def update_cleartext_passwords_to_hash(env: list) -> list:
    for dct in env:
        dct["password"] = hash_password(dct["password"])
    return env


def get_kubectl_conf() -> None:
    return config.load_kube_config(config_file="/etc/rancher/k3s/k3s.yaml")


def create_kube_client() -> CoreV1Api:
    return CoreV1Api()


def create_secret(
    client: CoreV1Api, secret_name: str, secret_password: str
) -> None:
    
    secret_data = {secret_name: b64encode(secret_password.encode('utf-8')).decode('utf-8')}

    metadata = V1ObjectMeta(name=secret_name)
    secret = V1Secret(metadata=metadata, data=secret_data, type="Opaque")

    try:
        client.create_namespaced_secret(namespace="default", body=secret)
        print(f"Secret '{secret_name}' created in namespace 'default'.")
    except ApiException as e:
        if e.status == 409:
            client.replace_namespaced_secret(
                name=secret_name, namespace="default", body=secret
            )
            print(f"Secret '{secret_name}' updated in namespace 'default'.")
        else:
            raise e

def env_to_secret(env: list, client: CoreV1Api) -> None:
    for dct in env:
        create_secret(client, dct['var'], dct['password'])

if __name__ == "__main__":
    path = usage()
    env = update_cleartext_passwords_to_hash(env_vars_to_dict_list(read_env_file(path)))
    get_kubectl_conf()
    client = create_kube_client()
    env_to_secret(env, client)
