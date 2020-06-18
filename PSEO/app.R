#
# This is a Shiny web application. You can run the application by clicking
# the 'Run App' button above.
#
# Find out more about building applications with Shiny here:
#
#    http://shiny.rstudio.com/
#

library(shiny)

# Define UI for application that draws a histogram
ui <- fluidPage(
    navbarPage(title = "PSEO Data", 
               tabPanel("Field Explorer", 
                        sidebarLayout(
                            sidebarPanel(
                                helpText("Select your field for more information"),
                                
                                selectInput("major",
                                            "Select field:",
                                            choices = pseo$label)
                            ),
                            
                            # Show a plot of the generated distribution
                            mainPanel(
                                textOutput("selected"),
                                textOutput("info"),
                                
                            )
                        )),
               tabPanel("Major Comparision", "contents"), 
               tabPanel("Info", "contents"))
    
)

# Define server logic required to draw a histogram
server <- function(input, output) {
    output$selected <- reactive({ 
        paste("You have selected", input$major)
    })
    
    output$info <- reactive({ 
        def <- pseo[(pseo$label == input$major), "CIPDefinition"]
        def <- as.character(as.vector(def[1,]))
        return(str_c("Description of program: ", def))
    })
}

# Run the application 
shinyApp(ui = ui, server = server)
