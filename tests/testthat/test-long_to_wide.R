test_that("fmcom dataset has expected structure", {
  skip_if_not(exists("fmcom"), "fmcom dataset not yet built")
  expect_s3_class(fmcom, "data.frame")
  expect_true("water_type" %in% names(fmcom))
  expect_true(all(as.character(fmcom$water_type) %in% c("Marine", "Freshwater")))
  expect_true(!anyNA(fmcom$sample_ID))
})

test_that("fmcom_long_to_wide errors informatively on bad columns", {
  d <- data.frame(a = 1, substance = "x", value = 1)
  expect_error(
    fmcom_long_to_wide(d, id_cols = c("station")),
    "not found in"
  )
})
