#
# This is the user-interface definition of a Shiny web application. You can
# run the application by clicking 'Run App' above.
#
# Find out more about building applications with Shiny here:
#
#    http://shiny.rstudio.com/
#

library(shiny)
source("rshiny-tabs.R")

# Define UI for application that draws a histogram
shinyUI(fluidPage(
  #Define Navbar
  navbarPage(
    "Ticket Classification",
    # Sample Tab
    sample_tab(),
    # Tab to define the problem
    tabPanel("Problem"),
    # Show Raw Data
    tabPanel("Raw Data"),
    # Show Data Transformation
    tabPanel("Data Transformation"),
    # Show Feature Engineering
    tabPanel("Feature Engineering"),
    #Interactive ML solutions and their results
    tabPanel("ML Solutions")
  )

))
