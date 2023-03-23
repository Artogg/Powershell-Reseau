<#
.DESCRIPTION
Script pour faire un backup de la conf de switchs HP.
Utilise l'entree keepass admin associee.

.INPUTS
Prerequis sur votre poste:
- installer le module KeePass pour powershell,
- installer .Net 4.0 Posh-SSH module.

.EXAMPLE
Get-conf.ps1 monswitch
Get-conf.ps1 -Switch monswitch
#>

param(
    [Parameter()]
    [String]$FichierInventaire
)

begin{}

process{
    #Variables
    $date = Get-Date -Format "HHmmss_ddMMyyyy"
    $BackupDir="$PSScriptRoot\Backup\HP"
    $Temp="$BackupDir\temp"
    $EntreeKeepass= get-Secret -vault MonKeePass -name "MonEntree" 
    
    #Je teste si le fichier d'inventaire est indique et s'il existe
    if($FichierInventaire -ne ''){
        if ((Test-Path -Path $FichierInventaire) -eq $false){
            Write-Output "Le fichier $FichierInventaire n'existe pas.`n"
            exit
        }
    } else { 
        Write-Output "Veuillez indiquer un fichier d'inventaire.`n"
        exit
    }

    #Pour chaque switch du fichier d'inventaire, je vais chercher la conf en creant une session ssh et en passant la commande qui va bien
    Foreach($Switchs in Get-Content $FichierInventaire){
        #Pour chaque switch, je garde le nom pour creer le fichier de backup
        $BackupFile="$BackupDir\$date-$Switchs"
        #Je lance une session vers le sw en utilisant l'entree keepass et j'accepte la clef
        New-SShSession -ComputerName $Switchs -Credential $EntreeKeepass
        $session = Get-SSHSession -Index 0 
        $stream = $session.Session.CreateShellStream("dummy", 0, 0, 0, 0, 0)

        do { 
            $stream.read() 

        } while ($stream.DataAvailable)

        Start-Sleep 1
        #Je desactive le prompt ---- More ---- pour lire la conf en un seul ecran
        $stream.WriteLine("screen-length disable") 
        $stream.write("dis current-configu`n")
        #je laisse du temps pour recuperer toute la conf
        Start-Sleep 30

        #Je reactive le prompt ---- More ----
        $stream.WriteLine("undo screen-length disable") 
            

        #je lis la session pour capturer la reponse du switch dans le flux ssh 
        $out =''
        do {
            $out +=$stream.read()
        } while ($stream.DataAvailable)

        #Je redirige le flux vers un fichier temporaire
        $outputLines = $out.Split("`n")
        $outputLines | Out-File "$Temp"

        #Je coupe la session SSH
        Remove-SSHSession -Index 0

        #Var pour me dire quand commencer a copier dans le fichier backdup
        $Flip = "Stop"

        #Traitement de texte pour ne garder que la conf (enlever les premieres commandes)
        Foreach($Ligne in Get-Content -Path $Temp){
            #Je parse jusqu'a ma commande, comme ca je coupe la banniere et la commande, j'initialise ma va pour commencer a copier les lignes
            if ($Ligne -match ".*dis current.*"){
                $Flip = "Start"
                continue
            }
            #Si la ligne contient return je sors de la boucle
            if ($Ligne -match "return"){
                break
            }
            #Si j'ai le go, j'envoie la ligne dans mon fichier backup
            if ($Flip -eq "Start"){
                Write-Output "$Ligne" | Out-file "$BackupFile" -append
            }
        }
        #Je supprime le fichier temporaire
        Remove-Item $Temp
    }
}




