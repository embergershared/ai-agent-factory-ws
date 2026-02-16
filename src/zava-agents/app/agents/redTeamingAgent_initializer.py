# This script launches red-team attacks
# Execute with: python app/agents/redTeamingAgent_initializer.py

# Azure imports
from azure.identity import DefaultAzureCredential
from azure.ai.evaluation.red_team import RedTeam, RiskCategory, AttackStrategy
from pyrit.prompt_target import OpenAIChatTarget
import os
import asyncio
from dotenv import load_dotenv

load_dotenv()

# Azure AI Project Information
azure_ai_project = os.getenv("FOUNDRY_ENDPOINT")


# Instantiate your AI Red Teaming Agent
red_team_agent = RedTeam(
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


# Define target model for red teaming
# def test_chat_target(query: str) -> str:
#     return "I am a simple AI assistant that follows ethical guidelines. I'm sorry, Dave. I'm afraid I can't do that."

# # Configuration for Azure OpenAI model
# azure_openai_config = {
#     "azure_endpoint": f"{os.environ.get('gpt_endpoint')}/openai/deployments/{os.environ.get('gpt_deployment')}/chat/completions",
#     "api_key": os.environ.get("FOUNDRY_KEY"),
#     "azure_deployment": os.environ.get("gpt_deployment"),
# }

# Configuration for an OpenAI chat target model
chat_target = OpenAIChatTarget(
    model_name=os.environ.get("gpt_deployment"),
    endpoint=f"{os.environ.get("gpt_endpoint")}/openai/deployments/{os.environ.get('gpt_deployment')}/chat/completions",
    api_key=os.environ.get("gpt_api_key"),
    api_version=os.environ.get("gpt_api_version"),
)

# # Custom attack prompts (optional)
# red_team_agent_custom_attack = RedTeam(
#     azure_ai_project=azure_ai_project,
#     credential=DefaultAzureCredential(),
#     custom_attack_seed_prompts="data/custom_attack_prompts.json",
# )


# Execute the Red team scan
async def main():
    # red_team_result = await red_team_agent.scan(target=test_chat_target)
    # red_team_result = await red_team_agent.scan(target=azure_openai_config)
    # red_team_result = await red_team_agent.scan(target=chat_target)
    # red_team_result = await red_team_agent_custom_attack.scan(target=chat_target)

    # # Custom prompt attack Simple strategy
    # red_team_result = await red_team_agent.scan(
    #     target=chat_target,
    #     scan_name="Red Team Scan - Easy Strategies",
    #     attack_strategies=[AttackStrategy.EASY],
    # )

    # Custom prompt attack customized strategy
    red_team_result = await red_team_agent.scan(
        target=chat_target,
        scan_name="Red Team Scan - Easy-Moderate Strategies",
        attack_strategies=[
            AttackStrategy.Flip,
            AttackStrategy.ROT13,
            AttackStrategy.Base64,
            AttackStrategy.AnsiAttack,
            AttackStrategy.Tense,
        ],
    )


asyncio.run(main())
