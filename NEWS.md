# News

## AiGitCraft 1.0.0: ✨ Pull Request: Add Automated Test Suite, LLM Integration Refactor, Dependency Updates, and Documentation Enhancements

#### Enhancements

- **Add Comprehensive Test Suite Using testthat (Commit: 111fb98)**
  - Implements a robust set of automated tests under /tests/testthat/ covering core functionalities:
    - Git operations (branch/commit differences, uncommitted changes)
    - LLM invocation logic
    - LLM-powered helper workflows (commit message, PR description, code review, README)
    - Utility and validation routines
  - Ensures future-proofed refactoring and stability of AI-augmented git workflows.

- **Migrate LLM Layer from llmR to ellmer & introduce invoke_llm() Helper (Commit: 640832e)**
  - Removes direct dependency on custom llmR and instead routes all LLM calls through the new invoke_llm(), utilizing ellmer’s flexible, provider-agnostic interface.
  - Greatly simplifies provider configuration (local, OpenAI, Claude, etc.), model swapping, and temperature/params management.
  - Allows passing LLM provider/model either globally via options or per-call.
  - Makes the entire package future-compatible with a growing range of LLM services.

- **Dependency and Version Upgrades (Commit: cd010a4)**
  - Bumps package version to v1.0.0
  - Updates DESCRIPTION (drops llmR, git2r; adds ellmer, gert, cli, testthat), README, and documentation to reflect new LLM stack.
  - Updates renv.lock and renv/activate.R for R 4.5 and all latest tidyverse/Posit dependencies (dplyr, renv 1.1.4, readr 2.1.5, etc.).
  - Documents test dependencies and adopts testthat 3rd edition project structure.

- **Refactor/Cleanup Core Codebase (Commits: 7f3f8d1, 1b94cc1 et al.)**
  - Refactors all git operations:
    - Switches diff extraction to fast, robust gert + system2 calls (no more git2r).
    - Unifies repo_path handling and staging logic for diffs.
    - Screened folder logic made more robust.
    - Adds detailed error handling with cli alerts (instead of raw message/stop/warning).
  - LLM-powered workflows (commit message, PR desc, code review, README, Twitter thread) now consistently use invoke_llm, handle context files, and improve prompt engineering.

#### Fixes

- **Robust Error and Dependency Handling (1b94cc1)**
  - Standardizes user-facing errors via cli for all core functions.
  - Validation functions now provide clear, actionable diagnostics on missing .git repos and handle missing dependencies gracefully.
  - Bug in staged/unstaged diff extraction fixed.
- **Outdated LLM, API, or Dependency Options Removed**
  - All references to legacy llmR config replaced with ellmer (and provider-specific environment variables/global options).

#### Documentation

- **Comprehensive Updates to README.md, DESCRIPTION, & Roxygen (a19dbaf, a4278b3)**
  - Usage instructions refactored for ellmer and new options.
  - Example code for all main workflows, including new test coverage.
  - Provider/model configuration examples for OpenAI, Claude, Azure, and local.
  - Describes new recommendation to use ellmer::chat arguments directly and leverages options for LLM credentials.
  - All exported functions and utilities have roxygenized man pages, e.g. for invoke_llm, and testthat setup.

#### Summary

This is a major upgrade that (1) introduces a complete, automated test suite that increases maintainability, (2) future-proofs the package by migrating the core LLM interaction layer from a custom package to ellmer, and (3) modernizes all dependency, error, and configuration handling.

The package is now more robust, developer-friendly, and ready for use against any modern LLM provider and API, with full confidence thanks to comprehensive automated testing.

## AiGitCraft 0.3.0: Integration of `llmR` Package and Code Review Functionality

#### Enhancements

- **Use `llmR` package to communicate with LLMs**: Instead of relying on internal code to communicate with LLMs, the package now uses the infrastructure provided by `llmR`, also developed by me. This allows me to centralize the development of LLM interfaces in a centralized manner without repeating code across packages. (Commit: de8e30a)
- **Add code review functionality**: Implemented `perform_code_change_review` function to provide detailed code reviews using LLM. This function assesses code quality, potential bugs, code smells, security vulnerabilities, performance, and documentation. (Commit: 3a066f0)
- **Show which model is being used for LLM request**: Added a `log_request` parameter to `use_openai_llm`, `use_azure_llm`, and `use_custom_llm` functions to log the specific endpoint and model being used. (Commit: 28a6471)
- **Manage outputs longer than token limit**: Improved handling of LLM responses that exceed the output token limit. Users can now decide to let the LLM complete the answer, keep the incomplete answer, or stop the process. The incomplete answer is saved to a file for reference. (Commit: cfeab44)
- **Catch suggested package installation errors**: Enhanced error handling for package installation during dependency checks. (Commit: f643944)

#### Fixes

- **Missing auto print**: Added missing `cat()` to ensure the output is printed automatically. (Commit: d96f8e8)
- **Adapt to changes in LLM calling functions**: Updated the code to adapt to changes in LLM calling functions, ensuring compatibility with the new `llmR` package. (Commit: 0a71ad3)
- **Minor system prompt change**: Made a minor change to the system prompt for better clarity. (Commit: d1600a6)

#### Documentation

- **Add docs for validate_repo_path**: Added documentation for the `validate_repo_path` function. (Commit: c38da4f)
- **Documentation update**: Improved error messages and updated documentation to reflect changes in the language model provider configuration. (Commit: 65cbcde)
- **Typo fix**: Corrected a typo in the documentation. (Commit: 5075418)

#### Summary

This pull request integrates the `llmR` package for enhanced communication with Large Language Models (LLMs), centralizing LLM interface development and reducing code redundancy. It introduces a new code review functionality, improves error handling, and enhances the user experience by managing long LLM responses. Additionally, it includes several documentation updates and minor fixes to ensure smooth operation and better clarity.

## AiGitCraft 0.2.0: Allow interfacing with custom language models and log generation speed

#### Enhancements

- **Improved LLM Output Readability**: Added `cat(res)` to print the result of the LLM prompt and `invisible(res)` to return the result invisibly, making it easier to review and use the LLM output.

- **Structured Pull Request Descriptions**: Refactored the prompt for generating pull request descriptions to include a more structured format with sections for enhancements, fixes, and documentation. Also, added a poetry conclusion to the pull request description.

- **More General Custom LLM Access**: Refactored the `use_local_llm` function to `use_custom_llm`, allowing for custom (local or remote) language model endpoints compatible with the OpenAI API specification. Added an optional API key and model parameter for custom LLM services.

#### Fixes

- Improved error handling in LLM requests by checking if the error object is a character string or has a message attribute.

#### Summary

This pull request brings several improvements to the LLM operations, including enhanced pull request description generation, improved LLM output readability, and better error handling. Additionally, it adds a generation speed metric and refactors the `use_local_llm` function for custom language model endpoints.

## AiGitCraft 0.1.0: Initial beta release
