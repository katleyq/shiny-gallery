library(shiny)
library(htmltools)

# ---------------------------------------------------------------------------
# Configuration — override with environment variables on the server
# ---------------------------------------------------------------------------
SHINY_BASE_DIR <- Sys.getenv("SHINY_BASE_DIR", "/srv/shiny-server")
SHINY_BASE_URL <- Sys.getenv("SHINY_BASE_URL", "/")        # e.g. "/" or "/shiny/"
GALLERY_NAME   <- basename(normalizePath("."))              # exclude self

# ---------------------------------------------------------------------------
# Helper: read optional app-info.yml from an app directory
# ---------------------------------------------------------------------------
`%||%` <- function(a, b) if (!is.null(a) && length(a) > 0 && !is.na(a)) a else b

read_app_info <- function(dir) {
  name <- basename(dir)
  title <- tools::toTitleCase(gsub("[-_]", " ", name))

  info_file <- file.path(dir, "app-info.yml")
  if (file.exists(info_file) && requireNamespace("yaml", quietly = TRUE)) {
    info <- tryCatch(yaml::read_yaml(info_file), error = function(e) list())
    list(
      name        = name,
      title       = info$title       %||% title,
      description = info$description %||% "",
      icon        = info$icon        %||% "chart-bar",
      tags        = info$tags        %||% character(0),
      url         = paste0(SHINY_BASE_URL, name, "/")
    )
  } else {
    list(
      name        = name,
      title       = title,
      description = "",
      icon        = "chart-bar",
      tags        = character(0),
      url         = paste0(SHINY_BASE_URL, name, "/")
    )
  }
}

# ---------------------------------------------------------------------------
# Discover Shiny apps: subdirs that contain app.R or server.R
# ---------------------------------------------------------------------------
get_apps <- function() {
  if (!dir.exists(SHINY_BASE_DIR)) return(list())

  dirs <- list.dirs(SHINY_BASE_DIR, recursive = FALSE, full.names = TRUE)

  is_shiny_app <- function(d) {
    basename(d) != GALLERY_NAME &&
      (file.exists(file.path(d, "app.R")) || file.exists(file.path(d, "server.R")))
  }

  app_dirs <- Filter(is_shiny_app, dirs)
  lapply(app_dirs, read_app_info)
}

# ---------------------------------------------------------------------------
# Build a single app card
# ---------------------------------------------------------------------------
make_card <- function(app) {
  tag_els <- if (length(app$tags) > 0)
    tags$div(class = "card-tags",
      lapply(app$tags, function(t) tags$span(class = "tag", t))
    )
  else NULL

  desc_el <- if (nchar(app$description) > 0)
    tags$p(class = "card-description", app$description)
  else NULL

  tags$div(
    class = "app-card",
    tags$div(
      class = "card-icon",
      tags$i(class = paste0("fas fa-", app$icon))
    ),
    tags$div(
      class = "card-body",
      tags$h3(class = "card-title", app$title),
      desc_el,
      tag_els,
      tags$a(
        href = app$url,
        class = "card-link",
        target = "_blank",
        rel = "noopener",
        "Launch App ",
        tags$i(class = "fas fa-arrow-up-right-from-square")
      )
    )
  )
}

# ---------------------------------------------------------------------------
# UI
# ---------------------------------------------------------------------------
ui <- fluidPage(
  tags$head(
    tags$meta(charset = "UTF-8"),
    tags$meta(name = "viewport", content = "width=device-width, initial-scale=1"),
    tags$title("Shiny App Gallery"),
    tags$link(
      rel = "stylesheet",
      href = paste0(
        "https://fonts.googleapis.com/css2?",
        "family=Nunito:wght@300;800&family=Sanchez&family=Roboto+Mono:wght@300;400",
        "&display=swap"
      )
    ),
    tags$link(
      rel = "stylesheet",
      href = "https://cdnjs.cloudflare.com/ajax/libs/font-awesome/6.5.0/css/all.min.css",
      integrity = "sha512-Avb2QiuDEEvB4bZJYdft2mNjVShBftLdPG8FJ0V7irTLQ8Uo0qcPxh4Plq7G5tGm0rU+1SPhVotteLpBERwTkw==",
      crossorigin = "anonymous"
    ),
    tags$link(rel = "stylesheet", href = "styles.css")
  ),

  # Header
  tags$header(
    class = "site-header",
    tags$div(
      class = "header-content",
      tags$h1("Shiny App Gallery"),
      tags$p(class = "header-subtitle", "Interactive data applications")
    )
  ),

  # Main
  tags$main(
    class = "main-content",
    tags$div(
      class = "gallery-header",
      tags$h2("Applications"),
      uiOutput("app_count")
    ),
    uiOutput("gallery")
  ),

  # Footer
  tags$footer(
    class = "site-footer",
    tags$p(
      "Built with ",
      tags$a(href = "https://shiny.posit.co", target = "_blank", "R Shiny")
    )
  )
)

# ---------------------------------------------------------------------------
# Server
# ---------------------------------------------------------------------------
server <- function(input, output, session) {

  # Re-scan every 60 seconds so new apps appear without restarting
  apps <- reactive({
    invalidateLater(60000, session)
    get_apps()
  })

  output$app_count <- renderUI({
    n <- length(apps())
    tags$p(class = "app-count",
      sprintf("%d app%s available", n, if (n != 1) "s" else "")
    )
  })

  output$gallery <- renderUI({
    app_list <- apps()
    if (length(app_list) == 0) {
      tags$div(
        class = "empty-state",
        tags$i(class = "fas fa-cubes-stacked empty-icon"),
        tags$p("No apps found. Add a Shiny app to ", tags$code(SHINY_BASE_DIR), " to get started.")
      )
    } else {
      tags$div(
        class = "app-grid",
        lapply(app_list, make_card)
      )
    }
  })
}

shinyApp(ui, server)
