import 'package:flutter/material.dart';
import 'package:ar_flutter_plugin_updated/ar_flutter_plugin.dart';
import 'package:ar_flutter_plugin_updated/datatypes/config_planedetection.dart';
import 'package:ar_flutter_plugin_updated/datatypes/node_types.dart';
import 'package:ar_flutter_plugin_updated/managers/ar_anchor_manager.dart';
import 'package:ar_flutter_plugin_updated/managers/ar_location_manager.dart';
import 'package:ar_flutter_plugin_updated/managers/ar_object_manager.dart';
import 'package:ar_flutter_plugin_updated/managers/ar_session_manager.dart';
import 'package:ar_flutter_plugin_updated/models/ar_anchor.dart';
import 'package:ar_flutter_plugin_updated/models/ar_hittest_result.dart';
import 'package:ar_flutter_plugin_updated/models/ar_node.dart';
import 'package:ar_flutter_plugin_updated/widgets/ar_view.dart';
import 'package:vector_math/vector_math_64.dart' as vector;
import 'dart:io';
import 'package:flutter/services.dart' show rootBundle;
import 'package:path_provider/path_provider.dart';

void main() {
  runApp(const MainApp());
}

class MainApp extends StatelessWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Hanal 3D - AR Día de Muertos',
      theme: ThemeData(
        primarySwatch: Colors.deepOrange,
        brightness: Brightness.dark,
      ),
      home: const HomeScreen(),
    );
  }
}

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Hanal 3D'),
        centerTitle: true,
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Card(
            elevation: 8,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            child: Padding(
              padding: const EdgeInsets.all(32.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.auto_awesome,
                    size: 100,
                    color: Colors.deepOrange,
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    'Decora tu Altar',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'Día de Muertos',
                    style: TextStyle(
                      fontSize: 18,
                      color: Colors.grey,
                    ),
                  ),
                  const SizedBox(height: 32),
                  ElevatedButton.icon(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const ARScreen(),
                        ),
                      );
                    },
                    icon: const Icon(Icons.camera_alt, size: 28),
                    label: const Text(
                      'Abrir Cámara AR',
                      style: TextStyle(fontSize: 18),
                    ),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 32,
                        vertical: 16,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class ARScreen extends StatefulWidget {
  const ARScreen({super.key});

  @override
  State<ARScreen> createState() => _ARScreenState();
}

class _ARScreenState extends State<ARScreen> {
  ARSessionManager? arSessionManager;
  ARObjectManager? arObjectManager;
  ARAnchorManager? arAnchorManager;

  List<ARNode> nodes = [];
  int currentModelIndex = 0;

  // Lista de modelos 3D disponibles
  final List<Map<String, String>> models = [
    {
      'name': 'Altar',
      'path': 'assets/altar_de_dia_de_muertos.glb',
    },
    {
      'name': 'Día de Muertos',
      'path': 'assets/dia_de_los_muertos.glb',
    },
    {
      'name': 'Katrina',
      'path': 'assets/dia_de_los_muertos_katrina_mexico.glb',
    },
    {
      'name': 'Papel Picado',
      'path': 'assets/papel_picado.glb',
    },
    {
      'name': 'Calavera',
      'path': 'assets/skull_dia_de_muertos.glb',
    },
  ];

  @override
  void dispose() {
    arSessionManager?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Decoración AR'),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_outline),
            onPressed: _removeAllObjects,
            tooltip: 'Eliminar todos los objetos',
          ),
        ],
      ),
      body: Stack(
        children: [
          ARView(
            onARViewCreated: onARViewCreated,
            planeDetectionConfig: PlaneDetectionConfig.horizontalAndVertical,
          ),
          Positioned(
            bottom: 20,
            left: 20,
            right: 20,
            child: Column(
              children: [
                // Selector de modelo
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(12.0),
                    child: Column(
                      children: [
                        Text(
                          models[currentModelIndex]['name']!,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.arrow_back_ios),
                              onPressed: () {
                                setState(() {
                                  currentModelIndex = (currentModelIndex - 1) % models.length;
                                });
                              },
                            ),
                            const SizedBox(width: 20),
                            Text('${currentModelIndex + 1} / ${models.length}'),
                            const SizedBox(width: 20),
                            IconButton(
                              icon: const Icon(Icons.arrow_forward_ios),
                              onPressed: () {
                                setState(() {
                                  currentModelIndex = (currentModelIndex + 1) % models.length;
                                });
                              },
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                // Instrucciones
                const Card(
                  child: Padding(
                    padding: EdgeInsets.all(12.0),
                    child: Text(
                      'Toca sobre una superficie para colocar el objeto',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 14),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void onARViewCreated(
    ARSessionManager arSessionManager,
    ARObjectManager arObjectManager,
    ARAnchorManager arAnchorManager,
    ARLocationManager arLocationManager,
  ) {
    this.arSessionManager = arSessionManager;
    this.arObjectManager = arObjectManager;
    this.arAnchorManager = arAnchorManager;

    this.arSessionManager!.onInitialize(
          showFeaturePoints: false,
          showPlanes: true,
          showWorldOrigin: false,
          handlePans: true,
          handleRotation: true,
        );
    this.arObjectManager!.onInitialize();

    this.arSessionManager!.onPlaneOrPointTap = onPlaneOrPointTapped;
    this.arObjectManager!.onPanStart = onPanStarted;
    this.arObjectManager!.onPanChange = onPanChanged;
    this.arObjectManager!.onPanEnd = onPanEnded;
    this.arObjectManager!.onRotationStart = onRotationStarted;
    this.arObjectManager!.onRotationChange = onRotationChanged;
    this.arObjectManager!.onRotationEnd = onRotationEnded;
  }

  Future<void> onPlaneOrPointTapped(List<ARHitTestResult> hitTestResults) async {
    var singleHitTestResult = hitTestResults.firstOrNull;
    if (singleHitTestResult != null) {
      var newAnchor = ARPlaneAnchor(transformation: singleHitTestResult.worldTransform);
      bool? didAddAnchor = await arAnchorManager?.addAnchor(newAnchor);
      
      if (didAddAnchor!) {
        // Copy asset to app's Documents folder and use fileSystemAppFolderGLB type
        // This is the correct way to load local GLB models for ar_flutter_plugin
        String assetPath = models[currentModelIndex]['path']!;
        String modelUri;
        
        try {
          modelUri = await _copyAssetToDocuments(assetPath);
          print('Copied model to documents: $modelUri');
        } catch (e) {
          print('Error copying asset: $e');
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Error al cargar modelo: $e')),
            );
          }
          return;
        }

        // Create AR node using fileSystemAppFolderGLB type
        var newNode = ARNode(
          type: NodeType.fileSystemAppFolderGLB,
          uri: modelUri,  // Just the filename, not the full path
          scale: vector.Vector3(0.2, 0.2, 0.2),
          position: vector.Vector3(0.0, 0.0, 0.0),
          rotation: vector.Vector4(1.0, 0.0, 0.0, 0.0),
        );

        bool? didAddNodeToAnchor = await arObjectManager?.addNode(newNode, planeAnchor: newAnchor);

        if (didAddNodeToAnchor!) {
          nodes.add(newNode);
          print("Modelo agregado exitosamente: ${models[currentModelIndex]['name']}");
        } else {
          print("No se pudo agregar el modelo");
        }
      } else {
        print("No se pudo agregar el anchor");
      }
    }
  }

  onPanStarted(String nodeName) {
    print("Started panning node $nodeName");
  }

  onPanChanged(String nodeName) {
    print("Continued panning node $nodeName");
  }

  onPanEnded(String nodeName, Matrix4 newTransform) {
    print("Ended panning node $nodeName");
    final pannedNode = nodes.firstWhere((element) => element.name == nodeName);
    pannedNode.transform = newTransform;
  }

  onRotationStarted(String nodeName) {
    print("Started rotating node $nodeName");
  }

  onRotationChanged(String nodeName) {
    print("Continued rotating node $nodeName");
  }

  onRotationEnded(String nodeName, Matrix4 newTransform) {
    print("Ended rotating node $nodeName");
    final rotatedNode = nodes.firstWhere((element) => element.name == nodeName);
    rotatedNode.transform = newTransform;
  }

  /// Copies a Flutter asset to the app's Documents directory
  /// Returns just the filename (not the full path) for use with NodeType.fileSystemAppFolderGLB
  Future<String> _copyAssetToDocuments(String assetPath) async {
    final byteData = await rootBundle.load(assetPath);
    final buffer = byteData.buffer;
    
    // Get the app's documents directory
    final Directory appDocDir = await getApplicationDocumentsDirectory();
    
    // Extract just the filename from the asset path
    final String filename = assetPath.split('/').last;
    
    // Create the file in the documents directory
    final File file = File('${appDocDir.path}/$filename');
    
    // Write the asset bytes to the file
    await file.writeAsBytes(
      buffer.asUint8List(byteData.offsetInBytes, byteData.lengthInBytes),
    );
    
    print('File copied to: ${file.path}');
    print('File exists: ${await file.exists()}');
    
    // Return just the filename (the plugin will look in the documents folder)
    return filename;
  }

  Future<void> _removeAllObjects() async {
    for (var node in nodes) {
      await arObjectManager?.removeNode(node);
    }
    nodes.clear();
    
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Todos los objetos han sido eliminados'),
          duration: Duration(seconds: 2),
        ),
      );
    }
  }
}
