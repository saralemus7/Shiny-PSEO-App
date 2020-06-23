library(tidyverse)
library(shiny)
library(shinyalert)
library(shinythemes)
library(DT)
library(htmltools)

ui <- fluidPage(
    theme = shinytheme("simplex"),
    navbarPage(title = "PSEO Colorado Data", 
               #main panel
               tabPanel("Field Explorer", 
                        sidebarLayout(
                            sidebarPanel(
                                helpText("Select your field and press
                                         submit for more information"),
                                
                                selectInput("major",
                                            "Select field:",
                                            choices = pseo$label,
                                            selected = NULL),
                                selectInput("degree",
                                            "Degree level:",
                                            choices = pseo$label_degree_level),
                                checkboxInput("multiple", 
                                              "Compare additional fields within the same degree level",
                                              value = FALSE),
                                conditionalPanel(condition = "input.multiple",
                                            selectInput("major2",
                                            "Select up to 3 additional choices",
                                            choices = pseo$label,
                                            multiple = TRUE)),
                                hr(),
                                actionButton("submit",
                                             "Submit")
                            ),
                            

                            mainPanel(
                                htmlOutput("selected"),
                                htmlOutput("info"),
                                plotOutput("salaries")
                            )
                        )),
               
               #info panel
               tabPanel("Info",
                        h2("About the data:"),
                        "This app is based off of data from the US Census Bureau
                        study known as Post-Secondary Employment Outcomes (PSEO).",
                        checkboxInput("table", 
                                      "View Data",
                                      value = FALSE),
                        conditionalPanel(condition = "input.table",
                                         dataTableOutput("table"))
                        ))
    
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
    
    #Creating a select button that updates comparision options based on degree level choice
    observe({
        major_options <- pseo %>%
            group_by(label) %>% 
            filter(status_y1_earnings == "1", status_y5_earnings == "1", status_y10_earnings == "1", label_degree_level == input$degree) %>% 
            distinct(label) 
        major_options <- as.character(as_vector(major_options$label))
        #Remove the already selected major as an option
        major_options <- major_options[!major_options %in% input$major]
        updateSelectInput(session = session, inputId = "major2", choices = major_options)
    })
    
    #Displaying the major
    selected_text <- eventReactive(input$submit,{ 
        HTML(paste("<b>","You have selected: ","</b>", input$major, "<br>"))
    })
    output$selected <- renderUI({selected_text()})
    
    #Displaying the description of the program
    description_text <- eventReactive(input$submit, { 
        def <- pseo[(pseo$label == input$major), "CIPDefinition"]
        def <- as.character(as.vector(def[1,]))
        HTML(paste("<b>", "Description of program: ", "</b>", def))
    })
    output$info <- renderUI({description_text()})
    
    observeEvent(input$submit,{
        
        #Creating a string of the selected majors for the plot
        majors <- c(input$major, input$major2)
        majors <- paste(majors, collapse = "|")
        
        #caclulating the medians + making the df long
        plot_data <- pseo %>% 
            group_by(label) %>% 
            filter(status_y1_earnings == "1", status_y5_earnings == "1", status_y10_earnings == "1", 
                   label_degree_level == input$degree, str_detect(label, majors)) %>% 
            summarise(year1 =  mean(as.numeric(y1_p50_earnings)),
                      year5 =  mean(as.numeric(y5_p50_earnings)),
                      year10 =  mean(as.numeric(y10_p50_earnings))) 
        
        plot_data_long <- plot_data %>% 
            pivot_longer(cols = c(year1, year5, year10), names_to = "Type", values_to = "Amount")
        
        #fomatting Type for the plot
        plot_data_long <- plot_data_long %>% 
            mutate(Type = factor(Type, levels = c("year1", "year5", "year10"))) 
        
        plot1 <- ggplot(plot_data_long, mapping = aes(x = Type, y = Amount, fill = label)) +
            geom_bar(stat = "identity", position = "dodge") +
            geom_text(aes(label = str_c("$", format(round(as.numeric(Amount), 0), big.mark = ","))), position = position_dodge(width = 0.9), vjust = -0.25) +
            theme_light(base_size = 15) +
            scale_y_continuous(limit = c(0, 155000)) + scale_fill_brewer(palette = "Set2") +
            labs(title = "Average Median Earnings", subtitle = "1, 5, and 10 Years Post-Graduation", x = "Years After Graduation", y = "Average Median Earnings", fill = "Major")
        
        output$salaries <- renderPlot({
            plot1
        })
    })
    
    #DataTable for Info Tab
    output$table <- renderDataTable({
        pseo %>% 
            filter(status_y1_earnings == "1", status_y5_earnings == "1", status_y10_earnings == "1") %>%
            select(label_cipcode,label, label_grad_cohort, label_institution, label_degree_level, y1_p50_earnings, y5_p50_earnings, y10_p50_earnings) 
    })
    
    
}

# Run the application 
shinyApp(ui = ui, server = server)
