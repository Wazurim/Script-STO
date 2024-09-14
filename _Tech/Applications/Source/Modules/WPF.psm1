Add-Type -AssemblyName PresentationFramework #Pour supporter le WPF

function Read-XamlFileContent($xamlFile)
{
    <#
.SYNOPSIS
    Imports the content of a XAML file as a string.
.DESCRIPTION
    Reads the content of a specified XAML file and returns it as a string. This string can then be used for further processing, such as formatting or loading into a WPF application.
.PARAMETER xamlFile
    The path to the XAML file to be imported.
.OUTPUTS
    System.String
    Returns the content of the specified XAML file as a single string.
.EXAMPLE
    $inputXML = import-XamlFromFile "c:\_tech\MainWindow.xaml"
    This command imports the content of the XAML file located at "c:\_tech\MainWindow.xaml" into the `$xamlContent` variable.
.NOTES
    Ensure that the file path provided is correct and the file exists. This function reads the entire content of the file as a raw string.
#>
    $xamlContent = Get-Content $xamlFile -Raw
    return $xamlContent
}

function Format-XamlFile($xamlContent) 
{
    $formatedXamlFile = $xamlContent -replace 'mc:Ignorable="d"', '' -replace "x:N", 'N' -replace '^<Win.*', '<Window'
    return $formatedXamlFile
}

function Convert-ToXmlDocument($xamlContent)
{
    <#
.SYNOPSIS
    Converts a string of XML content into an XML document object.
.DESCRIPTION
    The `Convert-ToXmlDocument` function takes a string containing XML content and converts it into a `System.Xml.XmlDocument` object.
.PARAMETER xamlContent
    The XML content as a string. This should be a valid XML format.
.OUTPUTS
    System.Xml.XmlDocument
    Returns an `XmlDocument` object created from the provided XML string.
.EXAMPLE
    $xmlContent = "<root><element>Value</element></root>"
    $xmlDoc = Convert-ToXmlDocument $xmlContent
    This command converts the XML string in `$xmlContent` to an `XmlDocument` object stored in `$xmlDoc`.
.NOTES
    Ensure that the XML content provided is well-formed. This function does not perform validation beyond basic parsing.
#>
    [XML]$xmlDoc = $xamlContent 
    return $xmlDoc
}


function New-XamlReader($formatedXamlFile) 
{
    $XamlReader = (New-Object System.Xml.XmlNodeReader $formatedXamlFile)
    return $XamlReader
}

function New-WPFWindowFromXaml($XamlReader)
{
    try 
    {
        $window = [Windows.Markup.XamlReader]::Load($XamlReader)
        return $window
    } 
    catch 
    {
        Write-Warning $_.Exception
        throw
    }
}

function Get-WPFControlsFromXaml {
    param (
        [System.Xml.XmlDocument]$xmlDoc,
        [System.Windows.Window]$window,
        [hashtable]$sync= @{}
    )

    $formControls = [PSCustomObject]@{}
    # Process the XAML nodes and add controls to the hashtable
    $xmlDoc.SelectNodes("//*[@Name]") | ForEach-Object {
        try 
        {
            $control = $window.FindName($_.Name)
            $formControls | Add-Member -MemberType 'NoteProperty' -Name "$($_.Name)" -Value $control -ErrorAction Stop

            # Store the control in the synchronization hashtable
            $sync[$_.Name] = $control
        } 
        catch 
        {
            throw
        }
    }
    return $formControls
}


function Start-WPFApp($window)
{
    $Null = $window.Show() 
}

function Start-WPFAppDialog($window)
{
    $Null = $window.ShowDialog() 
}
#ShowDialog waits fro the form to close before it continues, Show doesn't
#ShowDialog is useful when you want to present info to a user, or let him change it, or get info from him before you do anything else.
#Show is useful when you want to show information to the user but it is not important that you wait fro him to be finished

#$formControls | get-member
#$formControls.var_chkboxVLC.IsChecked