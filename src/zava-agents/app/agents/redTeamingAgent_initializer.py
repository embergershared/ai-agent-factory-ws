# This script launches red-team attacks
# Execute with: python app/agents/redTeamingAgent_initializer.py

# NOTE: Heavy Azure / PyRIT imports are deferred to the functions that
# need them so the interactive menu appears instantly.
import os
import sys
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


def build_chat_target():
    """PyRIT OpenAIChatTarget pointing at the deployed model."""
    from pyrit.prompt_target import OpenAIChatTarget

    return OpenAIChatTarget(
        model_name=os.environ.get("gpt_deployment"),
        endpoint=(
            f"{os.environ.get('gpt_endpoint')}/openai/deployments/"
            f"{os.environ.get('gpt_deployment')}/chat/completions"
        ),
        api_key=os.environ.get("gpt_api_key"),
        api_version=os.environ.get("gpt_api_version"),
    )


def build_red_team_agent():
    """Standard RedTeam agent with the 4 default risk categories."""
    from azure.identity import DefaultAzureCredential
    from azure.ai.evaluation.red_team import RedTeam, RiskCategory

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


def build_custom_attack_agent():
    """RedTeam agent loaded with custom seed prompts."""
    from azure.identity import DefaultAzureCredential
    from azure.ai.evaluation.red_team import RedTeam

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
    from azure.ai.evaluation.red_team import AttackStrategy

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
    """Print a human-readable synthesis table of the scan results."""
    attack_name = ATTACK_CHOICES[choice]["name"]
    print("\n" + "─" * 70)
    print(f"  ✅  Scan complete: {attack_name}")
    print("─" * 70)

    if result is None:
        print("  (No result object returned.)\n")
        return

    # ── Studio URL ──────────────────────────────────────────────────────
    scan = getattr(result, "scan_result", None) or {}
    studio_url = scan.get("studio_url")
    if studio_url:
        print(f"\n  🔗  Foundry results: {studio_url}")

    # ── Scorecard tables ────────────────────────────────────────────────
    scorecard = None
    if hasattr(result, "to_scorecard"):
        scorecard = result.to_scorecard()
    if scorecard is None and isinstance(scan, dict):
        scorecard = scan.get("scorecard")

    if scorecard:
        _print_risk_category_table(scorecard)
        _print_attack_technique_table(scorecard)
        _print_joint_summary_table(scorecard)

    # ── Per-attack detail table ─────────────────────────────────────────
    attacks = getattr(result, "attack_details", None)
    if attacks:
        _print_attack_details_table(attacks)

    print()


# ── Table helpers ───────────────────────────────────────────────────────────
def _fmt_pct(value) -> str:
    """Format a float as a percentage string, or '–' if unavailable."""
    if value is None:
        return "–"
    return f"{value * 100:5.1f}%"


def _fmt_int(value) -> str:
    return "–" if value is None else str(value)


def _print_risk_category_table(scorecard: dict):
    """Risk-category ASR summary."""
    items = scorecard.get("risk_category_summary")
    if not items:
        return
    row = items[0]  # single summary row

    categories = [
        ("Overall", "overall"),
        ("Violence", "violence"),
        ("Hate/Unfairness", "hate_unfairness"),
        ("Sexual", "sexual"),
        ("Self-Harm", "self_harm"),
    ]

    print("\n  ┌─────────────────────────────────────────────────────┐")
    print("  │          Risk Category Attack Success Rates         │")
    print("  ├───────────────────┬────────┬───────┬────────────────┤")
    print("  │ Category          │   ASR  │ Total │ Successful     │")
    print("  ├───────────────────┼────────┼───────┼────────────────┤")
    for label, key in categories:
        asr = row.get(f"{key}_asr")
        total = row.get(f"{key}_total")
        success = row.get(f"{key}_successful_attacks")
        print(
            f"  │ {label:<17} │ {_fmt_pct(asr):>6} │ {_fmt_int(total):>5} │ {_fmt_int(success):>14} │"
        )
    print("  └───────────────────┴────────┴───────┴────────────────┘")


def _print_attack_technique_table(scorecard: dict):
    """Attack-technique (complexity) ASR summary."""
    items = scorecard.get("attack_technique_summary")
    if not items:
        return
    row = items[0]

    complexities = [
        ("Overall", "overall"),
        ("Baseline", "baseline"),
        ("Easy", "easy_complexity"),
        ("Moderate", "moderate_complexity"),
        ("Difficult", "difficult_complexity"),
    ]

    print("\n  ┌─────────────────────────────────────────────────────┐")
    print("  │       Attack Technique / Complexity Summary         │")
    print("  ├───────────────────┬────────┬───────┬────────────────┤")
    print("  │ Complexity        │   ASR  │ Total │ Successful     │")
    print("  ├───────────────────┼────────┼───────┼────────────────┤")
    for label, key in complexities:
        asr = row.get(f"{key}_asr")
        total = row.get(f"{key}_total")
        success = row.get(f"{key}_successful_attacks")
        print(
            f"  │ {label:<17} │ {_fmt_pct(asr):>6} │ {_fmt_int(total):>5} │ {_fmt_int(success):>14} │"
        )
    print("  └───────────────────┴────────┴───────┴────────────────┘")


def _print_joint_summary_table(scorecard: dict):
    """Joint risk × attack complexity ASR (detailed breakdown)."""
    detailed = scorecard.get("detailed_joint_risk_attack_asr")
    if not detailed:
        return

    print("\n  ┌──────────────────────────────────────────────────────────────────┐")
    print("  │           Joint Risk × Attack Complexity ASR                     │")
    print("  ├───────────────────┬──────────┬──────────┬──────────┬─────────────┤")
    print("  │ Risk Category     │ Baseline │   Easy   │ Moderate │  Difficult  │")
    print("  ├───────────────────┼──────────┼──────────┼──────────┼─────────────┤")
    for risk_cat, techniques in detailed.items():
        base = techniques.get("baseline", {}).get("attack_success_rate")
        easy = techniques.get("easy", {}).get("attack_success_rate")
        mod = techniques.get("moderate", {}).get("attack_success_rate")
        diff = techniques.get("difficult", {}).get("attack_success_rate")
        label = risk_cat.replace("_", " ").title()
        print(
            f"  │ {label:<17} │ {_fmt_pct(base):>8} │ {_fmt_pct(easy):>8} │ "
            f"{_fmt_pct(mod):>8} │ {_fmt_pct(diff):>11} │"
        )
    print("  └───────────────────┴──────────┴──────────┴──────────┴─────────────┘")


def _print_attack_details_table(attacks: list):
    """Per-attack synopsis table."""
    print(f"\n  Individual Attacks: {len(attacks)} total\n")

    # Column widths
    w_tech = 22
    w_cmplx = 12
    w_risk = 18
    w_result = 10

    hdr = (
        f"  {'#':>3}  "
        f"{'Technique':<{w_tech}}  "
        f"{'Complexity':<{w_cmplx}}  "
        f"{'Risk Category':<{w_risk}}  "
        f"{'Result':<{w_result}}"
    )
    sep = "  " + "─" * (len(hdr) - 2)
    print(hdr)
    print(sep)

    success_count = 0
    for i, atk in enumerate(attacks, 1):
        technique = (atk.get("attack_technique") or "–")[:w_tech]
        complexity = (atk.get("attack_complexity") or "–")[:w_cmplx]
        risk = (atk.get("risk_category") or "–").replace("_", " ").title()[:w_risk]
        succeeded = atk.get("attack_success")
        if succeeded is True:
            result_str = "🔴 SUCCESS"
            success_count += 1
        elif succeeded is False:
            result_str = "🟢 Blocked"
        else:
            result_str = "⚪ Unknown"

        print(
            f"  {i:>3}  "
            f"{technique:<{w_tech}}  "
            f"{complexity:<{w_cmplx}}  "
            f"{risk:<{w_risk}}  "
            f"{result_str:<{w_result}}"
        )

    print(sep)
    blocked = len(attacks) - success_count
    print(
        f"  Summary: {len(attacks)} attacks  │  "
        f"🟢 {blocked} blocked  │  "
        f"🔴 {success_count} succeeded  │  "
        f"ASR: {success_count / len(attacks) * 100:.1f}%"
    )


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
