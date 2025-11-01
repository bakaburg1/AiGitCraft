#' Get the differences between two branches
#'
#' This function takes a repository path, a source branch, and a target branch
#' and returns the differences between the two branches.
#'
#' @param repo_path The path to the repository.
#' @param target_branch The target branch (i.e. the branch you want to merge
#'   from). Default is the current branch.
#' @param source_branch The source branch (i.e. the branch you want to merge
#'   into). Default is 'main'.
#' @param screened_folders The path to the folders to be considered for changes.
#'   If NULL (the default), all the folders in the repository are screened.
#'
#' @return A character string with the differences between the two branches,
#'   displayed as a series of commits and their associated differences.
#'
#' @export
get_branch_differences <- function(
  repo_path = getOption("aigitcraft_repo", getwd()),
  target_branch = NULL,
  source_branch = "main",
  screened_folders = NULL
) {
  # TODO: add possibility to analyze only specific files

  validate_repo_path(repo_path)

  if (length(screened_folders) == 0) {
    screened_folders <- NULL
  }

  if (is.null(target_branch)) {
    branch_info <- gert::git_branch(repo = repo_path)
    target_branch <- resolve_git_branch(branch_info, repo_path)
  }

  max_commits <- getOption("aigitcraft_git_log_max", 1000L)
  max_commits <- as.integer(max_commits)
  if (is.na(max_commits) || max_commits <= 0L) {
    max_commits <- 1000L
  }

  target_commits <- gert::git_log(
    ref = target_branch,
    max = max_commits,
    repo = repo_path
  )

  source_commits <- gert::git_log(
    ref = source_branch,
    max = max_commits,
    repo = repo_path
  )

  diff_commits <- target_commits$commit[
    !target_commits$commit %in% source_commits$commit
  ]

  if (length(diff_commits) == 0) {
    cli::cli_alert_info("No differences between the branches.")
    return(NULL)
  }

  purrr::map_chr(diff_commits, function(commit_id) {
    tryCatch(
      {
        res <- get_commit_differences(
          repo_path = repo_path,
          target_commit = commit_id,
          screened_folders = screened_folders
        )

        if (is.null(res)) "" else res
      },
      error = function(e) {
        cli::cli_alert_danger(conditionMessage(e))
        ""
      }
    )
  }) |>
    paste(collapse = "\n")
}


#' Get the differences between two commits
#'
#' This function returns the differences between two commits.
#'
#' @param repo_path The path to the repository.
#' @param target_commit The target commit.
#' @param source_commit The source commit. If NULL, the parent commit of the
#'   target commit is used.
#' @param screened_folders The path to the folders to be considered for changes.
#'   If NULL (the default), all the folders in the repository are screened.
#'
#' @return A character string with the differences between the two commits. If
#'   only the target commit is provided, then the output will be the details of
#'   the target commit.
#'
#' @export
get_commit_differences <- function(
  repo_path = getOption("aigitcraft_repo", getwd()),
  target_commit = NULL,
  source_commit = NULL,
  screened_folders = NULL
) {
  validate_repo_path(repo_path)

  if (length(screened_folders) == 0) {
    screened_folders <- NULL
  }

  withr::with_dir(repo_path, {
    if (is.null(target_commit)) {
      target_commit <- gert::git_commit_id()
    }

    target_info <- gert::git_commit_info(target_commit)
    using_parent <- is.null(source_commit)

    if (using_parent) {
      if (length(target_info$parents) == 0) {
        cli::cli_abort("Diff on the first commit has not yet been implemented.")
      }
      source_commit <- target_info$parents[[1]]
    }

    if (is.null(source_commit) || !nzchar(source_commit)) {
      cli::cli_abort("Unable to determine source commit for comparison.")
    }

    if (!using_parent) {
      source_info <- gert::git_commit_info(source_commit)
    } else {
      source_info <- NULL
    }

    diff_args <- c("diff", source_commit, target_commit)
    if (!is.null(screened_folders)) {
      diff_args <- c(diff_args, "--", screened_folders)
    }

    # Capture stderr separately to preserve detailed git error messages
    diff_stderr <- tempfile()
    on.exit(unlink(diff_stderr), add = TRUE)

    diff_output <- system2(
      command = "git",
      args = diff_args,
      stdout = TRUE,
      stderr = diff_stderr
    )
    status <- attr(diff_output, "status")
    diff_errors <- if (file.exists(diff_stderr)) {
      readLines(diff_stderr, warn = FALSE)
    } else {
      character()
    }
    if (!is.null(status) && status != 0) {
      err_msg <- if (length(diff_errors)) {
        paste(diff_errors, collapse = "\n")
      } else {
        "unknown git error"
      }
      cli::cli_abort("Failed to compute git diff: {err_msg}")
    }
    diff_text <- paste(diff_output, collapse = "\n")

    if (identical(diff_text, "")) {
      cli::cli_alert_info("No differences between the commits.")
      return(NULL)
    }

    formatted_time <- function(x) format(x, usetz = TRUE)

    if (using_parent) {
      paste0(
        "Commit: ",
        target_commit,
        "\n",
        "Parent Commit: ",
        source_commit,
        "\n",
        "Message: ",
        target_info$message,
        "\n",
        "Date: ",
        formatted_time(target_info$time),
        "\n\n",
        "Differences: #####\n",
        diff_text,
        "\n\n--------------------------------\n\n"
      )
    } else {
      paste0(
        sprintf(
          "Commits: %s vs %s\n",
          target_commit,
          source_commit
        ),
        sprintf(
          "Dates: %s vs %s\n",
          formatted_time(target_info$time),
          formatted_time(source_info$time)
        ),
        "Differences: #####\n",
        diff_text,
        "\n\n--------------------------------\n\n"
      )
    }
  })
}

#' Get the uncommitted changes in the repository
#'
#' This function returns the uncommitted changes in the repository, staged or
#' unstaged.
#'
#' @param repo_path The path to the repository.
#' @param screened_folders The path to the folders to be considered for changes.
#'   If NULL (the default), all the folders in the repository are screened.
#' @param staged Whether to return the staged changes only. Default is FALSE.
#'
#' @return A character string with the uncommitted changes in the repository.
#'
#' @export
get_uncommitted_changes <- function(
  repo_path = getOption("aigitcraft_repo", getwd()),
  screened_folders = NULL,
  staged = FALSE
) {
  validate_repo_path(repo_path)

  if (length(screened_folders) == 0) {
    screened_folders <- NULL
  }

  withr::with_dir(repo_path, {
    diff_args <- if (isTRUE(staged)) {
      c("diff", "--cached")
    } else {
      c("diff", "HEAD")
    }

    if (!is.null(screened_folders)) {
      diff_args <- c(diff_args, "--", screened_folders)
    }

    # Capture stderr separately to preserve detailed git error messages
    changes_stderr <- tempfile()
    on.exit(unlink(changes_stderr), add = TRUE)

    changes <- system2(
      command = "git",
      args = diff_args,
      stdout = TRUE,
      stderr = changes_stderr
    )
    status <- attr(changes, "status")
    change_errors <- if (file.exists(changes_stderr)) {
      readLines(changes_stderr, warn = FALSE)
    } else {
      character()
    }
    if (!is.null(status) && status != 0) {
      err_msg <- if (length(change_errors)) {
        paste(change_errors, collapse = "\n")
      } else {
        "unknown git error"
      }
      cli::cli_abort("Failed to retrieve git diff: {err_msg}")
    }

    diff_text <- paste(changes, collapse = "\n")

    # If there are no differences, return NULL
    if (identical(diff_text, "")) {
      if (isTRUE(staged)) {
        cli::cli_alert_info("No staged changes.")
      } else {
        cli::cli_alert_info("No uncommitted changes since the last commit.")
      }

      return(NULL)
    }

    diff_text
  })
}
