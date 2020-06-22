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


server <- function(input, output, session) {
    
    #Creating a select button that updates degree options based on major choice
    observe({
        options <- pseo %>%
            group_by(label) %>% 
            filter(status_y1_earnings == "1", status_y5_earnings == "1", status_y10_earnings == "1", label == input$major) %>% 
            distinct(label_degree_level)
        options <- as.character(as_vector(options$label_degree_level))
        updateSelectInput(session = session, inputId = "degree", choices = options)
    })
    
    
    output$selected <- eventReactive(input$submit,{ 
        paste("You have selected: ", input$major)
    })
    
    #Getting the description of the program
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
        
        #making Type a factor so it plots in the correct order
        plot_data_long <- plot_data_long %>% 
            mutate(Type = factor(Type, levels = c("medy1", "medy5", "medy10"))) %>% 
            mutate(Amount = round(Amount, 0))
        
        plot1 <- ggplot(plot_data_long, mapping = aes(x = Type, y = Amount, fill = Type)) +
            geom_bar(stat = "identity", position = "dodge") +
            geom_text(aes(label = Amount), position = position_dodge(width = 0.9), vjust = -0.25) +
            theme(legend.position = "none") +
            scale_y_continuous(limit = c(0, 155000)) + scale_fill_brewer(palette = "Set2") +
            labs(title = str_c("Earnings Data for ", input$major), x = "Years after Graduation", y = "Average Median Earnings")
        
        output$salaries <- renderPlot({
            plot1
        })
    })
    
    
}

# Run the application 
shinyApp(ui = ui, server = server)
