skip_if_no_git <- function() {
  if (identical(Sys.which("git"), "")) {
    skip("git executable not available")
  }
}

test_that("get_commit_differences compares commits", {
  skip_if_not_installed("gert")
  skip_if_no_git()

  repo <- withr::local_tempdir()
  gert::git_init(repo)

  withr::with_dir(repo, {
    writeLines("first version", "file.txt")
    gert::git_add("file.txt")
    gert::git_commit("Initial commit")

    writeLines("second version", "file.txt")
    gert::git_add("file.txt")
    gert::git_commit("Update file")
  })

  commits <- gert::git_log(repo = repo)$commit
  latest <- commits[1]
  previous <- commits[2]

  diff_text <- get_commit_differences(
    repo_path = repo,
    target_commit = latest,
    source_commit = previous
  )

  expect_match(diff_text, latest, fixed = TRUE)
  expect_match(diff_text, "second version")
})

test_that("get_commit_differences defaults to parent commit", {
  skip_if_not_installed("gert")
  skip_if_no_git()

  repo <- withr::local_tempdir()
  gert::git_init(repo)

  withr::with_dir(repo, {
    writeLines("first", "file.txt")
    gert::git_add("file.txt")
    gert::git_commit("Initial")

    writeLines(c("first", "second"), "file.txt")
    gert::git_add("file.txt")
    gert::git_commit("Add second line")
  })

  latest <- gert::git_log(repo = repo)$commit[1]
  diff_text <- get_commit_differences(repo_path = repo, target_commit = latest)

  expect_match(diff_text, "Parent Commit:", fixed = TRUE)
  expect_match(diff_text, "second")
})

test_that("get_branch_differences aggregates commit diffs", {
  skip_if_not_installed("gert")
  skip_if_no_git()

  repo <- withr::local_tempdir()
  gert::git_init(repo)

  withr::with_dir(repo, {
    writeLines("base", "file.txt")
    gert::git_add("file.txt")
    gert::git_commit("Base commit")
  })

  default_branch <- gert::git_branch(repo = repo)
  gert::git_branch_create("feature", repo = repo)
  gert::git_branch_checkout("feature", repo = repo)

  withr::with_dir(repo, {
    writeLines(c("base", "feature change"), "file.txt")
    gert::git_add("file.txt")
    gert::git_commit("Feature work")
  })

  diff_summary <- get_branch_differences(
    repo_path = repo,
    target_branch = "feature",
    source_branch = default_branch
  )

  expect_match(diff_summary, "Feature work")
  expect_match(diff_summary, "feature change")
})

test_that("get_branch_differences auto-detects active branch from data frame", {
  skip_if_not_installed("gert")
  skip_if_no_git()

  repo <- withr::local_tempdir()
  gert::git_init(repo)

  withr::with_dir(repo, {
    writeLines("base", "file.txt")
    gert::git_add("file.txt")
    gert::git_commit("Base commit")
  })

  default_branch <- withr::with_dir(repo, gert::git_branch())
  gert::git_branch_create("feature", repo = repo)
  gert::git_branch_checkout("feature", repo = repo)

  withr::with_dir(repo, {
    writeLines(c("base", "feature change"), "file.txt")
    gert::git_add("file.txt")
    gert::git_commit("Feature work")
  })

  branch_df <- data.frame(
    name = c(default_branch, "feature"),
    head = c(FALSE, TRUE),
    active = c(FALSE, TRUE),
    stringsAsFactors = FALSE
  )

  diff_summary <- testthat::with_mocked_bindings(
    get_branch_differences(
      repo_path = repo,
      target_branch = NULL,
      source_branch = default_branch
    ),
    git_branch = function(repo) branch_df,
    .package = "gert"
  )

  expect_match(diff_summary, "Feature work")
  expect_match(diff_summary, "feature change")
})

test_that("get_uncommitted_changes reports staged and unstaged", {
  skip_if_not_installed("gert")
  skip_if_no_git()

  repo <- withr::local_tempdir()
  gert::git_init(repo)

  withr::with_dir(repo, {
    writeLines("original", "file.txt")
    gert::git_add("file.txt")
    gert::git_commit("Initial")

    writeLines("modified", "file.txt")
  })

  unstaged <- get_uncommitted_changes(repo_path = repo)
  expect_match(unstaged, "modified")

  withr::with_dir(repo, {
    gert::git_add("file.txt")
  })

  staged <- get_uncommitted_changes(repo_path = repo, staged = TRUE)
  expect_match(staged, "modified")
})

test_that("get_uncommitted_changes handles unborn HEAD", {
  skip_if_not_installed("gert")
  skip_if_no_git()

  repo <- withr::local_tempdir()
  gert::git_init(repo)

  withr::with_dir(repo, {
    writeLines("line1", "file.txt")
    gert::git_add("file.txt")
    writeLines(c("line1", "line2"), "file.txt")
  })

  unstaged <- get_uncommitted_changes(repo_path = repo)
  expect_match(unstaged, "line2")
})
