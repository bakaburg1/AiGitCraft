test_that("write_pull_request_description sends diff context to LLM", {
  skip_if_not_installed("gert")

  repo <- withr::local_tempdir()
  gert::git_init(repo)

  calls <- list()
  res <- capture.output(
    with_mocked_bindings(
      get_branch_differences = function(...) "commit diff text",
      invoke_llm = function(system_prompt, user_prompt, ...) {
        calls <<- list(system = system_prompt, user = user_prompt)
        "mock response"
      },
      write_pull_request_description(
        repo_path = repo,
        target_branch = "main",
        source_branch = "main"
      )
    )
  )

  expect_equal(tail(res, 1), "mock response")
  expect_match(calls$system, "pull request description", ignore.case = TRUE)
  expect_match(calls$user, "commit diff text")
})

test_that("perform_code_change_review relays diff to invoke_llm", {
  skip_if_not_installed("gert")

  repo <- withr::local_tempdir()
  gert::git_init(repo)

  calls <- list()
  review <- capture.output(
    with_mocked_bindings(
      invoke_llm = function(system_prompt, user_prompt, ...) {
        calls <<- list(system = system_prompt, user = user_prompt)
        "review result"
      },
      perform_code_change_review("some diff here", repo_path = repo)
    )
  )

  expect_equal(tail(review, 1), "review result")
  expect_match(calls$user, "some diff here")
})

test_that("describe_uncommitted_changes includes diff text in prompt", {
  skip_if_not_installed("gert")

  repo <- withr::local_tempdir()
  gert::git_init(repo)

  calls <- list()
  output <- capture.output(
    with_mocked_bindings(
      get_uncommitted_changes = function(...) "working tree diff",
      invoke_llm = function(system_prompt, user_prompt, ...) {
        calls <<- list(system = system_prompt, user = user_prompt)
        "description result"
      },
      describe_uncommitted_changes(repo_path = repo)
    )
  )

  expect_equal(tail(output, 1), "description result")
  expect_match(calls$user, "working tree diff")
})

test_that("write_commit_message passes staged changes to invoke_llm", {
  skip_if_not_installed("gert")

  repo <- withr::local_tempdir()
  gert::git_init(repo)

  calls <- list()
  message_text <- capture.output(
    with_mocked_bindings(
      get_uncommitted_changes = function(repo_path, staged, ...) {
        if (staged) "staged diff" else stop("unexpected unstaged call")
      },
      invoke_llm = function(system_prompt, user_prompt, ...) {
        calls <<- list(system = system_prompt, user = user_prompt)
        "commit message"
      },
      write_commit_message(repo_path = repo)
    )
  )

  expect_equal(tail(message_text, 1), "commit message")
  expect_match(calls$user, "staged diff")
})

test_that("write_repo_readme packages code context for LLM", {
  skip_if_not_installed("gert")

  repo <- withr::local_tempdir()
  gert::git_init(repo)
  dir.create(file.path(repo, "R"))
  writeLines("some_function <- function() 42", file.path(repo, "R", "code.R"))
  writeLines("# Existing README", file.path(repo, "README.md"))

  calls <- list()
  content <- capture.output(
    with_mocked_bindings(
      invoke_llm = function(system_prompt, user_prompt, ...) {
        calls <<- list(system = system_prompt, user = user_prompt)
        "readme contents"
      },
      write_repo_readme(repo_path = repo, screened_folders = repo)
    )
  )

  expect_equal(tail(content, 1), "readme contents")
  expect_match(calls$user, "some_function")
})

test_that("generate_twitter_thread uses README content", {
  skip_if_not_installed("gert")

  repo <- withr::local_tempdir()
  gert::git_init(repo)
  writeLines("# Repo title", file.path(repo, "README.md"))

  calls <- list()
  thread <- capture.output(
    with_mocked_bindings(
      invoke_llm = function(system_prompt, user_prompt, ...) {
        calls <<- list(system = system_prompt, user = user_prompt)
        "tweet thread"
      },
      generate_twitter_thread(repo_path = repo)
    )
  )

  expect_equal(tail(thread, 1), "tweet thread")
  expect_match(calls$user, "Repo title")
})
