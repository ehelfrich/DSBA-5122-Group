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
              box(title = "Parameters"),
              box(title = "Plot")
            )),
    tabItem(h1("Machine Learning"), tabName = "machinelearning",
            selectInput(inputId="machinelearning", label = "Select Machine Learning method: ", choices = machinelearning),
            actionButton(inputId = "machinelearningrerun", label = "Run"),
            fluidRow(
              box(title = "boxes showing test tickets with their labels/predicted label"),
              box(title = "Shows confusion matrix with precision/recall/f1 scores for each of the labels")
             
            )
            )
  )
  )
))