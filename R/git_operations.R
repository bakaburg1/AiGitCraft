#' Get the differences between two branches
#'
#' This function takes a repository path, a source branch, and a target branch
#' and returns the differences between the two branches.
#'
#' @param repo_path The path to the repository.
#' @param source_branch The source branch (i.e. the branch you want to merge
#'   into).
#' @param target_branch The target branch (i.e. the branch you want to merge
#'   from).
#'
#' @return A character string with the differences between the two branches,
#'   displayed as a series of commits and their associated differences.
get_commit_differences <- function(repo_path, source_branch, target_branch) {
  # Open the repository
  repo <- git2r::repository(repo_path)

  # List commits on source_branch not on target_branch
  source_commits <- git2r::commits(repo, ref = source_branch)
  target_commits <- git2r::commits(repo, ref = target_branch)
  commits <- setdiff(target_commits, source_commits)

  # Initialize an empty string to store the output
  output_text <- ""

  # Iterate over the commits
  for (commit in commits) {

    # Assuming each commit has one parent for simplicity
    parent_commit <- git2r::parents(commit)[[1]]

    # Get the diff between the commit and its parent
    # This may need adjustment for merge commits or more complex scenarios
    diff_data <- git2r::diff(
      git2r::tree(commit), git2r::tree(parent_commit), as_char = T)

    # Append commit information and diff to output text
    output_text <- paste0(output_text,
                          "Commit: ", git2r::sha(commit), "\n",
                          "Parent Commit", git2r::sha(parent_commit), "\n",
                          "Message: ", commit$message, "\n",
                          "Date: ", commit$author$when, "\n\n",
                          "Differences: #####\n",
                          diff_data,
                          "\n\n--------------------------------\n\n")
  }

  return(output_text)
}
