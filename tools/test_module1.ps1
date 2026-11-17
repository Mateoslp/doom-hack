$ErrorActionPreference = "Stop"

$jdkBin = "C:\Users\LENOVO\AppData\Local\Programs\Bizagi\Bizagi Modeler\jre6\64\bin"
$n2tTools = "C:\Users\LENOVO\Downloads\nand2tetris\nand2tetris\tools"
$jackCompiler = "$n2tTools\JackCompiler.bat"
$vmEmulator = "$n2tTools\VMEmulator.bat"

$srcDir = "C:\DoomProject\src"
$expectedClasses = @(
    "GameConstants", "GameState", "MathUtils", "InputManager", "ScoreManager",
    "WorldRenderer", "Player", "HUD",
    "Enemy", "Projectile", "PhysicsEngine", "EntityManager",
    "CollisionManager", "Renderer",
    "DoomGame", "Main"
)

$env:PATH = "$jdkBin;" + $env:PATH

Write-Host "=== [1/8] Compilando C:\DoomProject\src con JackCompiler v2.5 ==="
$compileOut = & $jackCompiler $srcDir 2>&1
$compileOut | ForEach-Object { Write-Host $_ }

# Validar que no existan mensajes de error (JackCompiler devuelve exit code 0 aun con errores)
$errors = $compileOut | Where-Object { $_ -match "In .*\.jack" -or $_ -match "Error" }
if ($errors) {
    Write-Error "Fallo de compilacion en src/: $($errors -join '; ')"
    exit 1
}

foreach ($cls in $expectedClasses) {
    if (-not (Test-Path "$srcDir\$cls.vm")) {
        Write-Error "No se genero $srcDir\$cls.vm"
        exit 1
    }
}

function Invoke-VmTestSuite {
    param(
        [string]$SuiteName,
        [string]$SuiteDir,
        [string]$TstFile,
        [string]$CmpFile,
        [string]$OutFile
    )

    $stageDir = "$SuiteDir\vm_run"
    Write-Host "`n=== Ejecutando suite $SuiteName en entorno aislado ($stageDir) ==="
    if (Test-Path $stageDir) {
        Remove-Item -Path $stageDir -Recurse -Force
    }
    New-Item -ItemType Directory -Path $stageDir | Out-Null

    # Copiar todos los .vm compilados de src/ y compilar el arnes Main.jack de la suite
    Copy-Item "$srcDir\*.vm" -Destination $stageDir -Force
    Copy-Item "$SuiteDir\Main.jack" -Destination $stageDir -Force

    $testCompileOut = & $jackCompiler "$stageDir\Main.jack" 2>&1
    $testCompileOut | ForEach-Object { Write-Host $_ }
    $testErrors = $testCompileOut | Where-Object { $_ -match "In .*\.jack" -or $_ -match "Error" }
    if ($testErrors) {
        Write-Error "Fallo de compilacion en $SuiteName/Main.jack: $($testErrors -join '; ')"
        exit 1
    }
    Remove-Item "$stageDir\Main.jack" -Force

    # Copiar OS/*.vm UNICAMENTE en el directorio temporal de test CLI (nunca en src/)
    Copy-Item "$n2tTools\OS\*.vm" -Destination $stageDir -Force
    Copy-Item "$SuiteDir\$TstFile" -Destination $stageDir -Force
    Copy-Item "$SuiteDir\$CmpFile" -Destination $stageDir -Force

    Push-Location $stageDir
    $prevEap = $ErrorActionPreference
    $ErrorActionPreference = "Continue"
    $emuOut = & $vmEmulator $TstFile 2>&1
    $ErrorActionPreference = $prevEap
    Pop-Location
    $emuOut | ForEach-Object { Write-Host $_ }

    Copy-Item "$stageDir\$OutFile" -Destination "$SuiteDir\$OutFile" -Force
    Write-Host "--- Resultado $OutFile ---"
    Get-Content "$SuiteDir\$OutFile"

    if (-not ($emuOut -match "End of script - Comparison ended successfully")) {
        Write-Error "La validacion de $SuiteName en VMEmulator NO finalizo con comparacion exitosa."
        exit 1
    }
}

Write-Host "`n=== [2/8] Regresion del Modulo Fundacional (Module1Test) ==="
Invoke-VmTestSuite `
    -SuiteName "Module1Test" `
    -SuiteDir "C:\DoomProject\tests\Module1Test" `
    -TstFile "Module1Test.tst" `
    -CmpFile "Module1Test.cmp" `
    -OutFile "Module1Test.out"

Write-Host "`n=== [3/8] Regresion de Capa 1: InputManager + ScoreManager (InputScoreTest) ==="
Invoke-VmTestSuite `
    -SuiteName "InputScoreTest" `
    -SuiteDir "C:\DoomProject\tests\InputScoreTest" `
    -TstFile "InputScoreTest.tst" `
    -CmpFile "InputScoreTest.cmp" `
    -OutFile "InputScoreTest.out"

Write-Host "`n=== [4/8] Regresion de Modulo 2: WorldRenderer (WorldRendererTest) ==="
Invoke-VmTestSuite `
    -SuiteName "WorldRendererTest" `
    -SuiteDir "C:\DoomProject\tests\WorldRendererTest" `
    -TstFile "WorldRendererTest.tst" `
    -CmpFile "WorldRendererTest.cmp" `
    -OutFile "WorldRendererTest.out"

Write-Host "`n=== [5/8] Regresion de Modulo 3: Player + HUD (PlayerHudTest) ==="
Invoke-VmTestSuite `
    -SuiteName "PlayerHudTest" `
    -SuiteDir "C:\DoomProject\tests\PlayerHudTest" `
    -TstFile "PlayerHudTest.tst" `
    -CmpFile "PlayerHudTest.cmp" `
    -OutFile "PlayerHudTest.out"

Write-Host "`n=== [6/8] Regresion de Modulo 4: Entidades, Pools y Fisica (EntitiesPhysicsTest) ==="
Invoke-VmTestSuite `
    -SuiteName "EntitiesPhysicsTest" `
    -SuiteDir "C:\DoomProject\tests\EntitiesPhysicsTest" `
    -TstFile "EntitiesPhysicsTest.tst" `
    -CmpFile "EntitiesPhysicsTest.cmp" `
    -OutFile "EntitiesPhysicsTest.out"

Write-Host "`n=== [7/8] Regresion de Modulo 5: Colisiones y Renderizado (CollisionRendererTest) ==="
Invoke-VmTestSuite `
    -SuiteName "CollisionRendererTest" `
    -SuiteDir "C:\DoomProject\tests\CollisionRendererTest" `
    -TstFile "CollisionRendererTest.tst" `
    -CmpFile "CollisionRendererTest.cmp" `
    -OutFile "CollisionRendererTest.out"

Write-Host "`n=== [8/8] Validacion de Modulo 6: Integracion del Juego DoomGame + Main (DoomGameTest) ==="
Invoke-VmTestSuite `
    -SuiteName "DoomGameTest" `
    -SuiteDir "C:\DoomProject\tests\DoomGameTest" `
    -TstFile "DoomGameTest.tst" `
    -CmpFile "DoomGameTest.cmp" `
    -OutFile "DoomGameTest.out"

Write-Host "`nVALIDACION COMPLETA: Module1Test (44/44) + InputScoreTest (40/40) + WorldRendererTest (36/36) + PlayerHudTest (40/40) + EntitiesPhysicsTest (44/44) + CollisionRendererTest (36/36) + DoomGameTest (40/40) = 280/280 aprobadas en VMEmulator."
