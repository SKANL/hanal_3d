# Carga de archivos .glb (solución)

Descripción breve

Este documento explica por qué los archivos .glb no se cargaban originalmente en la escena AR y qué se implementó para solucionarlo.

Problema

- El plugin `ar_flutter_plugin` (y su fork `ar_flutter_plugin_updated`) no siempre puede leer archivos `.glb` directamente desde el bundle de Flutter cuando se pasa una ruta `assets/...` o una URI `file://...`.
- Pasar `file://...` provocaba URIs malformadas porque el plugin a veces prefiere construir internamente su propio esquema, resultando en cadenas como `renderablefile:///...`.

Solución aplicada

- Copiar el asset `.glb` desde el bundle de Flutter al directorio de Documents de la app usando `rootBundle.load()` + `path_provider`.
- Usar `NodeType.fileSystemAppFolderGLB` y pasar solo el nombre del archivo (por ejemplo `mi_modelo.glb`). El plugin buscará automáticamente en la carpeta de documentos de la app.

Resumen técnico

- Función central: `_copyAssetToDocuments(String assetPath)` en `lib/main.dart`.
  - Lee bytes del asset con `rootBundle.load(assetPath)`.
  - Escribe los bytes en `getApplicationDocumentsDirectory()` con el mismo nombre de archivo.
  - Retorna solamente el `filename` (ej. `altar_de_dia_de_muertos.glb`).
- Al crear el `ARNode`, se usa:
  - `type: NodeType.fileSystemAppFolderGLB`
  - `uri: <filename>`

Cómo probar localmente (Android / iOS)

1. Asegúrate de que los archivos `.glb` estén listados en `pubspec.yaml` bajo `flutter: assets:`.
2. Hot-restart o rebuild de la app después de los cambios de assets.
3. Ejecuta la app en un dispositivo compatible AR (Android con ARCore o iOS con ARKit):

```powershell
# abre terminal en la carpeta del proyecto
flutter clean
flutter pub get
flutter run -d <device-id>
```

4. En la pantalla AR, selecciona un modelo y toca una superficie para colocarlo.
   - El código imprime en consola la ruta copiada y si el archivo existe, p.ej. `File copied to: C:\...\Documents\altar_de_dia_de_muertos.glb`.

Mensajes comunes y qué significan

- "Unable to load renderable...": indicaba URIs malformadas o que el plugin no encontraba el archivo en la ubicación esperada. La solución es copiar al Documents y usar `fileSystemAppFolderGLB`.
- Si ves `File exists: false` en los logs: verifica que `assetPath` es correcto y que el asset esté declarado en `pubspec.yaml`.

Siguientes mejoras recomendadas

- Eliminar archivos copiados cuando se elimina el nodo o en segundo plano para evitar acumulación de archivos.
- Implementar descubrimiento automático de assets (leer `pubspec.yaml` o generar una lista en build) para evitar editar manualmente la lista `models` en `main.dart` cada vez que agregues un .glb.
- Añadir controles UI para valores numéricos precisos (sliders para escala/rotación) por nodo.

Registro de cambios

- `lib/main.dart`: implementada `_copyAssetToDocuments`, cambio a `NodeType.fileSystemAppFolderGLB`, manejo de selección por nodo y controles UI para habilitar/deshabilitar gestures.

Contacto

Si quieres, puedo:
- Añadir la limpieza automática de archivos copiados al eliminar nodos.
- Detectar y añadir automáticamente nuevos `.glb` del `assets/` al selector.
- Añadir sliders para transformar con precisión cada objeto.


