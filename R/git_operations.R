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
    target_branch = git2r::repository_head()$name,
    source_branch = "main",
    screened_folders = NULL
) {
  # TODO: add possibility to analyze only specific files

  withr::with_dir(repo_path, {

    # Open the repository
    repo <- git2r::repository(repo_path)

    # List commits on source_branch not on target_branch
    source_commits <- git2r::commits(repo, ref = source_branch)
    target_commits <- git2r::commits(repo, ref = target_branch)
    diff_commits <- setdiff(target_commits, source_commits)

    if (length(diff_commits) == 0) {
      message("No differences between the branches.")
      return(NULL)
    }

    # Iterate over the commits
    purrr::map_chr(diff_commits, \(commit) {

      # Assuming each commit has one parent for simplicity
      parent_commit <- git2r::parents(commit)[[1]]

      if (length(parent_commit) == 0) {
        return("")
      }

      # Append commit information and diff to output text
      tryCatch({
        get_commit_differences(
          commit,
          screened_folders = file.path(getwd(), screened_folders))
      }, error = function(e) {
        warning(e)
        return("")
      })
    }) |> paste(collapse = "\n")
  })
}


#' Get the differences between two commits
#'
#' This function returns the differences between two commits.
#'
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
    target_commit = git2r::last_commit(
      getOption("aigitcraft_repo", getwd())
    ),
    source_commit = NULL,
    screened_folders = NULL
) {

  no_comparison <- FALSE

  # The use of the parent commit is done here instead of as default argument to
  # have a marker that we are describing the target commit only
  if (is.null(source_commit)) {
    source_commit <- git2r::parents(target_commit)[[1]]

    no_comparison <- TRUE
  }

  if (length(source_commit) == 0) {
    stop("Diff on the first commit has not yet been implemented.")
  }

  # Get the diff between the commit and its parent
  # This may need adjustment for merge commits or more complex scenarios
  diff_data <- git2r::diff(
    git2r::tree(target_commit), git2r::tree(source_commit),
    as_char = TRUE, path = screened_folders)

  # If there are no differences, return NULL
  if (diff_data == "") {
    message("No differences between the commits.")
    return(NULL)
  }

  # Append commit information and diff to output text
  if (no_comparison) {
    # Detail on the target commit
    output_text <- paste0(
      "Commit: ", git2r::sha(target_commit), "\n",
      "Parent Commit", git2r::sha(source_commit), "\n",
      "Message: ", target_commit$message, "\n",
      "Date: ", target_commit$author$when, "\n\n",
      "Differences: #####\n",
      diff_data,
      "\n\n--------------------------------\n\n")
  } else {
    # Comparison between commits
    output_text <- paste0(
      sprintf(
        "Commits: %s vs %s\n",
        git2r::sha(target_commit), git2r::sha(source_commit)),
      sprintf(
        "Dates: %s vs %s\n",
        target_commit$author$when, source_commit$author$when),

      "Differences: #####\n",
      diff_data,
      "\n\n--------------------------------\n\n")
  }

  return(output_text)
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

  withr::with_dir(repo_path, {

    if (isFALSE(staged)) {
      changes <- git2r::diff(
        git2r::tree(
          git2r::last_commit(repo_path)),
        as_char = T,
        path = screened_folders)
    } else {
      if (is.null(screened_folders)) {
        screened_folders <- ""
      }

      gitCommand <- sprintf("git diff --cached %s", screened_folders) |>
        trimws()

      # Execute the git command and capture the output
      changes <- system(gitCommand, intern = TRUE) |> paste(collapse = "\n")
    }

    # If there are no differences, return NULL
    if (changes == "") {
      if (isTRUE(staged)) {
        message("No staged changes.")
      } else {
        message("No uncommitted changes since the last commit.")
      }

      return(NULL)
    }

    changes
  })
}

