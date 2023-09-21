<# 
.DESCRIPTION
Script pour recuperer les differentes informations sur la connexion a une borne (puissance, signal, canal...).
Se balader entre deux bornes pour voir le changement d appairement.
#>

# La commande netsh ne renvoie pas d'objet, seuleument une suite de string, ce qui oblige a faire des grep
while ($true) {
    $NetSH = netsh wlan sh int
    if($NetSH) {
       $InfoNetSh = [PSCustomObject] @{
                    "Timestamp"= Get-Date -Format "ddMMyyyy HH:mm:ss"
                    "BSSID"= $($NetSH -match "^\s+BSSID" -split(": "))[1]
                    "Signal"= $($NetSH -match "^\s+Signal" -split(": "))[1]
                    "Canal"= $($NetSH -match "^\s+Canal" -split(": "))[1]
                    "Radio Type"= $($NetSH -match "^\s+Type de radio" -split(": "))[1]  
        }
        $InfoNetSh
        Start-Sleep -s 0.5
    } else {
        Write-Output "Impossible de se connecter a l'AP."
        break
    }
}