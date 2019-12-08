library(shinydashboard)
library(shinythemes)
library(devtools)
library(htmlwidgets)
library(waiter)
vectors <- list("TF-IDF", "Count Vectorizer")
feature <- list("UMAP", "TSNE")
machinelearning <- list("Logistic Regression", "Random Forest")

shinyUI(
  dashboardPage(skin = "yellow",
                dashboardHeader(
                  title = "Ticket Classifier"
                ),
                dashboardSidebar(
                  sidebarMenu(
                    menuItem("Business Case", tabName = "businesscase", icon = icon("dashboard")),
                    menuItem("Data Exploration", tabName = "dataexploration", icon = icon("search")),
                    menuItem("Feature Engineering", tabName = "featengineering", icon = icon("cogs")),
                    menuItem("Dimensionality Reduction", tabName = "dimreduction", icon = icon("coins")),
                    menuItem("Machine Learning", tabName = "machinelearning", icon = icon("brain")),
                    menuItem("Contact", tabName = "contact", icon = icon("id-card"))
                  )
                ),
                dashboardBody(
                  tabItems(
                    tabItem(h1("Business Case"), tabName = "businesscase", paste0("We explored typical customer ticket classification data in an effort to grasp customer word usage and ticket results. Our domain problem is one for agents who handle service tickets to quickly and efficiently classify the problem and resolve the ticket.")),
                    tabItem(h1("Data Exploration"), tabName = "dataexploration",
                            fluidRow(
                              column(2, actionButton("data_generate", "Generate Data Set")
                              )),
                            fluidRow(
                              box(width = 6, title = "Data Frame", DT::dataTableOutput('df'), collapsible = T),
                              box(width = 6, title = "Summary Stats", tableOutput('token_summary')),
                              box(width = 6, title = "Category Distribution", plotOutput('category_dist'))
                            )),
                    tabItem(h1("Feature Engineering"), tabName = "featengineering",
                            fluidRow(
                              box(title = "Parameters", height = 525,
                                  checkboxInput(inputId="stopwords", label="Stop Words: ", value=TRUE),
                                  sliderInput(inputId = "minwords", label = "Specify minimum amount of words you want in a ticket: ", min = 0, max = 50, step = 1, value = 10),
                                  sliderInput(inputId="m_words", label="Minimum words for Counts Chart:", min = 300, max = 600, value = 500),
                                  sliderInput(inputId="sizewords", label = "Word size for Counts Chart:", min = 8, max = 30, value = 14),
                                  selectInput(inputId= "vectorizeframe", label = "Select vectorization method", choices = vectors),
                                  use_waiter(),
                                  actionButton(inputId= "FE_run", label = "Run")
                              ),
                              box(width = 6,title = "Word Counts", height = 500, plotOutput('fe_hist')),
                              box(title = "Word Cloud"
                                  , status = "primary", solidHeader = F
                                  , collapsible = T, width = 12
                                  , column( 12,align="center" , plotOutput('fe_cloud')))
                            )),
                    tabItem(h1("Dimensionality Reduction"), tabName = "dimreduction",
                            selectInput(inputId="dimmethod", label = "Select Dimensionality Method: ", choices = feature),
                            fluidRow(
                              box(title = "Parameters", width = 4, 
                                  strong("UMAP"),
                                  sliderInput(inputId = "umap__n_neighbors", label = "nearest neighbors", min = 2, max = 50, step = 1, value = 15),
                                  sliderInput(inputId = "umap__min_dist", label = "Minimum Distance", min = 0.0, max = .99, step = .1, value = .25),
                                  br(),
                                  strong("PCA/T-SNE"),
                                  sliderInput(inputId = "pca__n_dims", label = "Number of PCA Dimensions", min = 2, max = 200, step = 2, value = 50),
                                  sliderInput(inputId = "pca__perplexity", label = "Perplexity", min = 10, max = 100, step = 5, value = 50),
                                  br(),
                                  actionButton(inputId="umap_run", label = "Run"),
                                  height = 600
                              ),
                              box(title = "Plot", plotOutput("dim_plot", brush = brushOpts(id = "dim_plot_brush"), height = 500),
                                  plotOutput("bars", height = 100),
                                  height = 700, width = 8)
                            )),
                    tabItem(h1("Machine Learning"), tabName = "machinelearning",
                            fluidRow(
                              box(title = "Model Parameters",  
                                  sliderInput(inputId = "rf__num_trees", label = "Random Forest - Choose Number of Trees", min = 1, max = 50, step = 1, value = 2),
                                  actionButton(inputId = "rf_run", label = "Run")
                              ),
                              box(title = "Download Model",
                                  downloadButton(outputId = "savedmodel.rds", label = "Download Best Model"))
                            ),
                            fluidRow(   
                              box(title = "Random Forest Metrics", verbatimTextOutput("cm")),
                              box(title = "Plot", plotOutput("ml_plot"), column = 6, align = "left", height = 500)
                            )),
                    tabItem(h1("Contact"), tabName = "contact",
                            HTML(
                              "Group Members: Eric Helfrich, Karan Edikala, Derek Stranton <br>
                              Emails: ehelfri1@uncc.edu, kedikala@uncc.edu, dstranto@uncc.edu <br>
                              Git Hub: https://github.com/ehelfrich/DSBA-5122-Group"
                            )
                    )
                    
                  )
                )
    )
  )