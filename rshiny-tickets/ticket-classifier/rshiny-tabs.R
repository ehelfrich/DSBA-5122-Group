### Collection of functions to define each tab on the UI ###

# Sample Tab  
sample_tab <- function() {
  tabPanel(
    "Sample Component",
  titlePanel("Old Faithful Geyser Data"),
  
  # Sidebar with a slider input for number of bins
  sidebarLayout(sidebarPanel(
    sliderInput(
      "bins",
      "Number of bins:",
      min = 1,
      max = 50,
      value = 30
    )
  ),
  
  # Show a plot of the generated distribution
  mainPanel(plotOutput("distPlot")))
  )
}

# Raw Data Visulization Tab
rawDataVis <- function() {
  
}