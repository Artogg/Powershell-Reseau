<# 
.DESCRIPTION
Script pour recuperer les differentes informations sur la connexion a une borne (puissance, signal, canal...).
Se balader entre deux bornes pour voir le changement d appairement.
#>

# La commande netsh ne renvoie pas d'objet, seuleument une suite de string, ce qui oblige a faire des grep

# On force l'UTF-8
$OutputEncoding = [System.Console]::OutputEncoding = [System.Console]::InputEncoding = [System.Text.Encoding]::UTF8
$PSDefaultParameterValues['*:Encoding'] = 'utf8'


# Jusqu'à l'arrêt manuel, on boucle sur le résultat de la commande netsh
while ($true) {
    $NetSH = netsh wlan sh int
    if($NetSH) {
       $InfoNetSh = [PSCustomObject] @{
                    "Timestamp"= Get-Date -Format "dd/MM/yyyy HH:mm:ss"
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
        $InfoNetSh
        Start-Sleep 1
    } else {
        Write-Output "Impossible de se connecter a l'AP."
        break
    }
}
