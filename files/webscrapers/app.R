library(shiny)

ui <- fluidPage(
    # static title that will be visible to BS4
    titlePanel("Scraping Demo Page"),

    # dynamic content that requires JavaScript
    mainPanel(
        actionButton("showText", "Click Me!"),
        textOutput("dynamicText")
    )
)

server <- function(input, output) {
    output$dynamicText <- renderText({
        # only show text after button click
        if(input$showText > 0) {
            "This text was dynamically generated!"
        }
    })
}

shinyApp(ui = ui, server = server)

# run this app while attached to the docker container using the following command
# shiny::runApp("files/selenium/", host = "0.0.0.0", port = 8123)



