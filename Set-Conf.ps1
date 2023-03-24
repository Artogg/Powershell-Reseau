<#
.DESCRIPTION
Script pour passer un jeu de commandes sur une liste de switchs.
Utilise l'entree keepass admin associee.
.PARAMETER FichierConf
Le fichier de conf a passer sur les switchs
.PARAMETER FichierInventaire
Le fichier inventaire recensant les switchs sur lesquels passer les commandes
.INPUTS
Prerequis sur votre poste:
- installer le module KeePass pour powershell,
- installer .Net 4.0 Posh-SSH module.
.EXAMPLE
Set-conf.ps1 FichierConf FichierInventaire
Set-conf.ps1 -FichierConf MonFichierDeConf -FichierInventaire MonFichierInventaire
#>

param(
    [Parameter()]
    [String]$FichierConf,
    [Parameter()]
    [String]$FichierInventaire
)

begin{}

process{
    #Variables
    $date = Get-Date -Format "ddMMyyyy"
    $timestamp = Get-Date -Format "HHmmss"
    $LogsDir="$PSScriptRoot\logs-conf\$date"
    $EntreeKeepass= get-Secret -vault MonVaulKeePass -name MonEntreeKeePass
    

    ## Test fichiers
    #Je teste si le fichier d'inventaire et le fichier de conf sont indiques et s'ils existent
    if(($FichierInventaire -ne '') -and ($FichierConf -ne '')){
        if (((Test-Path -Path $FichierInventaire) -eq $false) -or ((Test-Path -Path $FichierConf) -eq $false)){
            Write-Output "Fichier(s) introuvable(s). Verifier le chemin de destination`n"
            exit
        }
    }
    #Je teste si le dossier des logs du jour existe, sinon je le cree
    if ((Test-Path -Path $LogsDir) -eq $false){
        New-Item -ItemType Directory $LogsDir | Out-Null
    }

    ## Lancement de session SSH
    #Pour chaque switch du fichier d'inventaire, je vais chercher la conf en creant une session ssh et en passant la commande qui va bien
    foreach($Switchs in Get-Content $FichierInventaire){
        #Pour chaque switch, je garde le nom pour creer le fichier de backup
        $LogsFile="$LogsDir\$timestamp-$Switchs"
        Write-Output "Passage des commandes sur $Switchs"

        #Je teste si l'equipement repond au ping
        if (Test-Connection -ComputerName $Switchs -Count 3 -Quiet) {
            #Je lance une session vers le sw en utilisant l'entree keepass en utilisant le module POSH-SSH
            New-SShSession -ComputerName $Switchs -Credential $EntreeKeepass -AcceptKey | Out-Null
            $session = Get-SSHSession -Index 0 
            $stream = $session.Session.CreateShellStream("dummy", 0, 0, 0, 0, 1024)
            Start-Sleep 2

            $out =''

            #Je passe chaque ligne de conf pour chaque equipement
            Foreach($LigneDeConf in Get-Content $FichierConf){
                $stream.WriteLine($LigneDeConf)

                #Si je sauvegarde je laisse un peu de temps pour le process
                if (($LigneDeConf -match ".*save force.*") -or ($LigneDeConf -match ".*copy run.*")){
                    Start-Sleep 5
                } else {
                    Start-Sleep -Milliseconds 500   
                }
                #je lis la session pour capturer la reponse du switch dans le flux ssh 
                do {
                    $out +=$stream.read()
                } while ($stream.DataAvailable)


            }
                #Je redirige la sortie des flux vers un fichier de logs
                $outputLines = $out.Split("`n")
                $outputLines | Out-File $LogsFile -Append
                #Je coupe la session SSH
                Remove-SSHSession -Index 0 | Out-Null
        } else {
            #Si je ne ping pas -> l'equipement est injoignable
            Write-Output "L'equipement $Switchs est injoignable."
        }
    }
}





