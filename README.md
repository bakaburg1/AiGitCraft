
<!-- README.md is generated from README.Rmd. Please edit that file -->

# AiGitCraft

<!-- badges: start -->
<!-- badges: end -->

AiGitCraft is an R package designed to enhance Git operations by
leveraging Large Language Models (LLMs) to automatically generate
meaningful commit messages, pull request descriptions, and other related
documentation. It simplifies the process of managing and documenting
code changes, making it easier for developers to maintain a clear and
informative history of their project’s evolution.

## Installation

You can install the development version of AiGitCraft from GitHub with:

``` r
# install.packages("pkgload")
remotes::install_github("bakaburg1/AiGitCraft")
```

## Features

- **Automatic Commit Messages**: Generate commit messages that
  accurately reflect the changes made, using context from the code and
  project documentation.
- **Pull Request Descriptions**: Generate detailed and structured pull
  request descriptions by analyzing the differences between branches.
- **Code Review Summaries**: Provide a summary of the changes made,
  helping reviewers to understand the context and impact of the
  modifications.
- **Commit Differences**: Retrieve and display the differences between
  commits in a human-readable format, aiding code reviews and
  documentation.
- **Uncommitted Changes Summary**: Describe the changes from the last
  committed state in a repository, helping developers to keep track of
  modifications.
- **README Generation**: Automatically write or update README files for
  repositories based on the content of the DESCRIPTION file and the code
  files.
- **LLM Integration**: Utilize various LLM providers such as OpenAI,
  Azure, or a local LLM server to process natural language tasks related
  to Git operations.
- **Bonus! Create a twitter thread**: Generate a twitter thread to
  present the repo based on the README.md file.

## Usage

### Generate pull request descriptions

To automatically create a pull request description:

``` r
library(AiGitCraft)

# Set the repository path and branches
repo_path <- "path/to/your/repo"
# or use getwd() or use getOption("aigitcraft_repo")

source_branch <- "main"
target_branch <- "feature-branch"

# Generate the pull request description
write_pull_request_description(
  repo_path, source_branch, target_branch,
  use_description = TRUE, # Optional, analyze the DESCRIPTION file to
                            # better understand the changes
  use_readme = TRUE, # Optional, analyze the README file to better understand
                       # the changes
  )
```

### Get description of uncommitted changes

To get the description of uncommitted changes in a repository:

``` r

# Get the uncommitted changes summary
get_uncommitted_changes_summary(
    repo = repo_path,
    screened_folders = "R" # Optional, specify the folders to screen for changes
    staged = FALSE, # Optional, get the staged changes only
    use_description = TRUE, # Optional, analyze the DESCRIPTION file to
                            # better understand the changes
    use_readme = TRUE, # Optional, analyze the README file to better understand
                       # the changes
    cite_changes = TRUE, # Optional, cite the changes positions in the summary.
                         # doesn't work always
    suggest_commits = TRUE # Optional, suggest commit messages for the changes
    )
```

### Generate commit messages

To generate a commit message for staged changes:

``` r

# Generate the commit message
write_commit_message(
  repo_path,
  use_conventional_commit = TRUE, # Optional, use the Conventional Commits
                                   # specification
  use_description = TRUE, # Optional, analyze the DESCRIPTION file to
                          # better understand the changes
  use_readme = TRUE, # Optional, analyze the README file to better understand
                     # the changes
  use_files = c(
  "this_file.R", "that_file.R") # Optional, specify a vector of files to analyze
                                # to help the LLM to understand the changes
  )
```

### Generate code review summaries

To generate a code review summaries of changes in the code:

``` r
# Generate the code review of the differences between the current branch and
# the main branch
perform_code_change_review(
  get_branch_differences(screened_folders = "R")
  )
  
# Generate the code review of the uncommitted changes
perform_code_change_review(
  get_uncommitted_changes_summary(
    repo = repo_path,
    screened_folders = "R"
    )
  )
  
# Generate the code review of the committee changes
perform_code_change_review(
  get_commit_differences(
    repo_path,
    commit_sha = "commit_sha",
    no_comparison = FALSE
    )
  )
```

### Generate README files

To automatically write or update README files for repositories:

``` r
# Generate the README file

write_repo_readme(
  repo_path,
  use_description = TRUE, # Optional, analyze the DESCRIPTION file to
                          # better understand the changes
  use_readme = TRUE, # Optional, analyze the README file to better understand
                     # the changes
  file_exts = c("R", "py") # Optional, include only the specified file
                            # extensions in the analysis
  code_folders = c("R", "test") # Optional, include only the specified
                                   # folders in the analysis, otherwise the
                                   # whole repository is analyzed
  recursive = TRUE # Optional, include the subfolders in the analysis
  )
```

## Configuration

AiGitCraft uses the `bakaburg1/llmR` package to interact with Large
Language Models (LLMs). To interact with LLM through the llmR package
you need to set up the necessary API keys and model identifiers for the
language model providers you intend to use. This can be done by setting
the appropriate options in R:

``` r
# OpenAI configuration example

options(
  
  # API providers
  llmr_llm_provider = "openai",
  
  # OpenAI GPT API
  llmr_openai_api_key_gpt = "your-openai-api-key",
)

# Azure configuration example

options(

  # API providers
  llmr_llm_provider = "azure",

  # Azure GPT API
  llmr_azure_resource_gpt = "your-azure-resource",
  llmr_azure_deployment_gpt = "your-azure-deployment",
  llmr_azure_api_key_gpt = "your-azure-api-key",

  # Azure common parameters
  llmr_azure_api_version = "" # See Azure API documentation
)

# Custom LLM server configuration example
# Can be used for local LLM servers or custom API endpoints following the
# OpenAi API specification.

options(

  # API providers
  llmr_llm_provider = "custom",

  # Local LLM server example
  llmr_custom_llm_endpoint = "http://localhost:1234/v1/chat/completions",
  llmr_custom_model_gpt = "llama3-8b-8192"
)
```

## License

AiGitCraft is licensed under the MIT License. See the LICENSE file for
more details.

------------------------------------------------------------------------

Please note that AiGitCraft is still under development and features may
change. Always refer to the package’s documentation for the most
up-to-date information.
