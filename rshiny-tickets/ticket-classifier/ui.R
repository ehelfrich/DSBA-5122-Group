library(shinydashboard)
vectors <- list("TF-IDF", "Count Vectorizer")
feature <- list("UMAP", "TSNE")
machinelearning <- list("Logistic Regression", "Random Forest")

shinyUI(dashboardPage(
  dashboardHeader(
    title = "Ticket Classifier"
  ),
  dashboardSidebar(
    sidebarMenu(
      menuItem("Business Case", tabName = "businesscase", icon = icon("dashboard")),
      menuItem("Data Exploration", tabName = "dataexploration", icon = icon("search")),
      menuItem("Feature Engineering", tabName = "featengineering", icon = icon("cogs")),
      menuItem("Dimensionality Reduction", tabName = "dimreduction", icon = icon("coins")),
      menuItem("Machine Learning", tabName = "machinelearning", icon = icon("brain"))
    )
  ),
  dashboardBody(
    tabItems(
      tabItem(h1("Business Case"), tabName = "businesscase", paste0("The business problem is that")),
      tabItem(h1("Data Exploration"), tabName = "dataexploration",
              fluidRow(
                box(title = "Generate Data Set", actionButton("data_generate", "Generate")),
                box(title = "Data Frame", dataTableOutput('df')),
                box(title = "Summary Stats", tableOutput('token_summary')),
                box(title = "Category Distribution", plotOutput('category_dist'))
              )),
      tabItem(h1("Feature Engineering"), tabName = "featengineering",
              fluidPage(
                box(title = "Parameters",
                    checkboxInput(inputId="stopwords", label="Stop Words: ", value=TRUE),
                    sliderInput(inputId = "minwords", label = "Specify minimum amount of words you want in a ticket: ", min = 1, max = 500, step = 10, value = 50),
                    selectInput(inputId= "vectorizeframe", label = "Select vectorization method", choices = vectors),
                    actionButton(inputId= "FE_run", label = "Run")
                ),
                box(title = "Word Cloud", plotOutput('fe_cloud')),
                box(title = "Word Counts", height = 600, plotOutput('fe_hist'))
              )),
      tabItem(h1("Dimensionality Reduction"), tabName = "dimreduction",
              selectInput(inputId="dimmethod", label = "Select Dimensionality Method: ", choices = feature),
              fluidRow(
                box(title = "Parameters",
                    strong("UMAP"),
                    sliderInput(inputId = "umap__n_neighbors", label = "nearest neighbors", min = 2, max = 50, step = 1, value = 15),
                    sliderInput(inputId = "umap__min_dist", label = "Minimum Distance", min = 0.0, max = .99, step = .1, value = .25),
                    br(),
                    strong("PCA/T-SNE"),
                    sliderInput(inputId = "pca__n_dims", label = "Number of PCA Dimensions", min = 2, max = 200, step = 2, value = 50),
                    sliderInput(inputId = "pca__perplexity", label = "Perplexity", min = 10, max = 100, step = 5, value = 50),
                    br(),
                    actionButton(inputId="umap_run", label = "Run")
                ),
                box(title = "Plot", plotOutput("dim_plot"))
              )),
      tabItem(h1("Machine Learning"), tabName = "machinelearning",
              fluidRow(
                box(title = "Random Forest Hyperparameters",
                    sliderInput(inputId = "rf__num_trees", label = "Number of Trees", min = 1, max = 50, step = 1, value = 10),
                    actionButton(inputId = "rf_run", label = "Run")
                ),
                box(title = "Model Metrics", textOutput("metrics")),
                box(title = "Confustion Matrix")
                
              )
      )
    )
  )
))