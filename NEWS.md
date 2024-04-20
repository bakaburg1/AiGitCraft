# AiGitCraft 0.2.0

## Improved LLM Operations and Error Handling

#### Enhancements

- **Improved LLM Output Readability**: Added `cat(res)` to print the result of the LLM prompt and `invisible(res)` to return the result invisibly, making it easier to review and use the LLM output.

- **Structured Pull Request Descriptions**: Refactored the prompt for generating pull request descriptions to include a more structured format with sections for enhancements, fixes, and documentation. Also, added a poetry conclusion to the pull request description.

- **More General Custom LLM Access**: Refactored the `use_local_llm` function to `use_custom_llm`, allowing for custom (local or remote) language model endpoints compatible with the OpenAI API specification. Added an optional API key and model parameter for custom LLM services.

#### Fixes

* Improved error handling in LLM requests by checking if the error object is a character string or has a message attribute.

#### Summary
This pull request brings several improvements to the LLM operations, including enhanced pull request description generation, improved LLM output readability, and better error handling. Additionally, it adds a generation speed metric and refactors the `use_local_llm` function for custom language model endpoints.


# AiGitCraft 0.1.0

* Initial beta release.
