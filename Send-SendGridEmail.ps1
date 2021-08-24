<#
.SYNOPSIS
    Send email via SendGrid API
.DESCRIPTION
    This is a function to allow users to send automated notifications via the SendGrid API as an alternative to Send-Mail which is now depracated.
.EXAMPLE
    PS C:\> ./Send-SendGridEmail.ps1 -APIKey 'io34uf9043uj90c34poweifkdc,;rs.wrw349rtf0j5e' -To test@test.com -CC copytest@test.com -From noreply@test.co.uk -Body 'This is a test email' -BodyType 'text/html' -Subject 'Testing SendGrid' -FromName 'Test Notifications'

.NOTES
    Author: Jay Silva
    Version: 1.0
    Published Date: 23/08/2021
#>

[CmdletBinding()]
param (
    # Allows you to set the API key for SendGrid
    [Parameter(Mandatory=$true)]
    [String]
    $APIKey,

    # Allows you to set the recipients of your message.
    [Parameter(Mandatory=$true)]
    [ValidateScript({$_ -like '*@*'},ErrorMessage='{0} is not a valid email address.')]
    [String[]]
    $To,

    # Allows you to add recipients to be copied in.
    [Parameter(Mandatory=$false)]
    [ValidateScript({$_ -like '*@*'},ErrorMessage='{0} is not a valid email address.')]
    [String[]]
    $CC,

    # Allows you to set the From address
    [Parameter(Mandatory=$true)]
    [ValidateScript({$_ -like '*@*'},ErrorMessage='{0} is not a valid email address.')]
    [String]
    $From,

    # Allows you to set the Display Name of the sender.
    [Parameter(Mandatory=$false)]
    [String]
    $FromName,

    # Allows you to set the email subject.
    [Parameter(Mandatory=$true)]
    [String]
    $Subject,

    # Allows you to set the content type for your email.
    [Parameter(Mandatory=$true)]
    [ValidateSet('text/plain','text/html',ErrorMessage='{0} is not a valid Body type.')]
    [String]
    $BodyType,

    # This is the body (content) of your email.
    [Parameter(Mandatory=$true)]
    [String[]]
    $Body
)

begin{

    #Region Headers
    $headers = @{}
    $headers.add('authorization',('Bearer {0}' -f $APIKey))
    $headers.add('content-type','application/json')
    #EndRegion

    #Region Data
    $data = @{}
    $personalizations = @{}

    #Region Recipients
    $to | ForEach-Object -Begin {
        $recipients = @()
    } -Process {
        $recipients += @{email=$_}
    } -End {
        $personalizations.add('to',$recipients)
        Remove-Variable -Name recipients -Force
    }

    if ($cc) {
        $cc | ForEach-Object -Begin {
            $recipients = @()
        } -Process {
            $recipients += @{email=$_}
        } -End {
            $personalizations.add('cc',$recipients)
            Remove-Variable -Name recipients -Force
        }
    }
    #EndRegion

    #Region Body
    $content = @()
    $content += @{'type'=$BodyType;'value'="$Body"}
    #EndRegion

    #Region Data Json Conversion
    $data = [PSCustomObject]@{
        Content = $content
        Personalizations = @($personalizations)
        From = @{
            'email'=$From
            'name'=if ($FromName) {
                $FromName
            } else {
                $From
            }
        }
        Subject = $Subject
    }
    Remove-Variable -Name personalizations -Force
    #EndRegion
    #EndRegion
}

process {
    $data.content.value.gettype()
    try { 
        Invoke-WebRequest -Uri 'https://api.sendgrid.com/v3/mail/send' -Headers $headers -Body ($data | ConvertTo-Json -Depth 4) -Method POST
    }
    catch {
        Write-Error -Message ($_.ErrorDetails.Message | ConvertFrom-Json).Errors.Message
    }
}
end {

}
