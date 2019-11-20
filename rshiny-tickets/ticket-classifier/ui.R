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
    tabItem(tabName = "businesscase"),
    tabItem(tabName = "dataexploration"),
    tabItem(tabName = "featengineering"),
    tabItem(tabName = "dimreduction"),
    tabItem(tabName = "machinelearning")
  )
))