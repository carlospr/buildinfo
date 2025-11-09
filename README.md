# make-buildinfo.ps1

Script de PowerShell que genera un archivo `buildinfo.json` con información detallada sobre la compilación actual.  
Está pensado para proyectos que necesiten incluir metadatos del build dentro de sus artefactos finales, como juegos o aplicaciones multiplataforma.

---

## Descripción

El script recopila y registra información relevante del entorno de compilación:

- Versión del proyecto (`version`)
- Canal de build (`channel`: dev, beta o release)
- Plataforma destino (`platform`)
- Commit Git actual (`commit`)
- Identificador único de build (`buildId`)
- Fecha y hora UTC de compilación (`compiledAt`)
- Versión de datos o reglas (`dataVersion`)
- Versión del motor o framework (`engineVersion`)
- Nombre de la máquina de build (`buildMachine`)

El resultado se guarda como un fichero JSON, por ejemplo:

```json
{
  "version": "0.2.0",
  "channel": "dev",
  "platform": "Windows",
  "commit": "a4c1f2d",
  "buildId": "20251104-1812-a4c1f2d",
  "compiledAt": "2025-11-04T18:45:21Z",
  "dataVersion": 2,
  "engineVersion": "godot-4.3.stable",
  "buildMachine": "DESKTOP-01",
}
```

---

## Uso

Ejecutar desde PowerShell:

```powershell
.\make-buildinfo.ps1
```

Por defecto crea `buildinfo.json` en la carpeta actual.

### Parámetros

| Parámetro | Descripción | Valor por defecto |
|------------|--------------|------------------|
| `-Channel` | Canal del build (`dev`, `beta`, `release`) | `dev` |
| `-Platform` | Plataforma destino (`Windows`, `Linux`, `mac`, etc.) | `Windows` |
| `-DataVersion` | Versión de datos o reglas. Si no se pasa, se lee de `version.txt`. | `0` |
| `-Engine` | Motor o framework. Si no se pasa, se lee de `engine.txt`. | `unknown` |
| `-OutDir` | Carpeta donde guardar el JSON. | `.` |
| `-OutFile` | Nombre del archivo JSON. | `buildinfo.json` |
| `-Help`, `-h` | Muestra la ayuda y termina. | — |

---

## Archivos auxiliares

### version.txt
Archivo opcional en formato clave=valor:

```
version=0.2.0
dataVersion=2
```

Si no existe, se usa `version=0.0.0` y `dataVersion=0`.

### engine.txt
Archivo opcional en formato clave=valor:

```
engine=godot-4.3.stable
```

Si no existe, se usa `engine=unknown`.

---

## Ejemplos

Build normal:
```powershell
.\make-buildinfo.ps1
```

Build para Linux:
```powershell
.\make-buildinfo.ps1 -Channel beta -Platform Linux
```

Especificar salida personalizada:
```powershell
.\make-buildinfo.ps1 -OutDir out/meta -OutFile build-meta.json
```

Mostrar ayuda:
```powershell
.\make-buildinfo.ps1 -h
```

---

## Requisitos

- PowerShell 5.1 o superior
- Git instalado (opcional, solo si se desea registrar el commit actual)
- Permisos de escritura en la carpeta de salida

---

## Licencia

Publicado bajo licencia **MIT**.  
Consulta el archivo [LICENSE](LICENSE) para más información.
