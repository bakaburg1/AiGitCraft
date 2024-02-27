
#' Create a pull request description automatically
#'
#' This function uses LLM to create a pull request description automatically using
#' the differences between two branches.
#'
#' @param repo The path to the repository.
#' @param source_branch The source branch (i.e. the branch you want to merge into).
#' @param target_branch The target branch (i.e. the branch you want to merge from).
#' @param ... Additional arguments to be passed to `interrogate_llm`.
#'
#' @return A character string with the pull request description.
#'
#' @export
create_pull_request_description <- function(
    repo = getOption("aigitcraft_repo"),
    source_branch, target_branch,
    ...
) {

  system_prompt = "You are an AI expert in git and version control understanding"
  user_prompt = paste(
    "The following is the commit by commit diff between my branch and the main branch: ######\n",
    get_commit_differences(repo, source_branch, target_branch),
    "\n#######\n",
    "Your task is to understand the difference between the two branches and provide info for a pull request, that is a title and a change log. Use both the commit messages and the diff to understand the logic and implication of the changes. Mention the relevant commit ID when you discuss the changes. Do not describe the project in general, I wrote it! Try to infer the most user impacting changes and put them first in the description and use them to draft the pull request title.")

  interrogate_llm(c(system = system_prompt, user = user_prompt), ...)
}
