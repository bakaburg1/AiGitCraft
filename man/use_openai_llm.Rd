% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/LLM_calls.R
\name{use_openai_llm}
\alias{use_openai_llm}
\title{Use OpenAI Language Model}
\usage{
use_openai_llm(
  body,
  model = getOption("aigitcraft_openai_model_gpt"),
  api_key = getOption("aigitcraft_openai_api_key")
)
}
\arguments{
\item{body}{The body of the request.}

\item{model}{Model identifier for the OpenAI API. Obtained from R options.}

\item{api_key}{API key for the OpenAI service. Obtained from R options.}
}
\value{
The function returns the response from the OpenAI API.
}
\description{
Sends a request to the OpenAI API  using the parameters in the \code{body}
argument. It requires an API key and model identifier set in the R options.
}
