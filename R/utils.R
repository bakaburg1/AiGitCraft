#' Check and install dependencies
#'
#' Checks if a list of packages are installed and installs them if not. Trigger
#' an error if the user chooses not to install a package.
#'
#' @param deps A character vector of package names.
#'
#' @return Nothing.
#'
check_and_install_dependencies <- function(deps) {
  for (dep in deps) {
    stop_message <- paste0(dep, " is required but was not installed.")
    # Check if the package is installed
    is_installed <- requireNamespace(dep, quietly = TRUE)

    if (!is_installed) {
      # If not, ask the user if they want to install it
      if (interactive()) {
        # Only in interactive sessions, otherwise just stop
        do_install <- utils::menu(
          c("Yes", "No"),
          title = paste0(dep, " is not installed. Install it now?")
        )

        if (do_install == 1) {
          tryCatch(
            {
              utils::install.packages(dep)
              # After successful installation, recheck if the package is now installed
              is_installed <- requireNamespace(dep, quietly = FALSE)
            },
            error = function(e) {
              cli::cli_abort("Failed to install {dep}: {e$message}")
            }
          )
        }
      }
    }

    # Stop if the package is not installed
    if (!is_installed) cli::cli_abort(stop_message)
  }
}

#' Validate the repository path
#'
#' This function validates the repository path provided by the user.
#'
#' @param repo_path The path to the repository.
#'
#' @return Nothing.
validate_repo_path <- function(repo_path) {
  if (!dir.exists(repo_path)) {
    cli::cli_abort("Invalid repo_path. Please provide a valid directory path.")
  }

  if (!file.exists(file.path(repo_path, ".git"))) {
    cli::cli_abort("The repository path does not contain a .git folder.")
  }
}

#' Normalize branch metadata returned by gert
#'
#' @param branch_info Value returned by [gert::git_branch()].
#' @param repo_path Repository path, used for error context.
#'
#' @return Character scalar with the branch name.
resolve_git_branch <- function(branch_info, repo_path) {
  # Handle case where input is NULL: cannot continue without branch info
  if (is.null(branch_info)) {
    cli::cli_abort(
      "Unable to determine target branch for repository {.path {repo_path}}."
    )
  }

  # Main path: branch_info is a data.frame (most likely gert::git_branch()
  # output)
  if (is.data.frame(branch_info)) {
    # Fail early if there are no rows, i.e. no branches found
    if (nrow(branch_info) == 0L) {
      cli::cli_abort("No branches found in repository {.path {repo_path}}.")
    }

    # Prepare to detect HEAD/active branch in flexible schema
    branch_flags <- rep(FALSE, nrow(branch_info))
    if ("head" %in% names(branch_info)) {
      # 'head' is typical with gert, TRUE for row representing current HEAD
      branch_flags <- branch_flags |
        vapply(
          branch_info$head,
          function(value) isTRUE(as.logical(value)),
          logical(1)
        )
    }
    if ("active" %in% names(branch_info)) {
      # Some situations use 'active' instead of 'head'
      branch_flags <- branch_flags |
        vapply(
          branch_info$active,
          function(value) isTRUE(as.logical(value)),
          logical(1)
        )
    }

    # Identify which row(s) is considered HEAD/active branch
    head_idx <- which(branch_flags)
    if (length(head_idx) == 0L) {
      # If not found, fallback to first row (arbitrary, but safe in most CLIs)
      head_idx <- 1L
    } else {
      # Take the first match if multiple
      head_idx <- head_idx[[1]]
    }

    # Flexibly retrieve the correct column for branch name, supporting both
    # styles
    name_column <- NULL
    if ("name" %in% names(branch_info)) {
      name_column <- branch_info$name
    } else if ("branch" %in% names(branch_info)) {
      name_column <- branch_info$branch
    }

    # Defensive: abort if we couldn't find a proper column or index out of
    # bounds
    if (is.null(name_column) || length(name_column) < head_idx) {
      cli::cli_abort(
        "Unable to determine target branch from repository metadata."
      )
    }

    branch_name <- name_column[[head_idx]]
    # Validate branch name is proper non-empty character scalar
    if (!is.character(branch_name) || !nzchar(branch_name)) {
      cli::cli_abort("Invalid branch name detected in repository metadata.")
    }

    return(branch_name)
  }

  # If branch_info is already a character vector, return its first element
  if (is.character(branch_info)) {
    branch_name <- branch_info[[1]]
    if (!nzchar(branch_name)) {
      cli::cli_abort("Invalid branch name returned by gert::git_branch().")
    }
    return(branch_name)
  }

  # Defensive: catch all other unexpected input types
  cli::cli_abort(
    "Unsupported branch metadata type returned by gert::git_branch() for repository {.path {repo_path}}."
  )
}

#' Include context from a file in a prompt
#'
#' This function reads a file and includes its content in a prompt.
#'
#' @param file_path The path to the file.
#' @param prompt_text The text to include before and after the file content.
#'
#' @return A character string with the prompt text and the file content.
#'
generate_context_file_prompt <- function(file_path, prompt_text) {
  prompt <- NULL

  if (file.exists(file_path)) {
    prompt <- paste0(
      "\n\n",
      prompt_text,
      "\n\n####\n",
      readr::read_file(file_path),
      "####"
    )
  }

  prompt
}

#' Generate a prompt with the content of the DESCRIPTION file
#'
#' This function reads the DESCRIPTION file of a code repository and includes
#' its content in a prompt.
#'
#' @param repo_path The path to the code repository.
#'
#' @return A character string with the prompt text and the DESCRIPTION file
#'   content.
#'
generate_DESCRIPTION_context_prompt <- function(repo_path) {
  generate_context_file_prompt(
    file_path = file.path(repo_path, "DESCRIPTION"),
    prompt_text = "This is the content of the DESCRIPTION file of the code repo, which may give hints on the general goals of the repo:"
  )
}

#' Generate a prompt with the content of the README.md file
#'
#' This function reads the README.md file of a code repository and includes
#' its content in a prompt.
#'
#' @param repo_path The path to the code repository.
#'
#' @return A character string with the prompt text and the README.md file
#'   content.
#'
generate_README_context_prompt <- function(repo_path) {
  generate_context_file_prompt(
    file_path = file.path(repo_path, "README.md"),
    prompt_text = "This is the content of the README.md file of the code repo, which describes the repo. Use it to understand what the repo does:"
  )
}
