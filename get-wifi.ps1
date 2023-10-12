$OutputEncoding = [System.Console]::OutputEncoding = [System.Console]::InputEncoding = [System.Text.Encoding]::UTF8
$PSDefaultParameterValues['*:Encoding'] = 'utf8'

function get-timestamp{
    return get-date -Format "dd/MM/yyyy HH:mm:ss"
}

function get-IntWifi{
    $intWifi = Get-NetIPConfiguration | Where-object -property InterfaceAlias -Match "Wi-Fi" 
    return $intwifi
} 

function get-netsh{
    $NetSh = netsh wlan sh int
    $InfoNetSh = [PSCustomObject] @{
                    "Adresse MAC carte Wifi du poste" = $($NetSH -match "Adresse physique" -split(": "))[1]
                    "SSID" = $($NetSH -match "SSID" -split(": "))[1]
                    "BSSID"= $($NetSH -match "BSSID" -split(": "))[1]
                    "Signal"= $($NetSH -match "Signal" -split(": "))[1]
                    "Canal"= $($NetSH -match "Canal" -split(": "))[1]
                    "Radio Type"= $($NetSH -match "Type de radio" -split(": "))[1]
                    "Download (Mbps)" =   $($NetSH -match "Réception" -split(": "))[1]
                    "Upload (Mbps)" = $($NetSH -match "Transmission" -split(": "))[1]
                    "Authentification" = $($NetSH -match "Authentification" -split(": "))[1]
                    "Chiffrement" = $($NetSH -match "Chiffrement" -split(": "))[1]
        }
        return $InfoNetSh | Format-list -Property *
}

function get-RealTimeNetsh{
    while($true){
        if(get-netsh){
            get-timestamp
            get-netsh
            write-output "############################################################################################"
            Start-sleep 2
        } else {
            get-timestamp
            write-output "AP injoignable."
            Start-sleep 10
        }
    }
}

if (get-IntWifi){
        get-timestamp
        get-IntWifi
} else {
        write-output "Interface Réseau sans fil non détectée"
        exit
}
get-RealTimeNetsh

