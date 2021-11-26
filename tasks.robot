*** Settings ***
Documentation     Orders robots from RobotSpareBin Industries Inc.
...               Saves the order HTML receipt as a PDF file.
...               Saves the screenshot of the ordered robot.
...               Embeds the screenshot of the robot to the PDF receipt.
...               Creates ZIP archive of the receipts and the images.
Library    RPA.Browser
Library    RPA.Excel.Files
Library    RPA.HTTP
Library    RPA.Tables
Library    RPA.PDF
Library    RPA.Archive
Library    RPA.Dialogs
Library    RPA.Robocloud.Secrets


*** Variables ***
${GLOBAL_RETRY_AMOUNT}=    5x
${GLOBAL_RETRY_INTERVAL}=    0.5s

*** Keywords ***
Open the robot order website
    Add heading    Please enter the RobotSpareBin URL
    Add text input    name=robotsparebin
    ${URL}=    Run dialog
    Open Available Browser    ${URL.robotsparebin}
    Wait Until Page Contains Element    css:button.btn.btn-dark

*** Keywords ***
Download The Excel File
    ${secret}=    Get Secret    credentials
    Download    ${secret}[excel_url]    overwrite=true

*** Keywords ***
Get Orders
    ${orders}=    Read table from CSV    orders.csv    header=True
    [Return]    ${orders}

*** Keywords ***
Close the annoying modal
    Click Element    css:button.btn.btn-dark


*** Keywords ***
Fill the form
    [Arguments]    ${row}
    Select From List By Value    css:select#head.custom-select    ${row}[Head]
    IF    ${row}[Body]==1
    Click Button When Visible   id:id-body-1
    ELSE IF    ${row}[Body]==2
    Click Button When Visible    id:id-body-2
    ELSE IF    ${row}[Body]==3
    Click Button When Visible    id:id-body-3
    ELSE IF    ${row}[Body]==4
    Click Button When Visible   id:id-body-4
    ELSE IF    ${row}[Body]==5
    Click Button When Visible    id:id-body-5
    ELSE
    Click Button When Visible    id:id-body-6
    END
    Input Text   class:form-control  ${row}[Legs]
    Input Text    id:address    ${row}[Address]

*** Keywords ***
Preview the robot
    Click Button When Visible    css:button#preview.btn.btn-secondary
    Click Button When Visible    css:button#order.btn.btn-primary
    Page Should Contain Element    css:div#receipt.alert.alert-success

*** Keywords ***
Submit the order
    Wait Until Keyword Succeeds    ${GLOBAL_RETRY_AMOUNT}  ${GLOBAL_RETRY_INTERVAL}    Preview the robot

*** Keywords ***
Store the receipt as a PDF file
    [Arguments]    ${row}
    ${receipt_html}=    Get Element Attribute    css:div#receipt.alert.alert-success    outerHTML
    ${receipt_pdf}=    Html To Pdf    ${receipt_html}    ${CURDIR}${/}output${/}receipt${row}[Order number].pdf
    [Return]    ${CURDIR}${/}output${/}receipt${row}[Order number].pdf

*** Keywords ***
Take a screenshot of the robot
    [Arguments]    ${row}
    Screenshot    css:div#robot-preview-image    ${CURDIR}${/}output${/}receipt${row}[Order number].png
    [Return]    ${CURDIR}${/}output${/}receipt${row}[Order number].png

*** Keywords ***
Embed the robot screenshot to the receipt PDF file
    [Arguments]    ${row}
    ${files}=    Create List
    ...   ${CURDIR}${/}output${/}receipt${row}[Order number].pdf
    ...   ${CURDIR}${/}output${/}receipt${row}[Order number].png
    Add Files To PDF    ${files}    ${CURDIR}${/}output${/}receipt_${row}[Order number].pdf

*** Keywords ***
Go to order another robot
    Click Button When Visible    css:button#order-another.btn.btn-primary

*** Keywords ***
Create a ZIP file of the receipts
    Archive Folder With Zip    ${CURDIR}${/}output    receipt.zip

*** Tasks ***
Order robots from RobotSpareBin Industries Inc
    Open the robot order website
    Download The Excel File
    ${orders}=    Get orders
    FOR    ${row}    IN    @{orders}
        Close the annoying modal
        Fill the form    ${row}
        Submit the order
        ${pdf}=    Store the receipt as a PDF file    ${row}
        ${screenshot}=    Take a screenshot of the robot    ${row}
        Embed the robot screenshot to the receipt PDF file     ${row}
        Go to order another robot
    END
    Create a ZIP file of the receipts
