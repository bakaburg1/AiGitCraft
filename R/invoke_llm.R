#' Submit a prompt to an LLM via ellmer
#'
#' @param system_prompt The system prompt defining the assistant behavior.
#' @param user_prompt The user prompt describing the task.
#' @param ... Additional arguments passed to [ellmer::chat()] to configure the
#'   provider, model, or other options.
#'
#' @return The assistant response as a character string.
#' @keywords internal
invoke_llm <- function(system_prompt, user_prompt, ...) {
  args <- list(...)
  args <- args[!vapply(args, is.null, logical(1))]

  if (is.null(args$name)) {
    default_name <- getOption("aigitcraft_llm", "openai/gpt-4.1")
    if (is.null(default_name) || !nzchar(default_name)) {
      stop(
        "Please supply a provider via the `name` argument or set ",
        "options(aigitcraft_llm = \"provider/model\")."
      )
    }
    args$name <- default_name
  }

  cli::cli_alert_info("Using the {args$name} model...")

  args$system_prompt <- system_prompt

  chat <- do.call(ellmer::chat, args)
  chat$chat(user_prompt)
}
