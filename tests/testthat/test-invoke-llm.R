test_that("invoke_llm uses default provider when none supplied", {
  skip_if_not_installed("ellmer")

  withr::local_options(aigitcraft_llm = "openai/mock")

  recorded <- list()
  cli_calls <- list()

  result <- with_mocked_bindings(
    chat = function(...) {
      recorded <<- list(args = list(...))
      list(chat = function(prompt) {
        recorded$response_prompt <<- prompt
        "mock reply"
      })
    },
    .package = "ellmer",
    with_mocked_bindings(
      cli_alert = function(...) {
        cli_calls <<- c(cli_calls, list(list(...)))
        invisible(NULL)
      },
      .package = "cli",
      invoke_llm("system text", "user text")
    )
  )

  expect_equal(result, "mock reply")
  expect_equal(recorded$args$name, "openai/mock")
  expect_equal(recorded$response_prompt, "user text")
  expect_length(cli_calls, 1)
})

test_that("invoke_llm honours explicit provider", {
  skip_if_not_installed("ellmer")

  recorded <- list()

  response <- with_mocked_bindings(
    chat = function(...) {
      recorded <<- list(args = list(...))
      list(chat = function(prompt) paste("echo", prompt))
    },
    .package = "ellmer",
    with_mocked_bindings(
      cli_alert = function(...) invisible(NULL),
      .package = "cli",
      invoke_llm("sys", "usr", name = "anthropic/test")
    )
  )

  expect_equal(response, "echo usr")
  expect_equal(recorded$args$name, "anthropic/test")
})

test_that("invoke_llm errors when no provider available", {
  skip_if_not_installed("ellmer")

  withr::local_options(aigitcraft_llm = "")

  expect_error(
    with_mocked_bindings(
      chat = function(...) stop("should not be called"),
      .package = "ellmer",
      with_mocked_bindings(
        cli_alert = function(...) invisible(NULL),
        .package = "cli",
        invoke_llm("sys", "usr")
      )
    ),
    "Please supply a provider"
  )
})
