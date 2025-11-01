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
