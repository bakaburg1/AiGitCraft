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
          title = paste0(dep, " is not installed. Install it now?")) == 1

        if(do_install) {
          tryCatch({
            utils::install.packages(dep)
            # After successful installation, recheck if the package is now installed
            is_installed <- requireNamespace(dep, quietly = FALSE)
          }, error = function(e) {
            stop("Failed to install ", dep, ": ", e$message)
          })
        }
      }
    }

    # Stop if the package is not installed
    if (!is_installed) stop(stop_message)
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
    stop("Invalid repo_path. Please provide a valid directory path.")
  }

  if (!file.exists(file.path(repo_path, ".git"))) {
    stop("The repository path does not contain a .git folder.")
  }
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
      "\n\n", prompt_text, "\n\n####\n",
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
