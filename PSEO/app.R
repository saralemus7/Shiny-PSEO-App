library(tidyverse)
library(shiny)
library(shinyalert)
library(shinythemes)

ui <- fluidPage(
    theme = shinytheme("simplex"),
    navbarPage(title = "PSEO Data", 
               tabPanel("Field Explorer", 
                        sidebarLayout(
                            sidebarPanel(
                                helpText("Select your field and press
                                         submit for more information"),
                                
                                selectInput("major",
                                            "Select field:",
                                            choices = pseo$label),
                                selectInput("degree",
                                            "Degree level:",
                                            choices = pseo$label_degree_level),
                                hr(),
                                actionButton("submit",
                                             "Submit")
                            ),
                            
                            # Show a plot of the generated distribution
                            mainPanel(
                                textOutput("selected"),
                                textOutput("info"),
                                plotOutput("salaries")
                            )
                        )),
               tabPanel("Info",
                        h1("About the data:"),
                        "This app is based off of data from the US Census Bureau
                        study known as Post-Secondary Employment Outcomes (PSEO)."))
    
)


server <- function(input, output) {
    
    observe({
        updateSelectInput(session, "degree", choices = as.character(pseo[pseo$label==input$major, label_degree_level]))
    })
    
    observeEvent(input$submit, {
        if(nrow(
            pseo %>% 
            filter(label == input$major, label_degree_level == input$degree)) == 0){
            shinyalert(title = "error",
                       text = "data does not exist",
                       type = "error")
        }
    })
    
    output$selected <- eventReactive(input$submit,{ 
        paste("You have selected: ", input$major)
    })
    
    output$info <- eventReactive(input$submit, { 
        def <- pseo[(pseo$label == input$major), "CIPDefinition"]
        def <- as.character(as.vector(def[1,]))
        paste("<br>", "Description of program: ", def)
    })
    
    observeEvent(input$submit,{
        plot_data <- pseo %>% 
            group_by(label) %>% 
            filter(status_y1_earnings == "1", status_y5_earnings == "1", status_y10_earnings == "1", 
                   label_degree_level == input$degree, label == input$major) %>% 
            summarise(medy1 =  mean(as.numeric(y1_p50_earnings)),
                      medy5 =  mean(as.numeric(y5_p50_earnings)),
                      medy10 =  mean(as.numeric(y10_p50_earnings))) 
        plot_data_long <- plot_data %>% 
            pivot_longer(cols = c(medy1, medy5, medy10), names_to = "Type", values_to = "Amount")
        plot1 <- ggplot(plot_data_long, mapping = aes(x = Type, y = Amount, fill = Type)) +
            geom_bar(stat = "identity") +
            scale_y_continuous(limit = c(0, 120000)) + scale_fill_brewer(palette = "Set2") +
            labs(title = input$major)
        output$salaries <- renderPlot({
            plot1
        })
    })
    
    
}

# Run the application 
shinyApp(ui = ui, server = server)
