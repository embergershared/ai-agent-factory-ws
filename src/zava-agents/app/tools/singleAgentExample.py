# The start of singleAgentExample.py should include the following import statements:
import os
import base64
from openai import AzureOpenAI
from dotenv import load_dotenv
import numpy as np
import time

# Then, load the environment settings from the .env file using the load_dotenv() function:
# Load environment variables (Azure endpoint, deployment, keys, etc.)
load_dotenv()

# After that, retrieve the necessary environment variables for your Azure OpenAI deployment. For this, you will use the gpt-5-mini deployment that you created in the prior exercise. Add the following code to retrieve these values:

# Retrieve credentials from .env file or environment
endpoint = os.getenv("gpt_endpoint")
deployment = os.getenv("gpt_deployment")
api_key = os.getenv("gpt_api_key")
api_version = os.getenv("gpt_api_version")

# The next step is to create an AzureOpenAI client using the retrieved environment variables. Add the following code to create the client:

# Initialize Azure OpenAI client for GPT model
client = AzureOpenAI(
    azure_endpoint=endpoint,
    api_key=api_key,
    api_version=api_version,
)

# The majority of this file will be dedicated to the generate_response() function, which will take a text input and return a response from the Azure OpenAI model. Add the following code to define this function:


def generate_response(text_input):
    start_time = time.time()
    """
    Input:
        text_input (str): The user's chat input.

    Output:
        response (str): A Markdown-formatted response from the agent.
    """

    # Prepare the full chat prompt with system and user messages
    chat_prompt = [
        {
            "role": "system",
            "content": [
                {
                    "type": "text",
                    "text": """You are a helpful assistant working for Zava, a company that specializes in offering products to assist homeowners with do-it-yourself projects.
                        Respond to customer inquiries with relevant product recommendations and DIY tips. If a customer asks for paint, suggest one of the following three colors: blue, green, and white.
                        If a customer asks for something not related to a DIY project, politely inform them that you can only assist with DIY-related inquiries.
                        Zava has a variety of store locations across the country. If a customer asks about store availability, direct the customer to the Miami store.
                    """,
                }
            ],
        },
        {"role": "user", "content": text_input},
    ]

    # Call Azure OpenAI chat API
    completion = client.chat.completions.create(
        model=deployment,
        messages=chat_prompt,
        max_completion_tokens=10000,
        top_p=1,
        frequency_penalty=0,
        presence_penalty=0,
        stop=None,
        stream=False,
    )
    end_sum = time.time()
    print(f"generate_response Execution Time: {end_sum - start_time} seconds")
    # Return response content
    return completion.choices[0].message.content


# This single function prepares a chat prompt with a system message that defines the assistant’s role and a user message containing the input text. It then calls the Azure OpenAI chat API to generate a response and returns the content of that response. This particular function combines both the prompt definition and the call to the model in a single function for simplicity. As you will see later in this task, this is not necessarily the best approach for a production application.
