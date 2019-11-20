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
              box(title = "Data Frame"),
              box(title = "Summary Stats"),
              box(title = "Category Distribution")
            )),
    tabItem(h1("Feature Engineering"), tabName = "featengineering",
            checkboxInput(inputId="stopwords", label="Stop Words: ", value=TRUE),
            actionButton(inputId = "stopwordsrerun", label= "Run"),
            sliderInput(inputId = "minwords", label = "Specify minimum amount of words you want in a ticket: ", min = 4, max = 1000, step = 30, value = 100),
            actionButton(inputId = "minwordsrerun", label= "Run"),
            selectInput(inputId= "vectorizeframe", label = "Select vectorization method", choices = vectors),
            actionButton(inputId= "vectorframererun", label = "Run")
            ),
    tabItem(h1("Dimensionality Reduction"), tabName = "dimreduction",
            selectInput(inputId="dimmethod", label = "Select Dimensionality Method: ", choices = feature),
            fluidRow(
              box(title = "Show Data undergoing Dimensionality Reduction"),
              box(title = "Show data on an interactive graph"),
              box(title = "Show bars of the categories on the side of the data (x,y")
            )  ),
    tabItem(h1("Machine Learning"), tabName = "machinelearning",
            selectInput(inputId="machinelearning", label = "Select Machine Learning method: ", choices = machinelearning),
            actionButton(inputId = "machinelearningrerun", label = "Run"),
            fluidRow(
              box(title = "boxes showing test tickets with their labels/predicted label"),
              box(title = "Show confusion matrix with precision/recall/f1 scores for each of the labels")
             
            )
            )
  ),
  )
))