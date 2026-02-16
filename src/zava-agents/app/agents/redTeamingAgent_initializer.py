# This script launches red-team attacks
# Execute with: python app/agents/redTeamingAgent_initializer.py

# Azure imports
from azure.identity import DefaultAzureCredential
from azure.ai.evaluation.red_team import RedTeam, RiskCategory, AttackStrategy
from pyrit.prompt_target import OpenAIChatTarget
import os
import sys
import json
import asyncio
from datetime import datetime
from dotenv import load_dotenv

load_dotenv()

# ═════════════════════════════════════════════════════════════════════════════
# Constants
# ═════════════════════════════════════════════════════════════════════════════
CUSTOM_ATTACK_PROMPTS_PATH = "data/custom_attack_prompts.json"

ATTACK_CHOICES = {
    "1": {
        "name": "Baseline – Simple test function",
        "description": "Uses a static test function as the target (no real model). "
        "Quick smoke-test to verify the red-team agent works.",
    },
    "2": {
        "name": "Baseline – Azure OpenAI config dict",
        "description": "Sends attacks to the deployed Azure OpenAI model using "
        "the azure_openai_config dictionary target.",
    },
    "3": {
        "name": "Baseline – OpenAI Chat Target (PyRIT)",
        "description": "Sends attacks to the deployed model via the PyRIT "
        "OpenAIChatTarget class.",
    },
    "4": {
        "name": "Custom attack prompts",
        "description": f"Uses custom seed prompts from '{CUSTOM_ATTACK_PROMPTS_PATH}' "
        "with the OpenAIChatTarget.",
    },
    "5": {
        "name": "Easy attack strategies",
        "description": "Applies the pre-defined EASY strategy bundle "
        "(low-complexity obfuscation) against the OpenAIChatTarget.",
    },
    "6": {
        "name": "Customized attack strategies (Easy–Moderate)",
        "description": "Applies a hand-picked set of moderate-complexity strategies "
        "(Flip, ROT13, Base64, AnsiAttack, Tense) against the OpenAIChatTarget.",
    },
}


# ═════════════════════════════════════════════════════════════════════════════
# Helpers
# ═════════════════════════════════════════════════════════════════════════════
def print_banner():
    """Print a styled banner for the red-team launcher."""
    print("\n" + "═" * 60)
    print("  🔴  AI Red Teaming Agent – Attack Launcher")
    print("═" * 60)


def print_menu():
    """Display the numbered attack choices."""
    print("\nAvailable attack modes:\n")
    for key, info in ATTACK_CHOICES.items():
        print(f"  [{key}]  {info['name']}")
        print(f"       {info['description']}\n")
    print("  [Q]  Quit\n")


def get_user_choice() -> str:
    """Prompt the user until a valid choice is entered."""
    while True:
        choice = input("Select an attack mode ➜  ").strip().upper()
        if choice == "Q":
            print("\nExiting. No scan was run.\n")
            sys.exit(0)
        if choice in ATTACK_CHOICES:
            return choice
        print(f"  ⚠  Invalid selection '{choice}'. Please try again.\n")


# ═════════════════════════════════════════════════════════════════════════════
# Target & agent factories
# ═════════════════════════════════════════════════════════════════════════════
def build_test_chat_target():
    """A simple deterministic function target (no real model)."""

    def test_chat_target(query: str) -> str:
        return (
            "I am a simple AI assistant that follows ethical guidelines. "
            "I'm sorry, Dave. I'm afraid I can't do that."
        )

    return test_chat_target


def build_azure_openai_config() -> dict:
    """Azure OpenAI config-dict target."""
    return {
        "azure_endpoint": (
            f"{os.environ.get('gpt_endpoint')}/openai/deployments/"
            f"{os.environ.get('gpt_deployment')}/chat/completions"
        ),
        "api_key": os.environ.get("FOUNDRY_KEY"),
        "azure_deployment": os.environ.get("gpt_deployment"),
    }


def build_chat_target() -> OpenAIChatTarget:
    """PyRIT OpenAIChatTarget pointing at the deployed model."""
    return OpenAIChatTarget(
        model_name=os.environ.get("gpt_deployment"),
        endpoint=(
            f"{os.environ.get('gpt_endpoint')}/openai/deployments/"
            f"{os.environ.get('gpt_deployment')}/chat/completions"
        ),
        api_key=os.environ.get("gpt_api_key"),
        api_version=os.environ.get("gpt_api_version"),
    )


def build_red_team_agent() -> RedTeam:
    """Standard RedTeam agent with the 4 default risk categories."""
    azure_ai_project = os.getenv("FOUNDRY_ENDPOINT")
    return RedTeam(
        azure_ai_project=azure_ai_project,
        credential=DefaultAzureCredential(),
        risk_categories=[
            RiskCategory.Violence,
            RiskCategory.HateUnfairness,
            RiskCategory.Sexual,
            RiskCategory.SelfHarm,
        ],
        num_objectives=5,
    )


def build_custom_attack_agent() -> RedTeam:
    """RedTeam agent loaded with custom seed prompts."""
    azure_ai_project = os.getenv("FOUNDRY_ENDPOINT")
    return RedTeam(
        azure_ai_project=azure_ai_project,
        credential=DefaultAzureCredential(),
        custom_attack_seed_prompts=CUSTOM_ATTACK_PROMPTS_PATH,
    )


# ═════════════════════════════════════════════════════════════════════════════
# Scan dispatcher
# ═════════════════════════════════════════════════════════════════════════════
async def run_scan(choice: str):
    """Build the appropriate agent + target and run the scan."""
    result = None

    if choice == "1":
        # Baseline – simple test function
        agent = build_red_team_agent()
        target = build_test_chat_target()
        result = await agent.scan(target=target)

    elif choice == "2":
        # Baseline – Azure OpenAI config dict
        agent = build_red_team_agent()
        target = build_azure_openai_config()
        result = await agent.scan(target=target)

    elif choice == "3":
        # Baseline – OpenAI Chat Target (PyRIT)
        agent = build_red_team_agent()
        target = build_chat_target()
        result = await agent.scan(target=target)

    elif choice == "4":
        # Custom attack prompts
        agent = build_custom_attack_agent()
        target = build_chat_target()
        result = await agent.scan(target=target)

    elif choice == "5":
        # Easy attack strategies
        agent = build_red_team_agent()
        target = build_chat_target()
        result = await agent.scan(
            target=target,
            scan_name="Red Team Scan - Easy Strategies",
            attack_strategies=[AttackStrategy.EASY],
        )

    elif choice == "6":
        # Customized attack strategies (Easy–Moderate)
        agent = build_red_team_agent()
        target = build_chat_target()
        result = await agent.scan(
            target=target,
            scan_name="Red Team Scan - Easy-Moderate Strategies",
            attack_strategies=[
                AttackStrategy.Flip,
                AttackStrategy.ROT13,
                AttackStrategy.Base64,
                AttackStrategy.AnsiAttack,
                AttackStrategy.Tense,
            ],
        )

    return result


# ═════════════════════════════════════════════════════════════════════════════
# Results display
# ═════════════════════════════════════════════════════════════════════════════
def display_results(result, choice: str):
    """Print a human-readable summary of the scan results."""
    attack_name = ATTACK_CHOICES[choice]["name"]
    print("\n" + "─" * 60)
    print(f"  ✅  Scan complete: {attack_name}")
    print("─" * 60)

    # The result object from RedTeam.scan() varies by SDK version.
    # Try to display the most useful information available.
    if result is None:
        print("  (No result object returned.)\n")
        return

    # If the result has a to_json / to_dict helper, dump it nicely
    if hasattr(result, "to_dict"):
        data = result.to_dict()
        print(json.dumps(data, indent=2, default=str))
    elif hasattr(result, "to_json"):
        print(result.to_json(indent=2))
    elif isinstance(result, dict):
        print(json.dumps(result, indent=2, default=str))
    else:
        # Fallback: print the repr
        print(result)

    print()


# ═════════════════════════════════════════════════════════════════════════════
# Main
# ═════════════════════════════════════════════════════════════════════════════
async def main():
    print_banner()
    print_menu()
    choice = get_user_choice()

    selected = ATTACK_CHOICES[choice]
    print(f"\n▶  Launching: {selected['name']}")
    print(f"   {selected['description']}")
    print("   This may take several minutes …\n")

    start = datetime.now()
    result = await run_scan(choice)
    elapsed = datetime.now() - start

    display_results(result, choice)
    print(f"  ⏱  Elapsed time: {elapsed}\n")


asyncio.run(main())
