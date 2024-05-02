
#' Create a pull request description automatically
#'
#' This function uses LLM to create a pull request description automatically
#' using the differences between two branches.
#'
#' @param repo_path The path to the repository.
#' @param target_branch The target branch (i.e. the branch you want to merge
#'   from). Default is the current branch.
#' @param source_branch The source branch (i.e. the branch you want to merge
#'   into). Default is 'main'.
#' @param screened_folders The path to the folders to be considered for changes.
#'   If NULL (the default), all the folders in the repository are screened.
#' @param use_description Logical indicating whether to include the content of
#'   the DESCRIPTION file in the repository to help understand the changes.
#' @param use_readme Logical indicating whether to include the content of the
#'   README.md file in the repository to help understand the changes.
#' @param ... Additional arguments to be passed to `prompt_llm`.
#'
#' @return A character string with the pull request description.
#'
#' @export
write_pull_request_description <- function(
    repo_path = getOption("aigitcraft_repo", getwd()),
    target_branch = git2r::repository_head()$name,
    source_branch = "main",
    screened_folders = NULL,
    use_description = TRUE,
    use_readme = TRUE,
    ...
) {

  withr::with_dir(repo_path, {

    system_prompt = "You are an AI expert in git and version control understanding, whose goal is to help a developer write a pull request description."

    diff_text <- get_branch_differences(
      repo_path = repo_path,
      target_branch = target_branch,
      source_branch = source_branch,
      screened_folders = screened_folders)

    if (is.null(diff_text)) {
      return(NULL)
    }

    user_prompt = c(
      "The following is the commit by commit diff between my branch and the main branch: ######\n",
      if (isTRUE(use_description) && file.exists("DESCRIPTION")) {
        c(
          "This is the content of the DESCRIPTION file of the code repo, which may give hints on the general goals of the repo:",
          "####",
          readr::read_file("DESCRIPTION"),
          "####"
        )
      },
      if (isTRUE(use_readme) && file.exists("README.md")) {
        c(
          "This is the content of the README.md file of the code repo, which describes the repo:",
          "####",
          readr::read_file("README.md"),
          "####"
        )
      },
      "The following is the commit by commit diff between my branch and the main branch:",
      "######",
      diff_text,
      "#######",
      "Your task is to understand the difference between the two branches and provide info for a pull request, that is, a title and the change log.

Use both the commit messages and the diff to understand the logic and implication of the changes. Mention the relevant commit ID when you discuss the changes. Do not describe the project in general, I wrote it!

Separate the changes into sections such as 'Enhancements', 'Fixes', and 'Documentation', as required.

Format the pull request as markdown with the following structure: ```
## Pull request title

#### Enhancements
- Enhancement 1 title: description of enhancement (Commit: ***).
- Enhancement n title: description of enhancement (Commit: ***).

#### Fixes
- Fix 1 title: description of fix (Commit: ***).
- Fix n title: description of fix (Commit: ***).

#### Documentation (optional)
- Documentation 1 title: description of documentation change (Commit: ***).
- Documentation n title: description of documentation change (Commit: ***).

#### Summary
General description of the changes.
```

Try to infer the most user impacting changes and put them first in the description and use them to draft the pull request title.

Conclude the pull request description with a short and funny poetry of maximum 6 lines expressing the essence of the changes.") |>
      paste(collapse = "\n\n")

    res <- prompt_llm(c(system = system_prompt, user = user_prompt), ...)

    cat(res)

    invisible(res)
  })
}

#' Describe the changes from the last committed state in a git repository.
#'
#' This function uses LLM to describe the changes from the last committed state
#' in a git repository.
#'
#' @param repo_path The path to the repository.
#' @param screened_folders The path to the folders to be screened for changes.
#'   If NULL (the default), all the folders in the repository are screened.
#' @param staged Logical indicating whether to include only staged changes.
#' @param use_description Logical indicating whether to include the content of
#'   the DESCRIPTION file in the repository.
#' @param use_readme Logical indicating whether to include the content of the
#'   README.md file in the repository.
#' @param cite_changes Logical indicating whether to include a prompt to cite
#'   the relevant files and lines for the changes.
#' @param suggest_commits Logical indicating whether to include a prompt to
#'   suggest a commit message and the involved files and lines for each logical
#'   group of changes.
#' @param ... Additional arguments to be passed to `prompt_llm`.
#'
#' @return A character string with the description of the changes.
#'
#' @export
#'
describe_uncommitted_changes <- function(
    repo_path = getOption("aigitcraft_repo", getwd()),
    screened_folders = NULL,
    staged = FALSE,
    use_description = TRUE,
    use_readme = TRUE,
    cite_changes = TRUE,
    suggest_commits = TRUE,
    ...
) {

  withr::with_dir(repo_path, {

    uncommitted_changes <- get_uncommitted_changes(
      repo_path = repo_path,
      staged = staged,
      screened_folders = screened_folders)

    if (is.null(uncommitted_changes)) {
      return(NULL)
    }

    system_prompt = "You are an AI expert in git and version control understanding, whose goal is to help a developer understand the code in a repository."

    user_prompt = c(
      "I'm working on a code repo and I need to understand what are the last changes introduced since the last commit.",
      if (isTRUE(use_description) && file.exists("DESCRIPTION")) {
        c(
          "This is the content of the DESCRIPTION file of the code repo: ####\n\n",
          readr::read_file("DESCRIPTION"),
          "####"
        )
      },
      if (isTRUE(use_readme) && file.exists("README.md")) {
        c(
          "This is the content of the README.md file of the code repo: ####\n\n",
          readr::read_file("README.md"),
          "####"
        )
      },
      "Here are the changes in the repo since the last commited state:",
      "####",
      uncommitted_changes,
      "#######",
      "Your task is to understand the edits and provide a summary of the changes.",
      "Try to be smart and understand changes that are part of a logical group of changes (e.g. a new functionality, a bug fix, a refactoring, etc.) even if on different files and will be probably be committed together, and those that are isolated (i.e., will be committed individually).",
      if (isTRUE(cite_changes)) {
        "Cite the relevant files and lines for the changes you describe."
      },
      if (isTRUE(suggest_commits)) {
        "If you can, suggest a commit message and the involved files and lines for each logical group of changes."
      }
    ) |>
      paste(collapse = "\n")

    res <- prompt_llm(c(system = system_prompt, user = user_prompt), ...)

    cat(res)

    invisible(res)

  })
}

#' Write a commit message for the staged changes
#'
#' This function uses LLM to write a commit message for the staged changes in a
#' git repository.
#'
#' @param repo_path The path to the repository.
#' @param use_conventional_commit Logical indicating whether to style commit
#'   messages according to the Conventional Commits specification
#'   (https://www.conventionalcommits.org/en/v1.0.0/).
#' @param use_description Logical indicating whether to include the content of
#'   the DESCRIPTION file to help understand the changes.
#' @param use_readme Logical indicating whether to include the content of the
#'   README.md file to help understand the changes.
#' @param use_files A vector of file paths to analyze to help understand the
#'   changes.
#' @param ... Additional arguments to be passed to `prompt_llm`.
#'
#' @return A character string with the commit message.
#'
#' @export
write_commit_message <- function(
    repo_path = getOption("aigitcraft_repo", getwd()),
    use_conventional_commit = TRUE,
    use_description = TRUE,
    use_readme = TRUE,
    use_files = NULL,
    ...
) {

  withr::with_dir(repo_path, {

    staged_changes <- get_uncommitted_changes(
      repo_path = repo_path, staged = TRUE)

    if (is.null(staged_changes)) {
      return(NULL)
    }

    system_prompt = "You are an AI expert in git and version control understanding, whose goal is to help a developer write a commit message for the staged changes in a git repository."

    user_prompt = c(
      "I'm working on a code repo and I need to write a commit message for the staged changes.",
      if (isTRUE(use_description) && file.exists("DESCRIPTION")) {
        c(
          "This is the content of the DESCRIPTION file of the code repo which may give hints on the general goals of the repo:",
          "####",
          readr::read_file("DESCRIPTION"),
          "####"
        )
      },
      if (isTRUE(use_readme) && file.exists("README.md")) {
        c(
          "This is the content of the README.md file of the code repo which describes the repo:",
          "####",
          readr::read_file("README.md"),
          "####"
        )
      },
      if (length(use_files) > 0) {
        c(
          "The following is the content of related files you need to analyze to understand the changes:",
          "####",
          purrr::map_chr(use_files, ~ paste0(
            "------------- ", .x, "\n", readr::read_file(.x), "\n\n")
          ) |> paste(collapse = "\n\n"),
          "####"
        )
      },
      "Here are the changes in the repo that are staged for commit:",
      "####",
      staged_changes,
      "#######",
      "Your task is to understand the staged changes and write a commit message for them.",
      if (isTRUE(use_conventional_commit)) {
        "Try to style the commit message according to the Conventional Commits specification (https://www.conventionalcommits.org/en/v1.0.0/). I.e. use the following format: ###
      type(scope): title

      body
      ###
      The type can be one of the following: feat, fix, docs, style, refactor, test, chore, or a custom type. The scope is optional and can be anything specifying the place of the commit change."
      } else {
        "Use the following structure for the commit message: ####
      title

      body
      ###
      "
      },
      "Remember that the commit message title should be a short and meaningful description of the changes while you can add more details in message body."
    ) |>
      paste(collapse = "\n")

    res <- prompt_llm(c(system = system_prompt, user = user_prompt), ...)

    cat(res)

    invisible(res)

  })
}


#' Write a README for a code repo
#'
#' This function uses LLM to write a README file for a code repository based on
#' the content of the DESCRIPTION (optional) file and the code files. If the
#' README.md file already exists in the repository, the function will try to
#' update it with the new content.
#'
#' @param repo_path The path to the repository.
#' @param use_description Logical indicating whether to include the content of
#'   the DESCRIPTION file in the repository.
#' @param use_current_readme Logical indicating whether to update the content of
#'   the current README.md file in the repository.
#' @param file_exts The file extensions of the files to analyze to write the
#'   README. Should be a vector of extensions, e.g. c("R", "py", "js"). The
#'   extensions can be saved and retrieved project-wise using the
#'   `aigitcraft_file_exts` option.
#' @param screened_folders The path to the folders to be screened for code
#'   files. If NULL (the default), the whole repository is screened. It is
#'   suggested to include only the code folders, e.g. c("R", "src"), to avoid
#'   analyzing non-code and documentation files.
#' @param recursive Logical indicating whether to search for files recursively.
#' @param ... Additional arguments to be passed to `prompt_llm`.
#'
#' @return A character string with the content of the README file.
#'
#' @export
#'
write_repo_readme <- function(
    repo_path = getOption("aigitcraft_repo", getwd()),
    use_description = TRUE,
    use_current_readme = TRUE,
    file_exts = getOption("aigitcraft_file_exts"),
    screened_folders = getOption("aigitcraft_screened_folders", repo_path),
    recursive = TRUE,
    ...
) {

  withr::with_dir(repo_path, {

    system_prompt = "You are an AI expert in git and version control understanding, whose goal is to help a developer write a README file for a code repository."

    # Get the content of the code files
    file_text <- list.files(
      screened_folders, full.names = T, recursive = T,
      pattern = if (!is.null(file_exts)) {
        paste0("\\.(", file_exts |> paste(collapse = "|"), ")$")
        } else {
          "\\.[^\\.]+$"
        },
      ignore.case = T) |>
      stringr::str_subset("README", negate = T) |>
      purrr::map_chr(~ paste0(
        "------------- ", .x, "\n", readr::read_file(.x), "\n\n")
      ) |> paste(collapse = "\n\n")


    user_prompt = c(
      "I'm working on a code repo and I need to write/improve the README.md file for it.",
      if (isTRUE(use_description) && file.exists("DESCRIPTION")) {
        c(
          "This is the content of the DESCRIPTION file of the code repo, which may give hints on the general goals of the repo: ####\n\n",
          readr::read_file("DESCRIPTION"),
          "####"
        )
      },
      "The following is the content of the code files you need to analyze for writing the README:",
      "####",
      file_text,
      "####",
      if (isTRUE(use_current_readme) && file.exists("README.md")) {
        c(
          "This is the content of the current README.md file of the code repo: ####\n\n",
          readr::read_file("README.md"),
          "####",
          "Your task is to understand what the package does and update the README.md to provide a proper and well documented description of the repo."
        )
      } else {
        "Your task is to understand what the package does and write a proper and well documented README.md file content."
      }
    ) |>
      paste(collapse = "\n")

    res <- prompt_llm(c(system = system_prompt, user = user_prompt), ...)

    cat(res)

    invisible(res)

  })
}

#' Generate a Twitter thread
#'
#' This function uses LLM to generate a Twitter thread based on the repo README.md to present the repo to the community.
#'
#' @param repo_path The path to the repository.
#'
#' @return A character string with the content of the Twitter thread.
#'
#' @export
#'
generate_twitter_thread <- function(
    repo_path = getOption("aigitcraft_repo", getwd())
) {

  withr::with_dir(repo_path, {

    if (!file.exists("README.md")) {
      stop("The README.md file does not exist in the repository.")
    }

    system_prompt = "You are an AI expert in git and version control understanding, whose goal is to help a developer write a Twitter thread to present a code repository to the community."

    user_prompt = c(
      "I'm working on a code repo and I need to write a Twitter thread to present it to the community.",
      "The following is the content of the README.md file of the code repo: ####\n\n",
      readr::read_file("README.md"),
      "####",
      "Your task is to understand what the package does and write a short Twitter thread (2 to 4 messages) to present it to the community."
    ) |>
      paste(collapse = "\n")

    res <- prompt_llm(c(system = system_prompt, user = user_prompt))

    cat(res)

    invisible(res)

  })
}
