library(shinydashboard)
library(shinythemes)
library(devtools)
library(htmlwidgets)
library(waiter)
vectors <- list("TF-IDF", "Count Vectorizer")
feature <- list("UMAP", "TSNE")
machinelearning <- list("Logistic Regression", "Random Forest")

shinyUI(dashboardPage(
  skin = "yellow",
  dashboardHeader(title = "Ticket Classifier"),
  dashboardSidebar(
    sidebarMenu(
      menuItem(
        "Business Case",
        tabName = "businesscase",
        icon = icon("dashboard")
      ),
      menuItem(
        "Data Exploration",
        tabName = "dataexploration",
        icon = icon("search")
      ),
      menuItem(
        "Feature Engineering",
        tabName = "featengineering",
        icon = icon("cogs")
      ),
      menuItem(
        "Dimensionality Reduction",
        tabName = "dimreduction",
        icon = icon("coins")
      ),
      menuItem(
        "Machine Learning",
        tabName = "machinelearning",
        icon = icon("brain")
      ),
      menuItem("Contact", tabName = "contact", icon = icon("id-card"))
    )
  ),
  dashboardBody(
    tabItems(
      tabItem(
        h1("Business Case"),
        tabName = "businesscase",
        fluidRow(
          box(h2("Domain Problem"),
              p("Our domain problem is one for agents who handle service tickets to quickly and efficiently classify the problem and resolve the ticket.
                In a system without an automated classification system, agents would have to assign categories dependent on many variables,
                such as content and priority, and who to send tickets to. Many times, tickets can be classified incorrectly, which could be caused on accident,
                faulty information, or when the end user gives up trying to classify the ticket. Once this agent misclassifies the ticket,
                it is sent on to the next service desk, incorrectly, to fix and therefore wasting precious time for the next handler of the ticket.
                At a larger company, this happens multiple times a day."),
              h2("Purpose of the App"),
              p("This application was created to showcase the concept of a model, using a data science team approach,
                to demonstrate machine learning pipeline operations for a decision-making audience.
                The result will allow decision makers to determine if the feature engineering steps and model results are a worth-while investment
                to “productionize” the pipeline."),
              hr(),
              h2("App Contents"),
              h3("Data Exploration"),
              p("The Data Exploration tab allows the user to generate a training dataset.  
                The testing set is generated at application start and remains static throughout the entire session.  
                The tab shows a data table of generated training set, summary metrics of the test/train datasets, 
                and the distribution of categories for the training set.  "),
              h3("Feature Engineering"),
              p("The Feature Engineering tab gives the user the ability to apply different transformations to the dataset and then visualize
                how it affects the words in the dataset.  The word counts histogram and the word cloud allow the user to visualize how the stopwords/minimum words
                in a ticket affect the most common words."),
              h3("Dimensionality Reduction"),
              p("The Dimensionality Reduction tab allows the user to reduce the huge number of dimensions in the dataset down to 2 dimensions. 
                These reduced dimensions can then be viewed in a 2-d plot that can be visualized by humans. 
                This will help users visualize possible clusters of tickets in the data set and possibly see patterns between tickets."),
              h3("Machine Learning"),
              p("The Machine Learning tab allows the user to create a random forest classification model to predict the ticket category based on the body of the ticket. 
                It then shows  the model metrics and the confusion matrix after the model as been used to predict the test set’s categories."))
          )
      ),
      #### Data Exploration Tab ####
      tabItem(h1("Data Exploration"), tabName = "dataexploration",
              fluidRow(
                column(width = 6,
                  actionButton("data_generate", "Generate Training Data Set"),
                  box(
                    title = "Training Data",
                    DT::dataTableOutput('df'),
                    collapsible = T,
                    width = NULL
                  )
                ),
                column(width = 6,
                  downloadButton("data.csv", "Download Cleaned Master Data Set"),
                  fluidRow(
                    infoBoxOutput("training_size"),
                    infoBoxOutput("training_avg_count"),
                    infoBoxOutput("training_median_count")
                  ),
                  fluidRow(
                    infoBoxOutput("test_size"),
                    infoBoxOutput("test_avg_count"),
                    infoBoxOutput("test_median_count")
                  ),
                  box(
                    title = "Training Data Category Distribution",
                    plotOutput('category_dist'),
                    width = NULL
                  )
                )
              )),
      #### Feature Engineering Tab ####
      tabItem(h1("Feature Engineering"), tabName = "featengineering",
              fluidRow(
                box(
                  title = "Parameters",
                  height = 525,
                  checkboxInput(
                    inputId = "stopwords",
                    label = "Stop Words: ",
                    value = TRUE
                  ),
                  sliderInput(
                    inputId = "minwords",
                    label = "Specify minimum amount of words you want in a ticket: ",
                    min = 0,
                    max = 50,
                    step = 1,
                    value = 10
                  ),
                  sliderInput(
                    inputId = "m_words",
                    label = "Minimum words for Counts Chart:",
                    min = 300,
                    max = 600,
                    value = 500
                  ),
                  sliderInput(
                    inputId = "sizewords",
                    label = "Word size for Counts Chart:",
                    min = 8,
                    max = 30,
                    value = 14
                  ),
                  selectInput(
                    inputId = "vectorizeframe",
                    label = "Select vectorization method",
                    choices = vectors
                  ),
                  use_waiter(),
                  actionButton(inputId = "FE_run", label = "Run")
                ),
                box(
                  width = 6,
                  title = "Word Counts",
                  height = 500,
                  plotOutput('fe_hist')
                ),
                box(
                  title = "Word Cloud"
                  ,
                  status = "primary",
                  solidHeader = F
                  ,
                  collapsible = T,
                  width = 12
                  ,
                  column(12, align = "center" , plotOutput('fe_cloud'))
                )
              )),
      #### Dimensionality Reduction Tab ####
      tabItem(
        h1("Dimensionality Reduction"),
        tabName = "dimreduction",
        selectInput(
          inputId = "dimmethod",
          label = "Select Dimensionality Method: ",
          choices = feature
        ),
        fluidRow(
          box(
            title = "Parameters",
            width = 4,
            conditionalPanel("input.dimmethod == 'UMAP'",
                             strong("UMAP"),
                             sliderInput(inputId = "umap__n_neighbors", 
                                         label = "nearest neighbors", 
                                         min = 2, max = 50, step = 1, value = 15),
                             sliderInput(inputId = "umap__min_dist", 
                                         label = "Minimum Distance", 
                                         min = 0.0, max = .99, step = .1, value = .25)
            ),
            conditionalPanel("input.dimmethod == 'TSNE'",
                             strong("PCA/T-SNE"),
                             sliderInput(
                               inputId = "pca__n_dims",
                               label = "Number of PCA Dimensions",
                               min = 2, max = 200, step = 2, value = 50
                             ),
                             sliderInput(
                               inputId = "pca__perplexity",
                               label = "Perplexity",
                               min = 10, max = 100, step = 5, value = 50
                             )
            ),
            actionButton(inputId = "umap_run", label = "Run"),
            height = 600
          ),
          box(
            title = "Plot",
            plotOutput(
              "dim_plot",
              brush = brushOpts(id = "dim_plot_brush")
            ),
            plotOutput("bars", height = 200)
          )
        )
      ),
      tabItem(
        h1("Machine Learning"),
        tabName = "machinelearning",
        fluidRow(
          box(
            title = "Model Parameters",
            sliderInput(
              inputId = "rf__num_trees",
              label = "Random Forest - Choose Number of Trees",
              min = 1,
              max = 50,
              step = 1,
              value = 2
            ),
            actionButton(inputId = "rf_run", label = "Run")
          ),
          box(
            title = "Download Model",
            downloadButton(outputId = "savedmodel.rds", label = "Download Best Model")
          )
        ),
        fluidRow(
          box(title = "Random Forest Metrics", verbatimTextOutput("cm")),
          box(
            title = "Plot",
            plotOutput("ml_plot"),
            column = 6,
            align = "left",
            height = 500
          )
        )
      ),
      tabItem(h1("Contact"), tabName = "contact",
              fluidRow(
                HTML(
                  "Group Members: Eric Helfrich, Karan Edikala, Derek Stranton <br>
                  Emails: ehelfri1@uncc.edu, kedikala@uncc.edu, dstranto@uncc.edu <br>
                  Git Hub: https://github.com/ehelfrich/DSBA-5122-Group <br>
                  Final Report: https://github.com/ehelfrich/DSBA-5122-Group/blob/master/rshiny-tickets/ticket_report.html"
                )
                ))
                )
                )
              ))