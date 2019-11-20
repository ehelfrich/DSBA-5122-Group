## app.R ##
library(shiny)
library(shinydashboard)

ui <- dashboardPage(
  dashboardHeader(
    title = "Tickets"
  ),
  dashboardSidebar(
    sidebarMenu(
      menuItem("Business Case", tabName = "businesscase", icon = icon("dashboard")),
      menuItem("Data Exploration", tabName = "dataexploration", icon = icon("th")),
      menuItem("Feature Engineering", tabName = "featengineering", icon = icon("th")),
      menuItem("Dimensionality Reduction", tabName = "dimreduction", icon = icon("th")),
      menuItem("Machine Learning", tabName = "machinelearning", icon = icon("th"))
    )
  ),
  dashboardBody(
    tabItem(tabName = "businesscase"),
    tabItem(tabName = "dataexploration"),
    tabItem(tabName = "featengineering"),
    tabItem(tabName = "dimreduction"),
    tabItem(tabName = "machinelearning")
  )
)

server <- function(input, output) { }

shinyApp(ui, server)
