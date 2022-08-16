from brownie import Price_limit_token, MockV3Aggregator, network, config
from scripts.helpful_scripts import (
    get_account,
    LOCAL_BLOCKCHAIN_ENVIRONMENTS,
)


def deploy_price_limit_token():
    account = get_account()

    price_limit_token = Price_limit_token.deploy(
        {"from": account},
        publish_source=config["networks"][network.show_active()].get("verify"),
    )
    print(f"Contract deployed to {price_limit_token.address}")
    return price_limit_token


def main():
    deploy_price_limit_token()