library(tidyverse)
library(shiny)
library(shinyalert)
library(shinythemes)
library(DT)
library(htmltools)

pseo <- readRDS("data/pseo.rds")

ui <- fluidPage(
    theme = shinytheme("simplex"),
    useShinyalert(),
    navbarPage(title = "PSEO Colorado Data", 
               #main section
               tabPanel("Field Explorer", 
                        sidebarLayout(
                            sidebarPanel(
                                helpText("Select your field(s) and press
                                         submit for more information"),
                                
                                selectInput("major",
                                            "Select field:",
                                            choices = pseo$label),
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
                                br(),
                                br(),
                                plotOutput("salaries"),
                                br(),
                                htmlOutput("userHelp")
                            )
                        )),
               
               #info section
               tabPanel("Info",
                        h5("About the data:"),
                        "This app is based off of data from the US Census Bureau study known as Post-Secondary Employment Outcomes (PSEO). 
                        The data set used for this app in particular contains information on graduates from post-secondary institutions located in the state of Colorado. 
                        This includes information about their major, graduation cohort, industry, degree level, and quartile earnings 1,5, and 10 years after graduation. 
                        Please check the “View data” option if you would like to further explore the data. 
                        The original dataset has been filtered for use of this app because for many observations, earnings data is not available for all years. 
                        According to the Census Bureau, this is mainly because of “insufficient labor market attachment in the reference year.” 
                        The Census Bureau combined transcript data given by different schools in Colorado with their national database containing information 
                        about jobs to create a really interesting and informative dataset about college students and their future employment tracks.", br(),
                        a(href="https://lehd.ces.census.gov/data/pseo_experimental.html", "Census Bureau PSEO Information Page"), br(),
                        br(), br(), h5("About the app:"),
                        "The purpose of this app is to allow you to pick a field which is of interest and explore how average median earnings for that field change 
                        over time and by degree level. There is a comparison feature which, when selected, allows you to select up to 3 other fields within the same 
                        degree level and better understand how your selected field compares to others in terms of income for each measurement period. The goal of this app is 
                        to help you to make more informed decisions about your education and future opportunities by exploring pre-existing data from Colorado graduates.", 
                        checkboxInput("table", 
                                      "View Raw Data",
                                      value = FALSE),
                        conditionalPanel(condition = "input.table",
                                         dataTableOutput("table"))
                        ))
    
)


server <- function(input, output, session) {
    
    #Handling invalid major errors
    observeEvent(input$submit,{
        if(!(input$major %in% pseo$label)){
        shinyalert(title = "Error",
                   text = "Invalid major selection.",
                   type = "error")
        }
    })
    
    #Creating a select button that updates degree options based on major choice
    observe({
        options <- pseo %>%
            group_by(label) %>% 
            filter(label == input$major) %>% 
            distinct(label_degree_level)
        options <- as.character(as_vector(options$label_degree_level))
        updateSelectInput(session = session, inputId = "degree", choices = options)
    })
    
    #Creating a select button that updates comparision options based on major + degree level choice
    observe({
        major_options <- pseo %>%
            group_by(label) %>% 
            filter(label_degree_level == input$degree) %>% 
            distinct(label) 
        major_options <- as.character(as_vector(major_options$label))
        #Remove the already selected major as an option
        major_options <- major_options[!major_options %in% input$major]
        updateSelectInput(session = session, inputId = "major2", choices = major_options)
    })
    
    #Displaying the major
    selected_text <- eventReactive(input$submit,{ 
        HTML(paste("<h3>","You have selected: ", "</h3>","<h4>", "<b>", input$major,":",input$degree, "</h4>","</b>", "<br>"))
    })
    output$selected <- renderUI({selected_text()})
    
    #Displaying the description of the program
    description_text <- eventReactive(input$submit, { 
        def <- pseo[(pseo$label == input$major), "CIPDefinition"]
        def <- as.character(as.vector(def[1,]))
        HTML(paste("<h3>", "Description of program: ", "</h3>","<b>","<h4>" ,def,"</b>","</h4>", 
                   "<br>","<h3>","Salary Explorer:", "</h3>"))
    })
    output$info <- renderUI({description_text()})
    
    #Displaying help text that lets user know about comparision feature
    #if they don't select it 
    help_text <- eventReactive(input$submit, { 
        if(input$multiple == FALSE){
        h5("If you would like to compare your selected
            field to others within the same degree level,
            please use the checkbox on the right.")
        }
    })
    output$userHelp <- renderUI({help_text()})
    
    
    observeEvent(input$submit,{
        
        #Creating a string of the selected majors for the plot
        majors <- c(input$major, input$major2)
        majors <- paste(majors, collapse = "|")
        
        #caclulating the means + making the df long
        plot_data <- pseo %>% 
            group_by(label) %>% 
            filter(label_degree_level == input$degree, str_detect(label, majors)) %>% 
            summarise(`1 year` =  mean(as.numeric(y1_p50_earnings)),
                      `5 years` =  mean(as.numeric(y5_p50_earnings)),
                      `10 years` =  mean(as.numeric(y10_p50_earnings))) 
        
        plot_data_long <- plot_data %>% 
            pivot_longer(cols = c(`1 year`, `5 years`, `10 years`), names_to = "Type", values_to = "Amount")
        
        #fomatting Type for the plot
        plot_data_long <- plot_data_long %>% 
            mutate(Type = factor(Type, levels = c("1 year", "5 years", "10 years"))) 
        
        plot1 <- ggplot(plot_data_long, mapping = aes(x = Type, y = Amount, fill = label)) +
            geom_bar(stat = "identity", width = 0.7, position=position_dodge(width = 0.85)) +
            geom_text(aes(label = str_c("$", format(round(as.numeric(Amount), 0), big.mark = ","))), 
                      position = position_dodge(width = 0.9), vjust = -0.25) +
            theme_light(base_size = 15) +
            scale_y_continuous(limit = c(0, 155000)) + scale_fill_brewer(palette = "Set2") +
            labs(title = "Average Median Earnings", subtitle = "1, 5, and 10 Years Post-Graduation", 
                 x = "Years After Graduation", y = "Average Median Earnings", fill = "Major")
        
        output$salaries <- renderPlot({
            plot1
        })
    })
    
    #DataTable for Info Tab
    output$table <- renderDataTable({
        pseo %>% 
            select(label_cipcode,label, label_grad_cohort, label_institution, label_degree_level,
                   y1_p50_earnings, y5_p50_earnings, y10_p50_earnings) 
    })
    
    
}

# Run the application 
shinyApp(ui = ui, server = server)
