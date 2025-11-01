test_that("generate_context_file_prompt returns formatted content", {
  tmp <- withr::local_tempfile()
  writeLines(c("alpha", "beta"), tmp)

  prompt <- generate_context_file_prompt(tmp, "HEADER")

  expect_true(grepl("HEADER", prompt))
  expect_true(grepl("alpha", prompt))
  expect_true(grepl("beta", prompt))
  expect_true(grepl("####", prompt, fixed = TRUE))
})

test_that("generate_context_file_prompt returns NULL for missing file", {
  missing_path <- file.path(tempdir(), "no-file.txt")
  expect_null(generate_context_file_prompt(missing_path, "anything"))
})

test_that("description and readme prompts reuse helper", {
  repo <- withr::local_tempdir()
  writeLines("Package: demo", file.path(repo, "DESCRIPTION"))
  writeLines("# README", file.path(repo, "README.md"))

  desc_prompt <- generate_DESCRIPTION_context_prompt(repo)
  readme_prompt <- generate_README_context_prompt(repo)

  expect_true(grepl("Package: demo", desc_prompt))
  expect_true(grepl("# README", readme_prompt))
})

test_that("validate_repo_path checks git root", {
  repo <- withr::local_tempdir()
  dir.create(file.path(repo, ".git"))

  expect_silent(validate_repo_path(repo))
  expect_error(validate_repo_path(tempfile()), "Invalid repo_path")

  nogit <- withr::local_tempdir()
  expect_error(validate_repo_path(nogit), "does not contain a .git")
})

test_that("resolve_git_branch returns name from character vector", {
  branch <- resolve_git_branch(c("dev", "main"), tempdir())
  expect_identical(branch, "dev")
})

test_that("resolve_git_branch selects head branch from data frame", {
  repo <- withr::local_tempdir()
  branch_df <- data.frame(
    name = c("main", "feature"),
    head = c(FALSE, TRUE),
    active = c(FALSE, TRUE)
  )

  branch <- resolve_git_branch(branch_df, repo)
  expect_identical(branch, "feature")
})
