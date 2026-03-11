#!/usr/bin/env pwsh
<#
.SYNOPSIS
    Crea las redes Docker necesarias para el proyecto AS-2025.
    
.DESCRIPTION
    Este script crea las redes Docker especificadas en NETWORK_SPECS_DEFAULT.
    Puede personalizarse editando esta variable o pasando NETWORK_SPECS_ENV.
    
.EXAMPLE
    ./create-docker-networks.ps1
    
.EXAMPLE
    $env:NETWORK_SPECS_ENV = "dev_net:172.30.10.0/24 prod_net:172.30.20.0/24"
    ./create-docker-networks.ps1
#>

$ErrorActionPreference = "Stop"

function Write-Log {
    param([string]$Message)
    [Console]::Error.WriteLine($Message)
}

function Write-Error-Exit {
    param([string]$Message)
    [Console]::Error.WriteLine("ERROR: $Message")
    exit 1
}

function Test-CommandExists {
    param([string]$Command)
    $null = Get-Command $Command -ErrorAction SilentlyContinue
    if (-not $?) {
        Write-Error-Exit "No se encontró el comando requerido: $Command"
    }
}

# Verificar que Docker está instalado
Test-CommandExists docker

# Define redes en formato: nombre[:subnet]
# - Sin subnet: Docker asigna una automáticamente.
# - Con subnet: evita solapamientos (ej. 172.30.10.0/24)
#
# Personaliza de 2 formas:
# 1) Edita NETWORK_SPECS aquí.
# 2) O pásalo por variable de entorno, separando por espacios:
#    $env:NETWORK_SPECS_ENV = 'dev_net:172.30.10.0/24 prod_net:172.30.20.0/24'; ./scripts/create-docker-networks.ps1
$NETWORK_SPECS_DEFAULT = @(
    "development_net:172.40.0.0/24"
    "services_net:172.20.0.0/24"
    "production_net:172.30.0.0/24"
    "vpn_net:172.10.0.0/24"
)

# Usar variable de entorno si está definida
if ($env:NETWORK_SPECS_ENV) {
    $NETWORK_SPECS = $env:NETWORK_SPECS_ENV -split '\s+' | Where-Object { $_ }
} else {
    $NETWORK_SPECS = $NETWORK_SPECS_DEFAULT
}

function Create-NetworkIfMissing {
    param(
        [string]$Name,
        [string]$Subnet = ""
    )
    
    docker network inspect $Name *>$null
    if ($LASTEXITCODE -eq 0) {
        Write-Log "==> Red existe: $Name"
        return
    }
    
    Write-Log "==> Creando red: $Name"
    if ($Subnet) {
        docker network create --driver bridge --subnet $Subnet $Name | Out-Null
    } else {
        docker network create --driver bridge $Name | Out-Null
    }
}

# Procesar cada especificación de red
foreach ($spec in $NETWORK_SPECS) {
    if (-not $spec) {
        continue
    }
    
    # Parsear nombre:subnet
    $parts = $spec -split ':', 2
    $name = $parts[0]
    $subnet = if ($parts.Count -gt 1 -and $parts[1]) { $parts[1] } else { "" }
    
    if (-not $name) {
        Write-Error-Exit "Spec inválido (nombre vacío): '$spec'"
    }
    
    Create-NetworkIfMissing -Name $name -Subnet $subnet
}

Write-Log "Listo. Redes creadas (o ya existían)."
Write-Log "Tip: lista redes con: docker network ls"
